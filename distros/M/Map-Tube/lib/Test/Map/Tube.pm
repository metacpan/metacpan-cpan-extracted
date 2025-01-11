package Test::Map::Tube;

$Test::Map::Tube::VERSION   = '3.91';
$Test::Map::Tube::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Test::Map::Tube - Interface to test Map::Tube features.

=head1 VERSION

Version 3.91

=cut

use strict; use warnings;
use 5.006;
use Carp;
use Test::Builder;
use Data::Compare;
use Map::Tube::Route;

my $TEST      = Test::Builder->new;
my $TEST_BOOL = 1;
my $PLAN      = 0;

=head1 DESCRIPTION

Its main responsibilty is to validate the map data as used by the package that
takes the role of L<Map::Tube>. You can also unit test map functions as well.

=head1 SYNOPSIS

=head2 Validate map data ONLY.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 3.75;
    eval "use Test::Map::Tube $min_ver";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    ok_map(Map::Tube::London->new);

=head2 Validate map functions ONLY.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 3.75;
    eval "use Test::Map::Tube $min_ver";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    ok_map_functions(Map::Tube::London->new);

=head2 Validate map data and functions BOTH.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 3.75;
    eval "use Test::Map::Tube $min_ver tests => 2";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    my $map = Map::Tube::London->new;
    ok_map($map);
    ok_map_functions($map);

=head2 Validate map data, functions and routes.

    use strict; use warnings;
    use Test::More;

    my $min_ver = 3.75;
    eval "use Test::Map::Tube $min_ver tests => 3";
    plan skip_all => "Test::Map::Tube $min_ver required" if $@;

    use Map::Tube::London;
    my $map = Map::Tube::London->new;
    ok_map($map);
    ok_map_functions($map);

    my @routes = (
        "Route 1|Tower Gateway|Aldgate|Tower Gateway,Tower Hill,Aldgate",
        "Route 2|Liverpool Street|Monument|Liverpool Street,Bank,Monument",
    );
    ok_map_routes($map, \@routes);

=cut

sub import {
    my ($self, %plan) = @_;
    my $caller = caller;

    foreach my $function (qw(ok_map not_ok_map ok_map_routes ok_map_functions)) {
        no strict 'refs';
        *{$caller."::".$function} = \&$function;
    }

    $TEST->exported_to($caller);
    $TEST->plan(%plan);

    $PLAN = 1 if (exists $plan{tests});
}

=head1 METHODS

=head2 ok_map($map_object, $message)

Validates the map data. It expects an object of a package that has taken the role
of L<Map::Tube>. You can optionally pass C<$message>.

=cut

sub ok_map ($;$) {
    my ($object, $message) = @_;

    $TEST->plan(tests => 1) unless $PLAN;
    $TEST->is_num(_ok_map($object), $TEST_BOOL, $message);
}

=head2 not_ok_map($map_object, $message)

Reverse of C<ok_map()>.

=cut

sub not_ok_map ($;$) {
    my ($object, $message) = @_;

    $TEST->plan(tests => 1) unless $PLAN;
    $TEST->is_num(_ok_map($object), !$TEST_BOOL, $message);
}

=head2 ok_map_functions($map_object, $message)

Validates the map functions. It expects an object of a package that has taken the
role of L<Map::Tube>. You can  optionally  pass C<$message>. For this method, you
would require C<Map::Tube> v3.75 or above.

=cut

sub ok_map_functions ($;$) {
    my ($object, $message) = @_;

    $TEST->plan(tests => 1) unless $PLAN;
    $TEST->is_num(_ok_map_functions($object), $TEST_BOOL, $message);
}

=head2 ok_map_routes($map_object, \@routes, $message)

Validates the given routes. It expects an  object of a package that has taken the
role of L<Map::Tube> and array ref of list of route details in the format below:

    my @routes = (
        "Route 1|A1|A3|A1,A2,A3",
        "Route 2|A1|B1|A1,A2,B1",
    );

You can optionally pass C<$message>. For this method, you would require C<Test::Map::Tube>
v0.15 or above.

=cut

sub ok_map_routes($$;$) {
    my ($object, $routes, $message) = @_;
    my @errors = _ok_map_routes($object, $routes);
    if (!@errors) {
      $TEST->plan(tests => 1) unless $PLAN;
      return $TEST->is_num($TEST_BOOL, $TEST_BOOL, $message);
    }
    $TEST->plan(tests => 0+@errors) unless $PLAN;
    for (@errors) {
      my ($g, $e, $d) = @$_;
      my ($gs, $es) = map join("\n", @{$_->nodes}), $g, $e;
      $TEST->is_eq($gs, $es, $message||$d)
    }
}

#
#
# PRIVATE METHODS

sub _ok_map {
    my ($object) = @_;

    return 0 unless (defined $object && $object->does('Map::Tube'));

    eval { $object->get_map_data };
    ($@) and (carp('no map data found') and return 0);

    eval { $object->_validate_map_data; };
    return 1 unless ($@);

    carp($@) and return 0;
}

sub _ok_map_functions {
    my ($object) = @_;

    return 0 unless (defined $object && $object->does('Map::Tube'));

    my $actual;
    eval { $actual = $object->get_map_data };
    ($@) and (carp('no map data found') and return 0);

    # get_shortest_route()
    eval { $object->get_shortest_route };
    ($@) or (carp('get_shortest_route() with no param') and return 0);
    eval { $object->get_shortest_route('Foo') };
    ($@) or (carp('get_shortest_route() with one param') and return 0);
    eval { $object->get_shortest_route('Foo', 'Bar') };
    ($@) or (carp('get_shortest_route() with two invalid params') and return 0);
    my $from_station = $actual->{stations}->{station}->[0]->{name};
    my $to_station   = $actual->{stations}->{station}->[1]->{name};
    eval { $object->get_shortest_route($from_station, 'Bar') };
    ($@) or (carp('get_shortest_route() with invalid to station') and return 0);
    eval { $object->get_shortest_route('Foo', $to_station) };
    ($@) or (carp('get_shortest_route() with invalid from station') and return 0);
    eval { $object->get_shortest_route($from_station, $to_station) };
    ($@) and carp($@) and return 0;

    # get_name()
    if (exists $actual->{name} && defined $actual->{name}) {
        ($object->name eq $actual->{name})
            or (carp('name() returns incorrect map name') and return 0);
    }

    # get_lines()
    my $lines_count = scalar(@{$actual->{lines}->{line}});
    (scalar(@{$object->get_lines}) == $lines_count)
        or (carp('get_lines() returns incorrect line entries') and return 0);

    # get_stations()
    eval { $object->get_stations('Not-A-Valid-Line-Name') };
    ($@) or (carp('get_stations() with invalid line name') and return 0);
    my $line_name = $actual->{lines}->{line}->[0]->{name};
    (scalar(@{$object->get_stations($line_name)}) > 0)
        or (carp('get_stations() returns incorrect station entries') and return 0);

    # get_next_stations()
    eval { $object->get_next_stations };
    ($@) or (carp('get_next_stations() with no param'.Dumper($@)) and return 0);
    eval { $object->get_next_stations('Not-A-Valid-Station-Name') };
    ($@) or (carp('get_next_stations() with invalid station name') and return 0);
    (scalar(@{$object->get_next_stations($from_station)}) > 0)
        or (carp('get_next_stations() returns incorrect station entries') and return 0);

    # get_line_by_id()
    eval { $object->get_line_by_id };
    ($@) or (carp('get_line_by_id() with no param') and return 0);
    eval { $object->get_line_by_id('Not-A-Valid-Line-ID') };
    ($@) or (carp('get_line_by_id() with invalid id') and return 0);
    my $line_id = $actual->{lines}->{line}->[0]->{id};
    eval { $object->get_line_by_id($line_id) };
    ($@) and (carp($@) and return 0);

    # get_line_by_name() - handle in case Map::Tube::Plugin::FuzzyNames is installed.
    eval { $object->get_line_by_name($line_name) };
    ($@) and (carp($@) and return 0);
    eval { my $l = $object->get_line_by_name('Not-A-Valid-Line-Name'); croak() unless defined $l };
    ($@) or (carp('get_line_by_name() with invalid line name') and return 0);
    eval { my $l = $object->get_line_by_name; croak() unless defined $l; };
    ($@) or (carp('get_line_by_name() with no param') and return 0);

    # get_node_by_id()
    eval { $object->get_node_by_id };
    ($@) or (carp('get_node_by_id() with no param') and return 0);
    eval { $object->get_node_by_id('Not-A-Valid-Node-ID') };
    ($@) or (carp('get_node_by_id() with invalid node id') and return 0);
    my $station_id = $actual->{stations}->{station}->[0]->{id};
    eval { $object->get_node_by_id($station_id) };
    ($@) and (carp($@) and return 0);

    # add_station()
    eval { $object->get_line_by_id($line_id)->add_station };
    ($@) or (carp('add_station() with no param') and return 0);
    eval { $object->get_line_by_id($line_id)->add_station('Not-A-Valid-Station') };
    ($@) or (carp('add_station() with invalid node object') and return 0);
    eval { $object->get_line_by_id($line_id)->add_station($object->get_node_by_id($station_id)) };
    ($@) and (carp($@) and return 0);

    # get_node_by_name()
    eval { $object->get_node_by_name };
    ($@) or (carp('get_node_by_name() with no param') and return 0);
    eval { $object->get_node_by_name('Not-A-Valid-Node-Name') };
    ($@) or (carp('get_node_by_name() with invalid node name') and return 0);
    eval { $object->get_node_by_name($from_station) };
    ($@) and (carp($@) and return 0);

    return 1;
}

sub _ok_map_routes {
    my ($object, $routes) = @_;
    return 0 unless (defined $object && $object->does('Map::Tube'));
    eval { $object->get_map_data };
    ($@) and (carp('no map data found') and return 0);
    my @failed;
    foreach (@$routes) {
        chomp;
        next if /^\#/;
        next if /^\s+$/;
        my ($description, $from, $to, $route) = split /\|/;
        my $got = $object->get_shortest_route($from, $to);
        my $expected = _expected_route($object, $route);
        next if Compare($got, $expected);
        push @failed, [$got, $expected, $description];
    }
    return @failed;
}

sub _expected_route {
    my ($object, $route) = @_;

    my $nodes   = [];
    foreach my $name (split /\,/,$route) {
        my @_names = $object->get_node_by_name($name);
        push @$nodes, $_names[0];
    }

    return Map::Tube::Route->new(
       { from  => $nodes->[0],
         to    => $nodes->[-1],
         nodes => $nodes
       });
}

=head1 CONTRIBUTORS

=over 2

=item * Ed J

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Map::Tube

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2024 Mohammad Sajid Anwar.

This  program  is  free software; you can redistribute it  and/or modify it under
the  terms  of the the Artistic License (2.0). You may  obtain a copy of the full
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

1; # End of Test::Map::Tube
