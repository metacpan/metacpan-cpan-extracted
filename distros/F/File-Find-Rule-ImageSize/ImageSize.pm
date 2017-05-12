# $Id: ImageSize.pm 875 2002-10-29 11:05:17Z richardc $
package File::Find::Rule::ImageSize;
use strict;

use File::Find::Rule;
use base qw( File::Find::Rule );
use vars qw/$VERSION @EXPORT/;
$VERSION = '0.03';
@EXPORT = @File::Find::Rule::EXPORT;

use Number::Compare;
use Image::Size qw( imgsize );

my $dimension;
sub File::Find::Rule::image_x { $dimension = 'x'; &_match_dimension }
sub File::Find::Rule::image_y { $dimension = 'y'; &_match_dimension }

sub _match_dimension {
    my $self = shift()->_force_object;
    my $axis = $dimension;
    my @rules = map { Number::Compare->new($_) } @_;
    $self->exec( sub {
                     my %h; @h{'x', 'y'} = imgsize($_);
                     my $val = $h{ $axis };
                     return unless defined $val;
                     for (@rules) { return 1 if $_->($val) }
                     return;
                 } );
}

1;

=head1 NAME

File::Find::Rule::ImageSize - rules for matching image dimensions

=head1 SYNOPSIS

 use File::Find::Rule::ImageSize;
 # find images bigger than 20x20
 my @images = find( file => image_x => '>20', image_y => '>20', in => '.' );

=head1 DESCRIPTION

File::Find::Rule::ImageSize interfaces Image::Size to File::Find::Rule
enabling you to find files based upon their dimensions.
Number::Compare is used so that the sizes may be relative values.

=head2 ->image_x( @sizes )
=head2 ->image_y( @sizes )

Match only things with their dimensions constrained by @sizes.  The
specification can be a relative, as implemented by L<Number::Compare>.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>, from an idea by Mark Fowler.

=head1 COPYRIGHT

Copyright (C) 2002 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Number::Compare>, L<Image::Size>

=cut
