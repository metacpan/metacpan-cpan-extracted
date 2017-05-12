# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::VNCTunnel;
use strict;
use warnings;
use 5.012;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use POSIX ":sys_wait_h";

use Carp;

our $VERSION = 0.995;

my @reaped;

$SIG{CHLD} = \&REAPER; ## no critic (Variables::RequireLocalizedPunctuationVars)
sub REAPER {
    my $stiff;
    print "Don't fear the reaper!\n";
    while (($stiff = waitpid(-1, &WNOHANG)) > 0) {
        # do something with $stiff if you want
        push @reaped, $stiff;
        print "Reaped app $stiff detected...\n";
    }
    # install *after* calling waitpid
    $SIG{CHLD} = \&REAPER; ## no critic (Variables::RequireLocalizedPunctuationVars)

    return;
}

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my %pids;
    $self->{pids} = \%pids;

    $self->{lastRun} = "";
    $self->{firstRun} = 1;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we are pretty much self contained
    return;
}

sub register {
    my $self = shift;
    $self->register_worker("work");
    return;
}


sub work {
    my ($self) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    
    my $workCount = 0;
    
    if($self->{firstRun}) {
        # Mark ALL Tunnels as stale
        my $xsth = $dbh->prepare("UPDATE computers_vnc SET last_update = '1970-01-01 05:00:00'")
                or croak($dbh->errstr);
        my $logsth = $dbh->prepare("INSERT INTO computers_vnclog
                    (logtype, computer_name, client_ip, proxy_port, freelogtext, username)
                    VALUES ('MARK_ALL_STALE', '" . $self->{loghost} . "', '127.0.0.1', 0, 'Worker restart', 'worker')")
                or croak($dbh->errstr);
        if($xsth->execute && $logsth->execute) {
            $dbh->commit;
            $workCount++;
            $self->{firstRun} = 0;
        } else {
            $dbh->rollback;
            return 0;
        }
    }

    {
         # Re-instate reaped sessions (if they still exist in the database, otherwise ignore them)
         my $selsth = $dbh->prepare_cached("SELECT * FROM computers_vnc
                                             WHERE process_id = ?")
                 or croak($dbh->errstr);
         my $upsth = $dbh->prepare_cached("UPDATE computers_vnc SET process_id = ?
                                             WHERE proxy_port = ?")
                 or croak($dbh->errstr);
        my $logsth = $dbh->prepare_cached("INSERT INTO computers_vnclog
                    (logtype, computer_name, client_ip, proxy_port, freelogtext, username)
                    VALUES ('RESTART_REAPED', ?, ?, ?, 'Restart reaped tunnel', 'worker')")
                or croak($dbh->errstr);

        my @lines;
        while((my $procpid = shift @reaped)) {
            delete $self->{pids}->{$procpid};
            if(!$selsth->execute($procpid)) {
                $dbh->rollback;
            } else {
                while((my $line = $selsth->fetchrow_hashref)) {
                    push @lines, $line;
                }
                $selsth->finish;
            }
        }
        foreach my $line (@lines) {
            print "Restarting tunnel for reaped " . $line->{proxy_port} . "...\n";
            my $procpid = $self->start_app($line);
            if($procpid) {
                if($upsth->execute($procpid, $line->{proxy_port}) &&
                        $logsth->execute($line->{computer_name}, $line->{client_ip}, $line->{proxy_port})) {
                    $dbh->commit;
                    $workCount++;
                } else {
                    $dbh->rollback;
                    $self->stop_app($procpid);
                }
            }
        }
    }




    
    {
        # Kill stale sessions
        my $selsth = $dbh->prepare_cached("SELECT * FROM computers_vnc
                                          WHERE (now()-last_update) > interval '5 minutes'")
                or croak($dbh->errstr);
        my $delsth = $dbh->prepare_cached("DELETE FROM computers_vnc
                                          WHERE process_id = ?");
        my $logsth = $dbh->prepare_cached("INSERT INTO computers_vnclog
                    (logtype, computer_name, client_ip, proxy_port, freelogtext, username)
                    VALUES (?, ?, ?, ?, ?, 'worker')")
                or croak($dbh->errstr);
        if(!$selsth->execute) {
            croak($dbh->errstr);
        }
        my @lines;
        while((my $line = $selsth->fetchrow_hashref)) {
            push @lines, $line;
        }
        $selsth->finish;
        
        foreach my $line (@lines) {
            if($line->{process_id}) {
                $self->stop_app($line->{process_id});
            }
            my $logmode = "SESSION_END";
            my $logtext = "Browser window closed (refresh timeout) or worker restart";
            if(!$line->{has_proxystarted}) {
                $logmode = "SESSION_TIMEOUT";
                $logtext = "Tunnel seems to have never been started";
            }
            if($delsth->execute($line->{process_id}) &&
                    $logsth->execute($logmode, $line->{computer_name},
                                    $line->{client_ip}, $line->{proxy_port}, $logtext)) {
                $dbh->commit;
            } else {
                $dbh->rollback;
            }
        }
    }    
    
    {
        # check for new tunnels to create
        my $nsth = $dbh->prepare_cached("SELECT * FROM computers_vnc
                                        WHERE has_proxystarted = 'f'::boolean")
                or croak($dbh->errstr);
        $nsth->execute() or croak($dbh->errstr);
        my @lines;
        while((my $line = $nsth->fetchrow_hashref)) {
            push @lines, $line;
        }
        $nsth->finish;
        my $ncsth = $dbh->prepare_cached("UPDATE computers_vnc
                                         SET process_id = ?,
                                         has_proxystarted = 't'::boolean
                                         WHERE proxy_port = ?")
                or croak($dbh->errstr);
        my $logsth = $dbh->prepare_cached("INSERT INTO computers_vnclog
                    (logtype, computer_name, client_ip, proxy_port, freelogtext, username)
                    VALUES ('PROXY_STARTED', ?, ?, ?, 'Starting requested tunnel', 'worker')")
                or croak($dbh->errstr);
        foreach my $line (@lines) {
            my $procpid = $self->start_app($line);
            if($procpid) {
                if($ncsth->execute($procpid, $line->{proxy_port}) &&
                        $logsth->execute($line->{computer_name},
                                    $line->{client_ip}, $line->{proxy_port})) {
                    $dbh->commit;
                    $workCount++;
                } else {
                    $dbh->rollback;
                    $self->stop_app($procpid);
                }
            }
        }
    }
    
    $dbh->rollback;
    
    return $workCount;
}

sub DESTROY {
    my ($self) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};    
    
    my $delsth = $dbh->prepare_cached("DELETE FROM computers_vnc
                                          WHERE process_id = ?");
    
    foreach my $procid (keys %{$self->{pids}}) {
        $self->stop_app($procid);
        if($delsth->execute($procid)) {
            $dbh->commit;
        } else {
            $dbh->rollback;
        }
    }

    return;
}

sub start_app {
    my ($self, $app) = @_;

    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    
    my $pid = fork();

    if($pid) {
        #parent
        $reph->debuglog("Tunnel for " . $app->{computer_name} . " on port " . $app->{proxy_port} . " has PID $pid");
        $self->{pids}->{$pid} = $app->{proxy_port};
        return $pid;
    } else {
        # Child
        my $cmd = $self->{app} . " " . $app->{computer_ip} . " " . $app->{proxy_port};
        exec($cmd) or croak("Can't exec $cmd");
        print "Child done\n";
        exit(0);
    }
}

sub stop_app {
    my ($self, $procpid) = @_;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    
    if(!defined($self->{pids}->{$procpid})) {
        $reph->debuglog("App with PID $procpid doesn't seem my own!");
        return;
    }
    
    $reph->debuglog("Killing app for port " . $self->{pids}->{$procpid} . " with PID $procpid...");
    kill 15, $procpid; # SIGTERM
    sleep(3);
    kill 9, $procpid;  #SIGKILL
    delete $self->{pids}->{$procpid};
    $reph->debuglog("...killed.");
    return;
}

1;
__END__

=head1 NAME

Maplat::Worker::VNCTunnel - Open a new VNC Tunnel (proxy tunnel)

=head1 SYNOPSIS

This module opens proxy tunnels for VNC via an external script.

=head1 DESCRIPTION

This is the worker part to update the weather information.
=head1 Configuration

    <module>
        <modname>vnctunnel</modname>
        <pm>VNCTunnel</pm>
        <options>
            <db>maindb</db>
            <reporting>reporting</reporting>
            <app>perl tunnel.pl</app>
            <loghost>illinrbs01</loghost>
        </options>
    </module>

=head2 work

Internal function, does the cyclic checking and command handling.

=head2 start_app

Internal function, starts a new external tunnel script.

=head2 stop_app

Internal function, stops an external tunnel script.

=head2 REAPER

Internal function, handles SIGCHLD and avoids zombie processes.

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
