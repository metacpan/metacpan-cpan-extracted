# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::AutoScheduler;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

use Carp;
use Readonly;

Readonly my $SHIFTMEMKEY => "AutoScheduler::lastShift";
Readonly my $DAYMEMKEY => "AutoScheduler::lastDay";
Readonly my $HOURMEMKEY => "AutoScheduler::lastHour";

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we are pretty much self contained
    return;
}

sub register {
    my $self = shift;
    $self->register_worker("work_shift");
    $self->register_worker("work_hour");
    $self->register_worker("work_day");
    return;
}


sub work_shift {
    my ($self) = @_;
    
    my $workCount = 0;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $now = getCurrentHour();
    my $lastRun = $memh->get($SHIFTMEMKEY);
    if(!defined($lastRun)) {
        $lastRun = "";
    } else {
        $lastRun = dbderef($$lastRun);
    }
    
    if($lastRun eq $now) {
        return $workCount;
    }
    
    $memh->set($SHIFTMEMKEY, $now);
    
    if($now !~ /(08|14|22)$/) {
        return $workCount;
    }
    
    
    my $csth = $dbh->prepare_cached("INSERT INTO commandqueue
                                    (command, arguments)
                                    VALUES (?,?)")
            or croak($dbh->errstr);
    my @args = ();
    
    $reph->debuglog("Scheduling backup");
    if($csth->execute('BACKUP', \@args)) {
        $workCount++;
        $dbh->commit;
    } else {
        $dbh->rollback;
        $reph->debuglog("Scheduling backup FAILED!");
    }

    $dbh->commit;
    return $workCount;
}

sub work_hour {
    my ($self) = @_;
    
    my $workCount = 0;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $now = getCurrentHour();
    my $lastRun = $memh->get($HOURMEMKEY);
    if(!defined($lastRun)) {
        $lastRun = "";
    } else {
        $lastRun = dbderef($$lastRun);
    }
    
    
    if($lastRun eq $now) {
        return $workCount;
    }
    
    $memh->set($HOURMEMKEY, $now);
    
    { # Clean up the status log
        my %lifetimes = (
            'PRODLINE_ACCESS'   => '10 hours',
            'COMMAND'           => '5 days',
            'OTHER'             => '3 days',
            
        );
    
        foreach my $cmd (keys %lifetimes) {
            my $ltime = $lifetimes{$cmd};
            $reph->debuglog("Cleaning errors for $cmd ($ltime)");
            my $csth = $dbh->prepare("DELETE FROM errors
                                            WHERE error_type = '$cmd'
                                            AND reporttime < now() - INTERVAL '$ltime'")
                    or croak($dbh->errstr);
            if($csth->execute()) {
                $dbh->commit;
                $workCount++;
            } else {
                $dbh->rollback;
                $reph->debuglog("Cleaning FAILED!");
            }
        }
        $dbh->commit;
    }
    
    { # Clean up the access log
        my $csth = $dbh->prepare_cached("DELETE FROM accesslog
                                        WHERE accesstime < now() - INTERVAL '7 days'")
            or croak($dbh->errstr);

        $reph->debuglog("Cleaning accesslog");
        if($csth->execute()) {
            $dbh->commit;
            $workCount++;
        } else {
            $dbh->rollback;
            $reph->debuglog("Cleaning FAILED!");
        }

        $dbh->commit;
    }
    
    return $workCount;
}

sub work_day {
    my ($self) = @_;
    
    my $workCount = 0;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $now = getCurrentDay();
    my $lastRun = $memh->get($DAYMEMKEY);
    if(!defined($lastRun)) {
        $lastRun = "";
    } else {
        $lastRun = dbderef($$lastRun);
    }
    
    
    if($lastRun eq $now) {
        return $workCount;
    }
    
    $memh->set($DAYMEMKEY, $now);

    { # Clean up the cc_serverlog log
        my $csth = $dbh->prepare_cached("DELETE FROM cc_serverlog
                                        WHERE logtime < now() - INTERVAL '1 year'")
            or croak($dbh->errstr);

        $reph->debuglog("Cleaning cc_serverlog");
        if($csth->execute()) {
            $dbh->commit;
            $workCount++;
        } else {
            $dbh->rollback;
            $reph->debuglog("Cleaning FAILED!");
        }

        $dbh->commit;
    }

    my $csth = $dbh->prepare_cached("INSERT INTO commandqueue
                                    (command, arguments, starttime)
                                    VALUES (?,?,?)")
            or croak($dbh->errstr);
    
    { # Schedule the admin report
        my @args = ();
        
        my ($ndate, $ntime) = getDateAndTime();
        my $starttime = "$ndate 05:00:00";
        $reph->debuglog("Scheduling daily admin report");
        if($csth->execute('ADMIN_REPORT', \@args, $starttime)) {
            $workCount++;
            $dbh->commit;
        } else {
            $dbh->rollback;
            $reph->debuglog("Scheduling daily admin report FAILED!");
        }
    }

    { # Schedule the VNC report
        my @args = ();
        
        my ($ndate, $ntime) = getDateAndTime();
        my $starttime = "$ndate 05:30:00";
        $reph->debuglog("Scheduling daily VNC report");
        if($csth->execute('VNC_REPORT', \@args, $starttime)) {
            $workCount++;
            $dbh->commit;
        } else {
            $dbh->rollback;
            $reph->debuglog("Scheduling daily VNC report FAILED!");
        }
    }
    
    return $workCount;
}

1;
__END__

=head1 NAME

Maplat::Worker::AutoScheduler - Schedule some tasks automatically

=head1 SYNOPSIS

This module automatically schedules some tasks (mostly via the command table).

=head1 DESCRIPTION

This module provides a simple directory cleaner for multiple directories. Currently,
no recursive cleaning is done (we're working on that, stay tuned). Just configure the module,
the actual cleaning is done automatically.

=head1 Configuration

    <module>
        <modname>autoscheduler</modname>
        <pm>AutoScheduler</pm>
        <options>
            <db>maindb</db>
            <reporting>reporting</reporting>
            <memcache>memcache</memcache>
        </option>
    </module>

=head1 A NOTE OF WARNING

Danger, Will Robinson!

Except for this standard options, everything else is currently hardcoded in the modules source code. If you want to use this module,
you might want to write your own version (using this one as a template).

=head2 work_day

Schedule daily tasks.

=head2 work_hour

Schedule hourly tasks.

=head2 work_shift

My company uses a work shift model. This function schedules some tasks at the shift boundaries.

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
