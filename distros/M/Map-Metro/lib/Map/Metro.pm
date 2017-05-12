use 5.10.0;
use strict;
use warnings;

package Map::Metro;

# ABSTRACT: Public transport graphing
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use Module::Pluggable search_path => ['Map::Metro::Plugin::Map'], require => 1, sub_name => 'system_maps';
use Types::Standard qw/ArrayRef Str/;
use Try::Tiny;
use List::Util qw/any/;

use Map::Metro::Graph;
use Map::Metro::Exceptions;

has map => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef,
    predicate => 1,
    handles => {
        get_map => 'get',
    },
);
has mapclasses => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef,
    default => sub { [] },
    handles => {
        add_mapclass => 'push',
        get_mapclass => 'get',
    },
);
has hooks => (
    is => 'ro',
    isa => ArrayRef[ Str ],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        all_hooks => 'elements',
        hook_count => 'count',
    },
);
has _plugin_ns => (
    is => 'ro',
    isa => Str,
    default => 'Plugin::Map',
    init_arg => undef,
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my %args;
    if(scalar @args == 1) {
        $args{'map'} = shift @args;
    }
    elsif(scalar @args % 2 != 0) {
        my $map = shift @args;
        %args = @args;
        $args{'map'} = $map;
    }
    else {
        %args = @args;
    }

    if(exists $args{'map'} && !ArrayRef->check($args{'map'})) {
        $args{'map'} = [$args{'map'}];
    }
    if(exists $args{'hooks'} && !ArrayRef->check($args{'hooks'})) {
        $args{'hooks'} = [$args{'hooks'}];
    }

    return $class->$orig(%args);
};

sub BUILD {
    my $self = shift;
    my @args = @_;

    if($self->has_map) {
        my @system_maps = map { s{^Map::Metro::Plugin::Map::}{}; $_ } $self->system_maps;
        if(any { $_ eq $self->get_map(0) } @system_maps) {
            my $mapclass = 'Map::Metro::Plugin::Map::'.$self->get_map(0);
            my $mapobj = $mapclass->new(hooks => $self->hooks);
            $self->add_mapclass($mapobj);
        }
        else {
            try { die no_such_map mapname => $self->get_map(0) } catch { die $_->desc };
        }
    }
}

# Borrowed from Mojo::Util
sub decamelize {
    my $self = shift;
    my $string = shift;

    return $string if $string !~ m{[A-Z]};
    return join '_' => map {
                              join ('_' => map { lc } grep { length } split m{([A-Z]{1}[^A-Z]*)})
                           } split '::' => $string;
}

sub parse {
    my $self = shift;
    my %args = @_;

    return Map::Metro::Graph->new(filepath => $self->get_mapclass(0)->maplocation,
                                  do_undiacritic => $self->get_mapclass(0)->do_undiacritic,
                                  wanted_hook_plugins => [$self->all_hooks],
                                  exists $args{'override_line_change_weight'} ? (override_line_change_weight => $args{'override_line_change_weight'}) : (),
                            )->parse;
}

sub available_maps {
    my $self = shift;
    return sort $self->system_maps;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro - Public transport graphing



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Map-Metro"><img src="https://api.travis-ci.org/Csson/p5-Map-Metro.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Map-Metro-0.2405"><img src="https://badgedepot.code301.com/badge/kwalitee/Map-Metro/0.2405" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Map-Metro%200.2405"><img src="https://badgedepot.code301.com/badge/cpantesters/Map-Metro/0.2405" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-72.9%-red.svg" alt="coverage 72.9%" />
</p>

=end html

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SYNOPSIS

    # Install a map
    $ cpanm Map::Metro::Plugin::Map::Stockholm

    # And then
    my $graph = Map::Metro->new('Stockholm', hooks => ['PrettyPrinter'])->parse;

    my $routing = $graph->routing_for('Universitetet', 'Kista');

    # or in a terminal
    $ map-metro.pl route Stockholm Universitetet Kista

prints

    From Universitetet to Kista
    ===========================

    -- Route 1 (cost 15) ----------
    [   T14 ] Universitetet
    [   T14 ] Tekniska högskolan
    [   T14 ] Stadion
    [   T14 ] Östermalmstorg
    [   T14 ] T-Centralen
    [ * T11 ] T-Centralen
    [   T11 ] Rådhuset
    [   T11 ] Fridhemsplan
    [   T11 ] Stadshagen
    [   T11 ] Västra skogen
    [   T11 ] Solna centrum
    [   T11 ] Näckrosen
    [   T11 ] Hallonbergen
    [   T11 ] Kista

    T11  Blue line
    T14  Red line

    *: Transfer to other line
    +: Transfer to other station

=head1 DESCRIPTION

The purpose of this distribution is to find the shortest L<unique|/"What is a unique path?"> route/routes between two stations in a transport network.

See L<Task::MapMetro::Maps> for a list of released maps.

=head2 Methods

=head3 new($city, hooks => [])

B<C<$city>>

The name of the city you want to search connections in. Mandatory, unless you are only going to call L</"available_maps">.

B<C<$hooks>>

Array reference of L<Hooks|Map::Metro::Hook> that listens for events.

=head3 parse()

Returns a L<Map::Metro::Graph> object containing the entire graph.

=head3 available_maps()

Returns an array reference containing the names of all Map::Metro maps installed on the system.

=head2 What is a unique path?

The following rules are a guideline:

If the starting station and finishing station...

...are on the same line there will be no changes to other lines.

...shares multiple lines (e.g., both stations are on both line 2 and 4), each line constitutes a route.

...are on different lines, line changes will take place at suitable station(s). There is no guarantee that the same stations will be chosen for line changes between searches, if there are more than one suitable station to make a change at.

=head1 MORE INFORMATION

L<Map::Metro::Graph> - How to use graph object.

L<Map::Metro::Plugin::Map> - How to make your own maps.

L<Map::Metro::Hook> - How to extend Map::Metro via hooks/events.

L<Map::Metro::Cmd> - A guide to the command line application.

L<Map::Metro::Graph::Connection> - Defines a MMG::Connection.

L<Map::Metro::Graph::Line> - Defines a MMG::Line.

L<Map::Metro::Graph::LineStation> - Defines a MMG::LineStation.

L<Map::Metro::Graph::Route> - Defines a MMG::Route.

L<Map::Metro::Graph::Routing> - Defines a MMG::Routing.

L<Map::Metro::Graph::Segment> - Defines a MMG::Segment.

L<Map::Metro::Graph::Station> - Defines a MMG::Station.

L<Map::Metro::Graph::Step> - Defines a MMG::Step.

L<Map::Metro::Graph::Transfer> - Defines a MMG::Transfer.

=head2 Hierarchy

The following is a conceptual overview of the various parts of a graph:

At first, the map file is parsed. The four types of information (stations, transfers, lines and segments) are translated
into their respective objects.

Next, lines and stations are put together into L<LineStations|Map::Metro::Graph::LineStation>. Every two adjacent LineStations
are put into two L<Connections|Map::Metro::Graph::Connection> (one for each direction).

Now the network is complete, and it is time to start traversing it.

Once a request to search for paths between two stations is given, we first search for the starting L<Station|Map::Metro::Graph::Station> given either a
station id or station name. Then we find all L<LineStations|Map::Metro::Graph::LineStation> for that station.

Then we do the same for the destination station.

And then we walk through the network, from L<LineStation|Map::Metro::Graph::LineStation> to L<LineStation|Map::Metro::Graph::LineStation>, finding their L<Connections|Map::Metro::Graph::Connection>
and turning them into L<Steps|Map::Metro::Graph::Step>, which we then add to the L<Route|Map::Metro::Graph::Route>.

All L<Routes|Map::Metro::Graph::Route> between the two L<Stations|Map::Metro::Graph::Station> are then put into a L<Routing|Map::Metro::Graph::Routing>, which is returned to the user.

=head1 PERFORMANCE

Since 0.2200 performance is less of an issue than it used to be, but it could still be improved. Prior to that version the entire network was analyzed up-front. This is unnecessary when searching one (or a few) routes. For long-running applications it is still possible to pre-calculate all paths, see L<asps|Map::Metro::Graph/"asps()">.

It is also possible to run the backend to some commands in a server, see L<App::Map::Metro>.

=head1 STATUS

This is somewhat experimental. I don't expect that the map file format will I<break>, but it might be
extended. Only the documented api should be used, though breaking changes might occur.

For all maps in the Map::Metro::Plugin::Map namespace (unless noted):

=over 4

=item *

These maps are not an official source. Use accordingly.

=item *

There should be a note regarding what routes the map covers.

=back

=head1 COMPATIBILITY

Under Perl 5.16 or greater, C<fc> will be used instead of C<lc> for some string comparisons. Depending on the map definition
this might lead to some maps not working properly on pre-5.16 Perls.

Prior to version 0.2400, C<Map::Metro> required at least Perl 5.16.

=head1 Map::Metro or Map::Tube?

L<Map::Tube> is the main alternative to C<Map::Metro>. They both have their strong and weak points.

=over 4

=item *

Map::Tube is faster.

=item *

Map::Tube is more stable: It has been on Cpan for a long time, and is under active development.

=item *

Map::Metro has (in my opinion) a better map format.

=item *

Map::Metro supports eg. transfers between stations.

=item *

See L<Task::MapMetro::Maps> and L<Task::Map::Tube> for available maps.

=item *

It is possible to convert Map::Metro maps into Map::Tube maps using L<map-metro.pl|Map::Metro::Cmd/"map-metro.pl metro_to_tube $city">.

=back

=head1 SEE ALSO

=over 4

=item *

L<Task::MapMetro::Maps> - Available maps

=item *

L<Map::Tube> - An alternative

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
