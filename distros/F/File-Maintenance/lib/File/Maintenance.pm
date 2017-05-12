package File::Maintenance;
use warnings;
use strict;
use base qw(Class::Accessor);
use File::Find::Rule;
use File::Stat::OO;
use File::Copy;
use File::Path;
use File::Basename;
use DateTime;
use Carp;
use IO::Compress::Gzip qw($GzipError);
use IO::Compress::Zip qw($ZipError);
use IO::Compress::Bzip2 qw($Bzip2Error);

File::Maintenance->mk_accessors(
    qw(age test recurse directory pattern
        archive_directory)
);

use constant UNIT_MAP => {
    s => 'seconds',
    m => 'minutes',
    h => 'hours',
    d => 'days'
};

=head1 NAME

File::Maintenance - Maintain files based on their age.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module allows you to purge files from a directory based on age

    use File::Maintenance;

    my $fm = File::Maintenance->new({
            directory => '/tmp',
            pattern   => '*.sess',
            age       => '5d', #older than five days
    });

    $fm->test(1); # don't execute the purge
    $fm->purge; # prints the action to STDOUT but doesn't purge files

    $fm->test(0); # It's all for real
    $fm->purge; # Will delete old *.sess files from /tmp
    $fm->recurse(1);
    $fm->purge; # Will delete old *.sess files from /tmp and sub-directories

You can also archive files (move to another directory) based on age as well

    use File::Maintenance;

    my $fm = File::Maintenance->new({
            directory         => '/my/data/files',
            archive_directory => '/my/archive/files'
            pattern           => '*',
            recurse           => 1, # subdirectories too
            age               => '30m' # older than 30 minutes
    });

    $fm->archive;

Each value passed to the constructor has a corresponding method for
setting the value, so the archive above could have been written as:

    use File::Maintenance;

    my $fm = File::Maintenance->new();
    $fm->directory('/my/data/files');
    $fm->archive_directory('/my/archive/files);
    $fm->pattern('*');
    $fm->recurse(1);
    $fm->age('30m);
    $fm->archive;

Instead of purging, files can be compressed with either zip, gzip or bzip2 formats:

    $fm->zip;

or

    $fm->gzip;

or

    $fm->bzip2;

=head1 METHODS

=head2 directory

The root directory for purging

        $fm->directory('/tmp');

=head2 pattern

The pattern mask for files to process

        $fm->pattern('backup*.tar.gz');

By default, the pattern is a glob. To use a regular expression, it must be
quoted with the qr operator:

        $fm->pattern(qr/^(foo|bar)\d\d\.jpg$/);

=head2 archive_directory

The directory that files will be archived to. If the recurse attribute
is set, the archive directory hierarchy will match the source directory
hierarchy

=head2 age

Files older than the age will either be archived or purged, depending on
the requested action. The age can be specified by s, m, h or d -
(seconds, minutes, hours or days)

        $fm->age('1d'); # Files older than 1 day
        $fm->age('4h'); # Files older than 4 hours

=head2 recurse

Whether to traverse subdirectories

=head2 purge

Delete files older than age

=cut

sub purge {
    my $self = shift;

    foreach my $file ($self->get_files) {
        if ($self->test) {
            print "TEST: Purging $file\n";
        } else {
            unlink $file || croak("Unable to purge $file: $!");
        }
    }
}

=head2 gzip

Compresses files older than age using the gzip format

=cut

sub gzip {
    my $self = shift;

    foreach my $file ($self->get_files) {
        if ($self->test) {
            print "TEST: gzipping $file\n";
        } else {
            IO::Compress::Gzip::gzip $file => $file . '.gz'
                or croak ("Unable to gzip $file: $GzipError");
            unlink $file || croak("Unable to purge $file: $!");
        }
    }
}

=head2 zip

Compresses files older than age using the zip format

=cut

sub zip {
    my $self = shift;

    foreach my $file ($self->get_files) {
        if ($self->test) {
            print "TEST: zipping $file\n";
        } else {
            IO::Compress::Zip::zip $file => $file . '.zip'
                or croak ("Unable to zip $file: $ZipError");
            unlink $file || croak("Unable to purge $file: $!");
        }
    }
}

=head2 bzip2

Compresses files older than age using the bzip2 format

=cut

sub bzip2 {
    my $self = shift;

    foreach my $file ($self->get_files) {
        if ($self->test) {
            print "TEST: bzipping $file\n";
        } else {
            IO::Compress::Bzip2::bzip2 $file => $file . '.bz2'
                or croak ("Unable to bzip2 $file: $Bzip2Error");
            unlink $file || croak("Unable to purge $file: $!");
        }
    }
}

=head2 archive

Archive files older than age

=cut

sub archive {
    my $self        = shift;
    my $archive_dir = $self->archive_directory
        || croak("Archive directory not specified");
    my $directory = $self->directory;
    my %dir_map;

    croak("You cannot archive to the source directory")
        if ($directory eq $archive_dir);

    foreach my $file ($self->get_files) {

        my $path;

        if ($self->recurse) {
            $path = dirname($file);
            $path =~ s/^$directory//g;
            $path =~ s/\/(.*)$/$1/g;
            $path = $archive_dir . '/' . $path;
        } else {
            $path = $archive_dir;
        }

        if ($self->test) {
            print "TEST: move $file to $path\n";
        } else {
            unless (-d $path) {
                mkpath $path || croak("Cannot make directory $path: $!");
            }
            move($file, $path) || croak("Cannot move $file to $path: $!");
        }
    }
}

=head2 get_files

Return an array of files that match the filter criteria. This method is used
internally, but is useful enough to be offered externally

=cut

sub get_files {
    my $self      = shift;
    my $directory = $self->directory || croak("Directory not specified");
    my $pattern   = $self->pattern || croak("Pattern not specified");
    my $epoch     = $self->_get_threshold_date();
    my @files;

    my $rule = File::Find::Rule->new;
    $rule->file;
    $rule->name($pattern);
    $rule->mtime("<$epoch");
    $rule->maxdepth(1) unless $self->recurse;
    @files = $rule->in($directory);

    return @files;
}

sub _get_threshold_date {
    my $self = shift;
    croak("Age parameter not specified") unless $self->age;
    my $date = DateTime->now(time_zone => 'local');
    if ($self->age =~ /^(\d+)(s|m|h|d)$/) {
        my $measure = $1;
        my $unit    = $2;

        $date->add(UNIT_MAP->{$unit} => -$measure);

        return $date->epoch;
    } else {
        croak("Invalid age");
    }
}

=head1 AUTHOR

Dan Horne, C<< <dhorne at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-purge at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Maintenance>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Maintenance

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Maintenance>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Maintenance>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Maintenance>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Maintenance>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dan Horne, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of File::Maintenance
