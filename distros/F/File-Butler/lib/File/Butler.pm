#!/usr/bin/perl
################################################################################
# $Id: Butler.pm 2 2010-07-21 21:56:38Z v89326 $
# $URL: file:///S:/svn/File-Butler/trunk/lib/File/Butler.pm $
################################################################################
#
# Title:   File::Butler
# Author:  Kurt Kincaid
# VERSION: 4.0.0
#
################################################################################

package File::Butler;

use warnings;
use strict;
use Moose;
use feature "switch";

=head1 NAME

File::Butler - Handy collection of file-related tools.

=head1 VERSION

Version 4.0.0

=cut

our $VERSION = '4.0.0';

has 'filename' => (
    'is'  => 'rw',
    'isa' => 'Str',
    'required' => 1
);

=head1 SYNOPSIS

A collection of basic file manipulation tools. 

As of version 4.0.0, File::Butler is built around Moose.

    use File::Butler;

    my $fb = File::Butler->new( 'filename' => 'myfile.txt' );
    my $contents = $fb->read();
    my $retval = $fb->append( "Text to be appended." );
    my $retval = $fb->prepend( "Text to be prepended to the beginning of the file." );

Please note that "filename" is a required element during invocation. In 
cases where file contents are to be returned, contents are returned 
either as an array or an array reference, depending upon how the method is called.

=head1 SUBROUTINES/METHODS

=head2 dir

=cut

sub dir {
    my $self = shift;
    my $name = $self->{ 'filename' };
    unless ( -d $name ) {
        die "Directory $name does not exist";
    }
    my @files;
    opendir( my $dh, $name ) || die "Can't opendir $name: $!";
    @files = sort { lc( $a ) cmp lc( $b ) } readdir( $dh );
    closedir $dh;
    chomp @files;
    my @FILES;
    foreach my $file ( @files ) {
        push( @FILES, $file ) unless $file eq "." or $file eq "..";
    }
    if ( wantarray() ) {
        return @FILES;
    }
    else {
        return \@FILES;
    }
}

=head2 read

=cut

sub read {
    my $self = shift;
    my @array;
    open my $FILE, "<", $self->{ 'filename' }
      or die "File $self->{ 'filename' } does not exist";
    while ( <$FILE> ) {
        chomp;
        push( @array, $_ );
    }
    close $FILE;
    if ( wantarray() ) {
        return @array;
    }
    elsif ( defined wantarray() ) {
        my $content = join "\n", @array;
        return $content;
    }
}

=head2 write

=cut

sub write {
    my ( $self, $content ) = @_;
    open my $OUT, ">", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for writing";
    print $OUT $content;
    close $OUT;
    return 1;
}

=head2 append

=cut

sub append {
    my ( $self, $content ) = @_;
    open my $OUT, ">>", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for writing";
    print $OUT $content;
    close $OUT;
    return 1;
}

=head2 prepend

=cut

sub prepend {
    my ( $self, $content ) = @_;
    local $/ = undef;
    open my $IN, "<", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for reading";
    my $old = <$IN>;
    close $IN;
    open my $OUT, ">", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for writing";
    print $OUT $content;
    print $OUT $old;
    close $OUT;
    return 1;
}

=head2 srm

=cut

sub srm {
    my ( $self, $passes ) = @_;
    local $/ = undef;
    open my $IN, "<", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for reading";
    my $old = <$IN>;
    close $IN;
    my $length = length $old;
    for ( 1 .. $passes ) {
        my $text   = "";
        my $method = $_ % 10;
        my $pattern;
        given ( $method ) {
            when ( [ 1, 2, 3 ] ) {
                while ( length $text < $length ) {
                    $text .= sprintf( "%.0f", rand() );
                }
            }
            when ( 4 ) {
                $pattern = "010101";
            }
            when ( 5 ) {
                $pattern = "101010";
            }
            when ( 6 ) {
                $pattern = "100100";
            }
            when ( 7 ) {
                $pattern = "010010";
            }
            when ( 8 ) {
                $pattern = "001001";
            }
            when ( 9 ) {
                $pattern = "000000";
            }
            default {
                $pattern = "111111";
            }
        }
        while ( length $text < $length ) {
            $text .= $pattern;
        }
        open my $OUT, ">", $self->{ "filename" }
          or die "Unable to open $self->{ 'filename' } for writing";
        print $OUT $text;
        close $OUT;
    }
}

=head2 wc

=cut

sub wc {
    my $self = shift;
    my ( $lines, $words, $chars, $text );
    local $/ = undef;
    open my $IN, "<", $self->{ 'filename' }
      or die "Unable to open $self->{ 'filename' } for reading";
    $text = <$IN>;
    close $IN;
    $words = $text =~ s/((^|\s)\S)/$1/g;
    while ( $text =~ /\n/g ) {
        $lines++;
    }
    $chars = length $text;
    return $lines, $words, $chars;
}

=head1 AUTHOR

Kurt Kincaid, C<< <kurt.kincaid at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-butler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Butler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Butler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Butler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Butler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Butler>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Butler/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kurt Kincaid.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
################################################################################
# EOF
