# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::ReportCommands;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Padding qw(doFPad doSpacePad trim);
use Maplat::Helpers::Strings qw(normalizeString);

use Carp;
use Readonly;

Readonly my $MEMKEY => "AdminReport::lastRun";

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my %commands;

    foreach my $cmd (qw[ADMIN_REPORT VNC_REPORT]) {
        my $cmdfunc = "do_" . lc($cmd);
        $commands{$cmd} = $cmdfunc;
    }
    $self->{extcommands} = \%commands;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we are pretty much self contained
    return;
}

sub register {
    my $self = shift;

    # Register ourselfs in the RBSCommands module with additional commands
    my $comh = $self->{server}->{modules}->{$self->{commands}};
    
    foreach my $cmd (sort keys %{$self->{extcommands}}) {
        $comh->register_extcommand($cmd, $self);
    }
    return;
}

sub execute {
    my ($self, $command, $arguments) = @_;
    
    if(defined($self->{extcommands}->{$command})) {
        my $cmdfunc = $self->{extcommands}->{$command};
        return $self->$cmdfunc($arguments);
    }
    return;
}


sub do_admin_report {
    my ($self, $arguments) = @_;
    
    my $logtype = "OTHER"; # make logging visible only to admin user

    # If no email adresses given in arguments, use the default reciever list
    if(!defined($arguments) || scalar(@$arguments) == 0) {
        $arguments = $self->{reciever};
    }

    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $mailh = $self->{server}->{modules}->{$self->{mail}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    $reph->debuglog("Starting admin report generation");
    
    my $todo = "";
    
    my $text = "Today's admin report, generation started at " . getISODate() . "\n\n";
    
    {
        $reph->debuglog("...Retrograde booking system...");
        $text .= "Retrograde booking system\n";
        $text .= "=========================\n";
        my $osth = $dbh->prepare_cached("SELECT state_id, count(*) FROM orders
                                        GROUP BY state_id
                                        ORDER BY decode_stateid(state_id)")
                or croak($dbh->errstr);
        
        my $otext = "";
        if(!$osth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $osth->fetchrow_hashref)) {
                $cnt += $line->{count};
                $otext .= doSpacePad($line->{state_id}, 12) . $line->{count} . "\n";
            }
            
            $text .="There are $cnt SAP orders with the following states:\n$otext\n";
        }
        
        my $ssth = $dbh->prepare_cached("SELECT line_id, count(*) FROM signals
                                            GROUP BY line_id
                                            ORDER BY line_id")
                or croak($dbh->errstr);
        
        my $stext = "";
        if(!$ssth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $ssth->fetchrow_hashref)) {
                $cnt += $line->{count};
                $stext .= doSpacePad($line->{line_id}, 20) . $line->{count} . "\n";
            }
            
            $text .="There are $cnt raw signals for the following production lines:\n$stext\n";
        }
    }

    {
        $reph->debuglog("...Chipcard system...");
        $text .= "Chipcard system\n";
        $text .= "===============\n";
        my $csth = $dbh->prepare_cached("SELECT company_name, count(*) FROM cc_card
                                            GROUP BY company_name
                                            ORDER BY company_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt += $line->{count};
                $ctext .= doSpacePad($line->{company_name}, 12) . $line->{count} . "\n";
            }
            
            $text .="There are $cnt chipcards for the following companies/groups:\n$ctext\n";
        }
    }

    {
        $reph->debuglog("...User managment...");
        $text .= "Usermanagment\n";
        $text .= "=============\n";
        my $csth = $dbh->prepare_cached("SELECT * FROM users
                                        ORDER BY username")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{username} . "\n";
            }
            
            $text .="There are $cnt users registered:\n$ctext\n";
        }
    }

    {
        $reph->debuglog("...Web stats...");
        $text .= "Web stats\n";
        $text .= "=========\n";
        my $csth = $dbh->prepare_cached("SELECT url, count(*) FROM accesslog
                                            GROUP BY url
                                            ORDER BY count(*) DESC
                                            LIMIT 50")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt += $line->{count};
                $ctext .= doSpacePad($line->{count}, 11) . $line->{url} . "\n";
            }
            
            $text .="These are current the top 50 URL's with a combined $cnt hits:\n$ctext\n";
        }
    }

    {
        $reph->debuglog("...Operating systems...");
        $text .= "Operating systems\n";
        $text .= "=================\n";
        my $csth = $dbh->prepare_cached("SELECT operating_system, count(*) FROM computers
                                            GROUP BY operating_system
                                            ORDER BY operating_system")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt += $line->{count};
                $ctext .= doSpacePad($line->{operating_system}, 23) . $line->{count} . "\n";
            }
            
            $text .="The known $cnt computers have the following operating systems:\n$ctext\n";
        }
    }

    {
        $reph->debuglog("...Servicepacks...");
        $text .= "Servicepacks\n";
        $text .= "============\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name, operating_system, servicepack
                                            FROM computers
                                            NATURAL JOIN computers_os
                                            WHERE servicepack < default_servicepack
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} . ": " .
                            $line->{operating_system} . " SP" . $line->{servicepack} . "\n";
            }
            
            $text .="The following $cnt computers do not have the most recent servicepack:\n$ctext\n";
            
            if($cnt > 0) {
                $todo .= "You need to install servicepacks on $cnt computers!\n";
            }
        }
    }

    {
        $reph->debuglog("...VNC...");
        $text .= "VNC Remote Control\n";
        $text .= "==================\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name
                                            FROM computers
                                            WHERE has_vnc = 'f'
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} . "\n";
            }
            
            $text .="The following $cnt computers do not have the VNC installed:\n$ctext\n";
            if($cnt > 0) {
                $todo .= "You need to install VNC on $cnt computers!\n";
            }
        }
    }

    {
        $reph->debuglog("...VNC usage...");
        $text .= "VNC Remote Control usage\n";
        $text .= "========================\n";
        my $csth = $dbh->prepare_cached("SELECT date_trunc('minute', logtime) AS rtime,
                                        line_id, computer_name,
                                        username, freelogtext
                                        FROM computers_vnclog NATURAL JOIN computers
                                        WHERE logtype = 'REQUEST_SESSION'
                                        AND logtime >= NOW() - '3 days'::INTERVAL
                                        ORDER BY logtime")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{rtime} . " " . $line->{line_id} . " - " . $line->{computer_name} .
                            ": " . $line->{freelogtext} . " (" . $line->{username} . ")\n";
            }
            
            $text .="The following $cnt VNC connections where requested in the last 72 hours:\n$ctext\n";
        }
    }

    {
        $reph->debuglog("...Acronis Agent...");
        $text .= "Acronis Agent\n";
        $text .= "=============\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name
                                            FROM computers
                                            WHERE has_acronisagent = 'f'
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} . "\n";
            }
            
            $text .="The following $cnt computers do not have the Acronis Agent installed:\n$ctext\n";
            if($cnt > 0) {
                $todo .= "You need to install the Acronis agent on $cnt computers!\n";
            }
        }
    }

    {
        $reph->debuglog("...AntiVirus...");
        $text .= "AntiVirus\n";
        $text .= "=========\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name
                                            FROM computers
                                            WHERE has_antivirus = 'f'
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} . "\n";
            }
            
            $text .="The following $cnt computers do not have a current AntiVirus installed:\n$ctext\n";
            if($cnt > 0) {
                $todo .= "You need to update the AntiVirus on $cnt computers!\n";
            }
        }
    }

    {
        $reph->debuglog("...Computer domain...");
        $text .= "SGI2 Computer account\n";
        $text .= "=====================\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name, computer_domain
                                            FROM computers
                                            WHERE computer_domain != 'SGI2'
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} .
                        ": " . $line->{computer_domain} . "\n";
            }
            
            $text .="The following $cnt computers are not in SGI2:\n$ctext\n";
            if($cnt > 0) {
                $todo .= "You need to switch $cnt computers to the SGI2 domain!\n";
            }
        }
    }

    {
        $reph->debuglog("...User account...");
        $text .= "SGI2 User account\n";
        $text .= "=================\n";
        my $csth = $dbh->prepare_cached("SELECT line_id, computer_name, account_domain
                                            FROM computers
                                            WHERE computer_domain = 'SGI2'
                                            AND account_domain != 'SGI2'
                                            ORDER BY line_id, computer_name")
                or croak($dbh->errstr);
        
        my $ctext = "";
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{line_id} . " - " . $line->{computer_name} .
                        ": " . $line->{account_domain} . "\n";
            }
            
            $text .="The following $cnt computers in SGI2 do not use the domain for login:\n$ctext\n";
        }
    }

    $text .= "Report generation finished at " . getISODate() . "\n\n";
    
    $reph->debuglog("Sending emails...");
    my $mailtext = "";
    if($todo ne "") {
        $mailtext .= "#######################################################\n";
        $mailtext .= $todo;
        $mailtext .= "#######################################################\n\n";
    }
    $mailtext .= $text;
    foreach my $reciever (@{$arguments}) {
        $mailh->sendMail($reciever, "Daily Admin report", $mailtext, "text/plain");
    }
    
    $reph->debuglog("Finished admin report generation");
    
    $dbh->rollback;
    return (1, $logtype);
}

sub do_vnc_report {
    my ($self, $arguments) = @_;
    
    my $logtype = "OTHER"; # make logging visible only to admin user

    # If no email adresses given in arguments, use the default reciever list
    if(!defined($arguments) || scalar(@$arguments) == 0) {
        $arguments = $self->{reciever};
    }

    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $mailh = $self->{server}->{modules}->{$self->{mail}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $todo = "";
    
    $reph->debuglog("Starting admin report generation");
    my $text = "Today's admin report, generation started at " . getISODate() . "\n\n";
    
    {
        $reph->debuglog("...VNC usage...");
        $text .= "VNC Remote Control usage\n";
        $text .= "========================\n";
        my $csth = $dbh->prepare_cached("SELECT date_trunc('minute', logtime) AS rtime,
                                        line_id, computer_name,
                                        username, freelogtext
                                        FROM computers_vnclog NATURAL JOIN computers
                                        WHERE logtype = 'REQUEST_SESSION'
                                        AND logtime >= NOW() - '7 days'::INTERVAL
                                        ORDER BY logtime")
                or croak($dbh->errstr);
        
        my $ctext = "";
        my $badlines;
        my %badusers;
        if(!$csth->execute) {
            $dbh->rollback;
        } else {
            my $cnt = 0;
            while((my $line = $csth->fetchrow_hashref)) {
                $cnt++;
                $ctext .= $line->{rtime} . " " . $line->{line_id} . " - " . $line->{computer_name} .
                            ": " . $line->{freelogtext} . " (" . $line->{username} . ")\n";
                if($line->{computer_name} eq "wxppx112") {
                    print "bla\n";
                }
                my $badline = $line->{freelogtext};
                $badline = normalizeString($badline);
                my @words = split /\ /, $badline;
                my $isBad = 0;
                if(length($badline) < 5) {
                    $isBad = 1;
                }
                if((scalar @words) < 2) {
                    $isBad = 1;
                }
                foreach my $word (@words) {
                    if($word =~ /^(am|fr)$/i) {
                        # ok word
                        # fr = fuer with removed Umlaut...
                    } elsif(length($word) < 3 || length($word) > 14) {
                        $isBad = 1;
                    }
                }

                if($isBad) {
                    $badusers{$line->{username}} = 1;
                    $badlines .= $line->{rtime} . " " . $line->{line_id} . " - " . $line->{computer_name} .
                            ": '" . $line->{freelogtext} . "' (" . $line->{username} . ")\n";
                }
            }
            if($badlines ne "") {
                $badlines = "\n\n" .
                            "*******************************************\n" .
                            "The following lines may have bad log texts:\n" .
                            "*******************************************\n" .
                            "$badlines";

                $todo .= "The following users may have used bad log texts:\n";
                foreach my $badname (sort keys %badusers) {
                    $todo .= "$badname\n";
                }
            }
                
            
            $text .="The following $cnt VNC connections where requested in the last 7 days:\n$ctext\n$badlines\n";
        }
    }

    $text .= "Report generation finished at " . getISODate() . "\n\n";
    
    $reph->debuglog("Sending emails...");
    my $mailtext = "";
    if($todo ne "") {
        $mailtext .= "#######################################################\n";
        $mailtext .= $todo;
        $mailtext .= "#######################################################\n\n";
    }
    $mailtext .= $text;
    foreach my $reciever (@{$arguments}) {
        $mailh->sendMail($reciever, "VNC usage report", $mailtext, "text/plain");
    }

    $reph->debuglog("Finished VNC report generation");

    $dbh->rollback;
    return (1, $logtype);
}

1;
__END__

=head1 NAME

Maplat::Worker::ReportCommands - do some admin reports

=head1 SYNOPSIS

This module generates some reports for admin users

=head1 DESCRIPTION

Admins need to keep an overview of their system. This reports do just that.

A note of caution: This reports are tailored to my (the developers) needs. You might have to adapt them to your
specific requirements.

=head1 Configuration

    <module>
        <modname>reportcommands</modname>
        <pm>ReportCommands</pm>
        <options>
            <db>maindb</db>
            <reporting>reporting</reporting>
            <memcache>memcache</memcache>
            <mail>sendmail</mail>
            <commands>commands</commands>
            <reciever>software.developer@example.com</reciever>
            <reciever>system.administrator@example.com</reciever>
            <reciever>boss@example.com</reciever>
        </options>
    </module>

=head2 execute

Internal function, executes specific report function based on the report name

=head2 do_admin_report

Extensive report for a (mostly) complete system overview.

=head2 do_vnc_report

Simple report about the VNC connections made during the last few days.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Worker::PostgresDB as "db"
Maplat::Worker::Memcache as "memcache"
Maplat::Worker::SensMail as "mail"

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
