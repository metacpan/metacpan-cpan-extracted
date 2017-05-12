# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::DirCleaner;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Padding qw(doFPad);
use XML::Simple;
use Date::Simple ('date', 'today');
use File::stat;

use Carp;
use Readonly;

our $VERSION = 0.995;

Readonly my $YEARBASEOFFSET => 1900;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my %dirstatus;
    foreach my $dir (@{$self->{directory}}) {
        my %status = (
            maxage    => $dir->{maxage},
            status    => "UNKNOWN",
        );
        $dirstatus{$dir->{path}} = \%status;
    }
    $memh->set("dircleanstatus", \%dirstatus);
    $self->{dirstatus} = \%dirstatus;
    
    $self->{lastRun} = "";

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
    
    my $workCount = 0;
    
    my $now = getCurrentHour();
    if($self->{lastRun} eq $now) {
        return $workCount;
    }
    $self->{lastRun} = $now;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    foreach my $dir (sort keys %{$self->{dirstatus}}) {
        $workCount += $self->clean($dir);
    }
    
    $memh->set("dircleanstatus", \%{$self->{dirstatus}});
    
    return $workCount;
}

sub clean {
    my ($self, $dir) = @_;
    
    my @todelete;
    my $deletes = 0;
    
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    $reph->debuglog("Scanning $dir for cleaning");
    
    my $dfh;
    if(!opendir($dfh, $dir)) {
        if($self->{dirstatus}->{$dir}->{status} !~ /^ERROR$/o) {
            $self->{dirstatus}->{$dir}->{status} = "ERROR";
            $reph->dblog("DIR_CLEANER", "Can't open '$dir'");
            $dbh->commit;
        }
        $reph->debuglog("Can't open $dir");
        return $deletes;
    }
    
    my $fcount = 0;
    while((my $fname = readdir($dfh))) {
        next if($fname eq "." || $fname eq "..");
        
        # FIXME FOR SUBDIRS! REMOVE ALL EMPTY DIRS
        # Add code to configure from which depth on
        # empty dirs can be deleted
        #if(-d "$dir/$fname") {
        #    $self->clean("$dir/$fname");
        #    next;
        #}
        next if(!-f "$dir/$fname");
        my $date_string;
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(stat("$dir/$fname")->mtime);
        $year += $YEARBASEOFFSET;
        $mon += 1; $mon = doFPad($mon, 2);
        $mday = doFPad($mday, 2);
        $date_string = "$year-$mon-$mday";
        
        my $age = today() - date($date_string);

        next if($age <= $self->{dirstatus}->{$dir}->{maxage});
        push @todelete, "$dir/$fname";
        $fcount++;
        if($fcount == $self->{limit}) {
            $reph->debuglog("Limiting cleaning of $dir to $fcount files");
            last;
        }
    }
    closedir($dfh);
    
    my $ok = 1;
    if($fcount) {
        $reph->debuglog("Cleaning $fcount file(s) in $dir");
        foreach my $fname (@todelete) {
            if(unlink $fname) {
                $deletes++;
            } else {
                $ok = 0;
                $reph->debuglog("Failed to delete $fname");
            }
        }
        $reph->debuglog("Deleted $deletes file(s).");
    }
    
    if($ok) {
        $self->{dirstatus}->{$dir}->{status} = "OK";
    } else {
        if($self->{dirstatus}->{$dir}->{status} !~ /^(?:WARNING|ERROR)$/o) {
            $self->{dirstatus}->{$dir}->{status} = "WARNING";
            $reph->dblog("DIR_CLEANER", "Failed to delete file(s) in '$dir'");
            $dbh->commit;
        }
    }
    
    return $deletes;
}

1;
__END__

=head1 NAME

Maplat::Worker::DirCleaner - Clean stale files from directories

=head1 SYNOPSIS

This module cleans out old/stale files from configured directories

=head1 DESCRIPTION

This module provides a simple directory cleaner for multiple directories. Currently,
no recursive cleaning is done (we're working on that, stay tuned). Just configure the module,
the actual cleaning is done automatically.

=head1 Configuration

        <module>
                <modname>dircleaner</modname>
                <pm>DirCleaner</pm>
                <options>
                        <reporting>reporting</reporting>
                        <memcache>memcache</memcache>
                        <db>maindb</db>
                        <limit>1000</limit>
                        <directory>
                                <path>/full/path/to/dir</path>
                                <maxage>8</maxage>
                        </directory>
                        ...
                        <directory>
                                <path>relative/path/to/dir</path>
                                <maxage>7</maxage>
                        </directory>
                </options>
        </module>

maxage is the maximum age in days the files are allowed to reside in the directory

limit denotes the limit of how many files to clean out in a single run. This option prevents
the module of monopolizing harddisk IO.

=head2 work

Internal function.

=head2 clean

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
