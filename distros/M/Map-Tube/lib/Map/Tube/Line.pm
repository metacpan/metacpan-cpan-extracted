package Map::Tube::Line;

$Map::Tube::Line::VERSION   = '3.42';
$Map::Tube::Line::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::Line - Class to represent the line in the map.

=head1 VERSION

Version 3.42

=cut

use 5.006;
use Data::Dumper;

use Map::Tube::Exception::MissingNodeObject;
use Map::Tube::Exception::InvalidNodeObject;
use Map::Tube::Types qw(Color Nodes);

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

has id       => (is => 'ro', required => 1);
has name     => (is => 'rw');
has color    => (is => 'rw', isa => Color);
has stations => (is => 'rw', isa => Nodes);

=head1 DESCRIPTION

It provides simple interface to the 'line' of the map.

=head1 SYNOPSIS

    use strict; use warnings;
    use Map::Tube::Node;
    use Map::Tube::Line;

    my $line = Map::Tube::Line->new({ id => 1, name => 'L1', color => 'red'                  });
    my $node = Map::Tube::Node->new({ id => 1, name => 'N1', link  => '2,3', line => [$line] });

    $line->add_station($node);

=head1 CONSTRUCTOR

The following possible attributes for an object of type L<Map::Tube::Line>.

    +----------+--------------------------------------------------------------+
    | Key      | Description                                                  |
    +----------+--------------------------------------------------------------+
    | id       | Unique Line ID (required).                                   |
    | name     | Unique Line name (optional).                                 |
    | color    | Line color name or hash code (optional).                     |
    | stations | Ref to a list of objects of type Map::Tube::Node (optional). |
    +----------+--------------------------------------------------------------+

=head1 METHODS

=head2 id()

Returns the line id.

=head2 name()

Returns the line name.

=head2 color()

Returns the color name of the line.

=head2 add_station($station)

Adds C<$station>, an object of type L<Map::Tube::Node>, to the line.

=cut

sub add_station {
    my ($self, $station) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingNodeObject->throw({
        method      => __PACKAGE__."::add_station",
        message     => "ERROR: Missing station.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined $station);

    Map::Tube::Exception::InvalidNodeObject->throw({
        method      => __PACKAGE__."::add_station",
        message     => "ERROR: Invalid Node Object [". ref($station). "].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (ref($station) eq 'Map::Tube::Node');

    push @{$self->{stations}}, $station;
}

# TODO: Fix station name with different ids. Refer method Map::Tube::get_stations()
#
#=head2 get_stations()
#
#Returns ref to a list of stations i.e. object of type L<Map::Tube::Node>.
#
#=cut

sub get_stations {
    my ($self) = @_;

    return $self->stations;
}

sub as_string {
    my ($self) = @_;

    return $self->id unless defined $self->name;
    return $self->name;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 BUGS

Please report any bugs or feature requests to C<bug-map-tube at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Map-Tube>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::Line

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Map-Tube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Map-Tube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search CPAN

L<http://search.cpan.org/dist/Map-Tube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2016 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You  may obtain a copy of the full
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

1; # End of Map::Tube::Line
