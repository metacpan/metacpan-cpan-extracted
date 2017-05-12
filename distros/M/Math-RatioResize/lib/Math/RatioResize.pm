package Math::RatioResize;

use strict;
use warnings;

=head1 NAME

Math::RatioResize - Work out new dimensions for an image (or just a rectangle) when restricted in one dimension.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Given a box dimensions (width and height), and a max width or height, return back the resized dimensions whilst maintaining the aspect-ratio.

 use Math::RatioResize;
 
 my ( $w, $h ) = Math::RatioResize->resize( w => 360, h => 240, max_w => 100 );
 
 $w == 100
 $h == 66.66   # 240 * ( 100 / 360 )

=head1 METHODS

=head2 Class Methods

=head3 resize

As above.

=cut

sub resize
{
    my ( $self, %args ) = @_;
    
    my $w = $args{ w };
    my $h = $args{ h };

    my $max_w = $args{ max_w };
    my $max_h = $args{ max_h };

    if ( $max_w && $w > $max_w )
    {
        $h = $h * ( $max_w / $w );
        $w = $max_w;
    }

    if ( $max_h && $h > $max_h )
    {
        $w = $w * ( $max_h / $h );
        $h = $max_h;
    }

    return $w, $h;
}

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-empty at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-RatioResize>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::RatioResize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-RatioResize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-RatioResize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-RatioResize>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-RatioResize/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
