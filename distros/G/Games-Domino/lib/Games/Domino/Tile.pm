package Games::Domino::Tile;

$Games::Domino::Tile::VERSION   = '0.32';
$Games::Domino::Tile::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::Domino::Tile - Represents the tile of the Domino game.

=head1 VERSION

Version 0.32

=cut

use 5.006;
use Data::Dumper;
use Games::Domino::Params qw(ZeroOrOne ZeroToSix);

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

has 'left'   => (is => 'rw', isa => ZeroToSix, required => 1);
has 'right'  => (is => 'rw', isa => ZeroToSix, required => 1);
has 'double' => (is => 'ro', isa => ZeroOrOne, required => 1);
has 'top'    => (is => 'rw', isa => ZeroToSix);
has 'bottom' => (is => 'rw', isa => ZeroToSix);
has 'color'  => (is => 'rw', default => sub { 'blue' });

=head1 DESCRIPTION

It is used internally by L<Games::Domino>.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    unless (exists $_[0]->{double}) {
        if (defined($_[0]->{left})
            && defined($_[0]->{right}) && ($_[0]->{left} == $_[0]->{right})) {
            $_[0]->{double} = 1;
            $_[0]->{top} = $_[0]->{bottom} = $_[0]->{left};
        }
        else {
            $_[0]->{double} = 0;
        }
    }

    die("ERROR: Invalid double attribute for the tile.\n")
        if (defined($_[0]->{left})
            && defined($_[0]->{right})
            && ( (($_[0]->{left} == $_[0]->{right}) && ($_[0]->{double} != 1))
                 ||
                 (($_[0]->{left} != $_[0]->{right}) && ($_[0]->{double} != 0))
               )
        );

    if ($_[0]->{double} == 1) {
        $_[0]->{top} = $_[0]->{bottom} = $_[0]->{left};
    }

    return $class->$orig(@_);
};

=head1 METHODS

=head2 value()

Returns the value of the tile i.e. sum of left and right bips.

    use strict; use warnings;
    use Games::Domino::Tile;

    my $tile = Games::Domino::Tile->new({ left => 1, right => 4 });
    print "Value of the tile is [" . $tile->value . "].\n";

=cut

sub value {
    my ($self) = @_;

    return ($self->{left} + $self->{right});
}

=head2 as_string()

Returns the tile object as string. This method is overloaded as string context.So
if we print the object then this method gets called.  You can explictly call this
method as well. Suppose the tile has 3 left pips and 6 right pips then this would
return it as [3 | 6].

    use strict; use warnings;
    use Games::Domino::Tile;

    my $tile = Games::Domino::Tile->new({ left => 1, right => 4 });
    print "The tile is $tile\n";
    # same as above
    print "The tile is " . $tile->as_string() . "\n";

=cut

sub as_string {
    my ($self) = @_;

    return sprintf("[%d | %d]", $self->left, $self->right);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-Domino>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-domino at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Domino>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Domino::Tile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Domino>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Domino>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Domino>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Domino/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Games::Domino::Tile
