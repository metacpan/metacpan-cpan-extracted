# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Worker::Commands;
use strict;
use warnings;
use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;

use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my %extcommand;
    $self->{extcommand} = \%extcommand;

    return $self;
}

sub reload {
    my ($self) = shift;
    
    return;
}

sub register {
    my $self = shift;
    $self->register_worker("work");
    return;
}

sub register_extcommand {
    my ($self, $command, $modul) = @_;
    
    $self->{extcommand}->{$command} = $modul;
    
    my @cmdlist;
    foreach my $cmd (sort keys %{$self->{extcommand}}) {
        push @cmdlist, "'" . $cmd . "'";
    }
    push @cmdlist, "'NOP_OK'";
    push @cmdlist, "'NOP_FAIL'";
    
    $self->{commandlist} = join(",", @cmdlist);
    return;
}

sub work {
    my ($self) = @_;
    
    my $workCount = 0;
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $sth = $dbh->prepare_cached("SELECT id, command, arguments " .
                                "FROM commandqueue " .
                                "WHERE starttime <= now() " .
                                "AND command IN (" . $self->{commandlist} . ") " .
                                "ORDER BY starttime")
                    or croak($dbh->errstr);
    
    my $delsth = $dbh->prepare_cached("DELETE FROM commandqueue " .
                               "WHERE id = ?")
                    or croak($dbh->errstr);

    my $getsth = $dbh->prepare_cached("SELECT * " .
                               "FROM orders " .
                               "WHERE order_id = ?")
                    or croak($dbh->errstr);
    
    my $activecommand = 0;
    $memh->set_activecommand("activecommand", $activecommand);
    
    my @commands;
    $sth->execute or croak($dbh->errstr);
    while((my $command = $sth->fetchrow_hashref)) {
        push @commands, $command;
    }
    $sth->finish;
    $dbh->rollback; # some commands require that there is no active transaction on this database handle
    
    foreach my $command (@commands) {
        # For every command, refresh lifetick
        $memh->refresh_lifetick;
        
        my $logtype = "COMMAND"; # default: visible to non-admin user
        
        # Set active command id in webgui
        $activecommand = $command->{id};
        $memh->set_activecommand($activecommand);
        
        my $printarglist = "(no args)";
        if(!defined($command->{arguments})) {
            my @temp;
            $command->{arguments} = \@temp;
        }
        if(@{$command->{arguments}}) {
            $printarglist = "(" . join(",", @{$command->{arguments}}) . ")";
        }
        
        $reph->debuglog("RBSCommands " . $command->{command} . " $printarglist");

        if($self->{log_all}) {
            $reph->dblog("OTHER", "DEBUG Command " . $command->{command} . " $printarglist started");
        }
        $dbh->commit;
        
        my $done = 0;
        
        
        if(defined($self->{extcommand}->{$command->{command}})) {
            my $tmplogtype;
            ($done, $tmplogtype) = $self->{extcommand}->{$command->{command}}->execute($command->{command}, $command->{arguments});
            if(defined($tmplogtype) && $tmplogtype ne '') {
                $logtype = $tmplogtype; # Optional second argument "logtype"
            }        
        } else {
            # Just to make sure everyone understands: This part of the IF clause should
            # never be called because we already prefilter the command queue so we
            # only work on registered commands (so multiple workers can work on
            # _different_ parts of the command system).
            
            # Ok, so.... "Someone has set up us the bomb!"
            $logtype = "OTHER"; # "We get signal!"
            $reph->dblog($logtype, "Command " . $command->{command} . " not implemented"); # "Main screen turn on!"
        }
            
        
        $delsth->execute($command->{id});
        
        if(!$done) {
            $reph->dblog($logtype, "Command " . $command->{command} . " $printarglist failed");
        } elsif($self->{log_all}) {
            $reph->dblog("OTHER", "DEBUG Command " . $command->{command} . " $printarglist done");
        }
        $dbh->commit;
        $workCount++;
    }

    $activecommand = 0;
    $memh->set_activecommand($activecommand);
    
    return $workCount;
}
1;
__END__

=head1 NAME

Maplat::Worker::Commands - database admin command module

=head1 SYNOPSIS

This module executes commands scheduled from the WebGUI (table commandqueue)

=head1 DESCRIPTION

This module is the main command handling module and handles all the
bureaucracy of handling commands. It doesn't actually executes commands,
for this it relies on plugin modules like AdminCommands.

=head1 Configuration

        <module>
                <modname>commands</modname>
                <pm>Commands</pm>
                <options>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <reporting>reporting</reporting>
                        <log_all>1</log_all>
                </options>
        </module>

log_all is a boolean, setting if only failed commands or all executed commands are logged.

=head2 register_extcommand

Register an external command (command callback dispatch).

=head2 work

Internal function.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Worker::PostgresDB as "db"
Maplat::Worker::Memcache as "memcache"
Maplat::Worker::Reporting as "reporting"

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
