package Docker::Construct;

use 5.012;
use strict;
use warnings;

=head1 NAME

Docker::Construct - Construct the filesystem of an exported docker image.

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

This is the backend module for the L<docker-construct> command-line tool. For
basic usage, refer to its documentation instead.

    use Docker::Construct qw(construct);

    # Minimal usage
    construct('path/to/image.tar', 'path/to/output/dir');

    # With options
    construct(
        image           => 'path/to/image.tar',
        dir             => 'path/to/output.dir',
        quiet           => 1,
        include_config  => 1
    )

=cut

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(construct);

use Carp;
use JSON;
use Scalar::Util qw(openhandle);
use File::Spec::Functions qw(splitpath catfile);
use File::Path qw(remove_tree);

=head2 construct()

Reconstruct the the filesystem of the specified tarball (output from
the C<docker save> command) inside the specified directory. If only two
arguments are given, they are interpreted as the paths to the input tarball
and output directory respectively. If more arguments are given, the arguments
are interpreted as a hash. A hash allows you specify additional options and the
input tarball and output directory are specified with the C<image> and C<dir>
keys respectively.

=head2 Options

=over 4

=item * image I<(required)>

Path to the input tarball

=item * dir I<(required)>

Path to the output directory (must exist already)

=item * quiet

If true, progress will not be reported on stderr.

=item * include_config

If true, include the image's config json file as F<config.json> in the
root of the extracted filesystem.

=back
=cut

sub construct {
    # Parse parameters
    my %params;
    if ( @_ == 2 ) {
        ( $params{image}, $params{dir} ) = @_;
    }
    else {
        %params = @_;
    }

    croak "must specify input image tarball 'image'"    unless $params{image};
    croak "must specify output directory 'dir'"         unless $params{dir};
    my $image   = $params{image};
    my $dir     = $params{dir};
    croak "file not found: $image"      unless -f $image;
    croak "directory not found: $dir"   unless -d $dir;

    # Get list of files in initial image
    my @imagefiles = _read_file_list($image);

    croak "this does not seem to be a docker image (missing manifest.json)"
        unless grep {$_ eq 'manifest.json'} @imagefiles;

    # Extract image manifest.
    my %manifest = %{
        decode_json(
            _read_file_from_tar($image, 'manifest.json')
        )->[0]
    };

    # We're gonna create a list of the whiteout files in the image
    # (keyed by layer). The whiteout files indicate files from
    # previous layers to be deleted and are named after the files
    # they delete but prefixed with `.wh.`
    my %wh;
    for my $layer ( @{$manifest{Layers}} ) {
        my $layer_abbrev = substr($layer,0,12);
        print STDERR "reading layer: $layer_abbrev...\n" unless $params{quiet};

        $wh{$layer} = [];

        my $layer_fh    = _stream_file_from_tar($image, $layer);
        my $filelist    = _exec_tar($layer_fh, '-t');

        while (<$filelist>) {
            chomp;
            my ($dirname, $basename) = (splitpath $_)[1,2];
            if ($basename =~ /^\.wh\./) {
                my $to_delete = catfile $dirname, ( $basename =~ s/^\.wh\.//r );
                push @{ $wh{$layer} }, $to_delete;
            }
        }

        close $filelist     or croak $! ?   "could not close pipe: $!"
                                        :   "exit code $? from tar";
        close $layer_fh     or croak $! ?   "could not close pipe: $!"
                                        :   "exit code $? from tar";

    }

    # Extract each layer, ignoring the whiteout files and then removing
    # the files that are meant to be deleted after each layer.
    for my $layer ( @{$manifest{Layers}} ) {
        my $layer_abbrev    = substr $layer, 0, 12;
        print STDERR "extracting layer: $layer_abbrev...\n" unless $params{quiet};

        my $layer_fh    = _stream_file_from_tar($image, $layer);
        my $extract_fh  = _exec_tar($layer_fh, '-C', $dir, qw'-x --exclude .wh.*');

        close $extract_fh   or croak $! ?   "could not close pipe: $!"
                                        :   "exit code $? from tar";
        close $layer_fh     or croak $! ?   "could not close pipe: $!"
                                        :   "exit code $? from tar";

        for my $file ( @{ $wh{$layer} }) {
            my $path = catfile $dir, $file;
            if (-f $path) {
                unlink $path or carp "failed to remove file: $path";
            }
            elsif (-d $path) {
                remove_tree $path;

            }
        }
    }

    if ($params{include_config}) {
        my $config = $manifest{Config};
        carp "wanted to include config json but couldn't find it in manifest." unless defined $config;

        print STDERR "extracting config: $config...\n" unless $params{quiet};

        my $outfile = catfile $dir, 'config.json';
        open(my $config_write, '>', $outfile) or croak "could not open $outfile: $!";

        my $config_read = _exec_tar($image, '-xO', $config);
        while(<$config_read>) {
            print $config_write $_;
        }

        close $config_write  or croak        "could not close $outfile: $!";
        close $config_read   or croak $! ?   "could not close pipe: $!"
                                         :   "exit code $? from tar";

    }

    print STDERR "done.\n" unless $params{quiet};

}

# Take a tar input (either a filename or a filehandle to one)
# and return the list of files in the archive.
sub _read_file_list {
    my $fh = _exec_tar(shift, '-t');

    my @filelist = <$fh>;
    chomp @filelist;

    close $fh       or croak $! ?   "could not close pipe: $!"
                                :   "exit code $? from tar";

    return @filelist;
}

# Take a tar input (either a filename or a filehandle to one)
# and the name of a file in the archive and return the file's text.
sub _read_file_from_tar {
    my $fh = _stream_file_from_tar(@_);
    my $content;
    {
        local $/ = undef;
        $content = <$fh>;
    }
    close $fh
        or croak $! ?   "could not close pipe: $!"
                    :   "exit code $? from tar";
    return $content;
}

# Take a tar input (either a filename or a filehandle to one)
# and the name of a file in the archive and return an open
# filehandle that streams the file's text.
sub _stream_file_from_tar {
    my $input = shift;
    my $path    = shift;

    return _exec_tar($input, '-xO', $path);
}

# Takes as its first argument, either the filename for a tar archive
# or an open filehandle that a tar archive can be read from. The remaining
# arguments are used as arguments to `tar`. Starts executing the command
# and the returns a filehandle that streams the command's stdout.
sub _exec_tar {
    my $input   = shift;
    my @args    = @_;

    my $read_fh;
    if (openhandle $input) {
        # If input is a filehandle, then we fork and pipe input
        # through the command to the output handle.
        my @command = ('tar', @args);
        my $pid = open($read_fh, '-|');
        croak "could not fork" unless defined $pid;
        do { open(STDIN, '<&', $input); exec @command; } unless $pid;
    }
    else {
        # Otherwise, we assume input is a filename and just exec
        # tar on it.
        my @command = ('tar', '-f', $input, @args);
        open ($read_fh, '-|', @command)   or croak "could not exec tar";
    }
    return $read_fh;
}

=head1 AUTHOR

Cameron Tauxe, C<< <camerontauxe at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
