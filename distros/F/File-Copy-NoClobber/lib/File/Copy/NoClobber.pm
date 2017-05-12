package File::Copy::NoClobber;

use strict;
use warnings;
use Carp;

our $VERSION = '0.2.3';

use parent 'Exporter';
use File::Copy ();
use File::Spec::Functions qw(splitpath catpath catfile);
use File::Basename qw(basename dirname);
use Fcntl;

our @EXPORT = qw(copy move);

my $pattern = " (%02d)";
my $MAX_COUNT = 1e4;

my $WarnNewFile = 0;

sub import {

    my $pkg = shift;

    my %args = @_;

    if ( exists $args{-warn} ) {
        $WarnNewFile = delete $args{-warn};
    }

    $pattern = delete $args{-pattern} // $pattern;
    _check_pattern($pattern);

    @_ = %args;

    __PACKAGE__->export_to_level( 1, $pkg, @_ );

}

sub _check_pattern {

    my $ptn = shift;

    if ( sprintf($ptn,1) eq sprintf($ptn,2) ) {
        croak "Invalid noclobber pattern '$pattern'";
    }

}

sub _declobber {

    my($from,$to) = @_;

    my $from_bn = basename $from;
    my $orig_dest_file = my $dest_file = -d $to ? catfile( $to, $from_bn ) : $to;

    my $fh;

    my $write_test = 1;

    if ( -d $to ) {
        $write_test = -w $to;
    }
    elsif ( -f $to ) {
        $write_test = -w dirname $to;
    }

    if ( not $write_test ) {
        croak "Destination is not writable";
    }

    if ( -f $from and ref $to ne "GLOB" ) {

        if ( !-d dirname $to ) {
            croak "Invalid destination, should be in an existing directory";
        }

        # use eval in case autodie or friends get in here
        my $opened = eval {
            sysopen $fh, $dest_file, O_EXCL|O_CREAT|O_WRONLY;
        };

        my $count = 0;
        my $fp = filename_with_sprintf_pattern( $dest_file );

        while (not $opened and $!{EEXIST} ) {

            $opened = eval {
                sysopen
                    $fh,
                    ($dest_file = sprintf( $fp, ++$count )),
                    O_CREAT|O_EXCL|O_WRONLY;
            };

            if ($count > $MAX_COUNT) {
                croak "Failed to find a nonclobbering filename, tried to increment counter $MAX_COUNT times";
            }

        }

        if (not fileno $fh) {
            croak $!;
        }

        binmode $fh;
        switch_off_buffering($fh);

    }

    if ($dest_file ne $orig_dest_file and $WarnNewFile) {
        carp "Destination changed to " . basename $dest_file;
    }

    return ($fh,$dest_file);

}

sub copy {

    my @args = @_;

    my($from,$to,$buffersize) = @args;

    my($fh,$dest_file) = _declobber($from,$to);

    $args[1] = $fh // $dest_file;

    # return destination filename, as it may be altered
    return File::Copy::copy(@args) && $dest_file;

}

sub move {

    my @args = @_;

    my($from,$to,$buffersize) = @args;

    my($fh,$dest_file) = _declobber($from,$to);
    close $fh;

    $args[1] = $dest_file;

    # return destination filename, as it may be altered
    return File::Copy::move(@args) && $dest_file;

}

sub filename_with_sprintf_pattern {

    (my $path = shift) =~ s/%/%%/g;

    my($vol,$dir,$fn) = splitpath($path);

    if ( $fn =~ /\./ ) {
        $fn =~

            s{    (?= \. [^\.]+ $ )   }
             {        $pattern        }ex

            or die "Failed inserting noclobbering pattern into file";
    }
    else {
       $fn .= $pattern;
    }

    return catpath($vol,$dir,$fn);

}

sub switch_off_buffering {
    my $h = select(shift);
    $|=1;
    select($h);
}

1;

=encoding utf8

=head1 NAME

File::Copy::NoClobber - Rename copied files safely if destination exists

=head1 SYNOPSIS

    use File::Copy::NoClobber;

    copy( "file.txt", "elsewhere/" ); # elsewhere/file.txt
    copy( "file.txt", "elsewhere/" ); # elsewhere/file (01).txt

    # similar with move
    move( "file.txt", "elsewhere/" ); # elsewhere/file (02).txt

    use File::Copy::NoClobber -warn => 1; # warns when name is changed

    use File::Copy::NoClobber -pattern => "[%04d]" # custom noclobber

=head1 DESCRIPTION

The module exports copy() and move(). They are wrappers around C<copy>
and C<move> in L<File::Copy>.

=head1 INTERFACE

=head2 copy( $from, $to [, $buffersize] )

Supports the same arguments as L<File::Copy>.

Checks if the operation would overwrite an existing file, if so adds a
counter to the destination filename as shown in the SYNOPSIS.

The module uses sysopen with O_EXCL and an increasing counter to
determine a working filename. The second argument is then replaced
with this filehandle and passed to C<File::Copy::copy>.

The counter inserted to filenames is C<" (%02d)"> by default, but can
be changed on import.

It returns the filename written to or undef if unsuccessful.

=head2 move( $from, $to )

Supports the same arguments as L<File::Copy>.

Determines destination filename in the same way as C<copy>, but the
move operation is used on the filename rather than the filehandle, to
allow rename to be used.

=head1 DEPENDENCIES

This module does not introduce dependencies. It does not use modules
not already in use in File::Copy.

=head1 AUTHOR

Torbjørn Lindahl C<< torbjorn.lindahl@gmail.com >>

=head1 CONTRIBUTORS

Core ideas from I<Botje>, I<huf> and I<tm604> in #perl@freenode

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016, Torbjørn Lindahl C<< torbjorn.lindahl@gmail.com >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.
