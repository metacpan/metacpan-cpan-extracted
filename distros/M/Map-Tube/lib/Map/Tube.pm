package Map::Tube;

$Map::Tube::VERSION   = '4.07';
$Map::Tube::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube - Lightweight Routing Framework.

=head1 VERSION

Version 4.07

=cut

use 5.006;
use XML::Twig;
use Data::Dumper;
use Map::Tube::Node;
use Map::Tube::Line;
use Map::Tube::Table;
use Map::Tube::Route;
use Map::Tube::Pluggable;
use Map::Tube::Exception::MissingMapData;
use Map::Tube::Exception::MissingStationName;
use Map::Tube::Exception::InvalidStationName;
use Map::Tube::Exception::MissingStationId;
use Map::Tube::Exception::InvalidStationId;
use Map::Tube::Exception::InvalidStationLineId;
use Map::Tube::Exception::MissingLineId;
use Map::Tube::Exception::InvalidLineId;
use Map::Tube::Exception::MissingLineName;
use Map::Tube::Exception::InvalidLineName;
use Map::Tube::Exception::InvalidLineColor;
use Map::Tube::Exception::FoundMultiLinedStation;
use Map::Tube::Exception::FoundMultiLinkedStation;
use Map::Tube::Exception::FoundSelfLinkedStation;
use Map::Tube::Exception::DuplicateStationId;
use Map::Tube::Exception::DuplicateStationName;
use Map::Tube::Exception::MissingPluginGraph;
use Map::Tube::Exception::MissingPluginFormatter;
use Map::Tube::Exception::MissingPluginFuzzyFind;
use Map::Tube::Exception::MalformedMapData;
use Map::Tube::Exception::InvalidLineStructure;
use Map::Tube::Exception::InvalidStationStructure;
use Map::Tube::Exception::RouteNotFound;
use Map::Tube::Utils qw(to_perl is_same trim common_lines get_method_map is_valid_color);
use Map::Tube::Types qw(Routes Tables Lines NodeMap LineMap Color);

use Moo::Role;
use Role::Tiny qw();
use namespace::autoclean;

=encoding utf8

=head1 DESCRIPTION

The core module defined as Role (Moo) to process  the map data.  It provides the
interface to find the shortest route in terms of stoppage between two nodes.Also
you can get all possible routes between two given nodes.

If you are keen to know the internals of L<Map::Tube> then please follow the note
documented in L<Map::Tube::Cookbook>.

=head1 MAP LEADER BOARD

    +----------------------+----------+------------------------------------------+
    | Author               | PAUSE ID | Map Count (City)                         |
    +----------------------+----------+------------------------------------------+
    | Michal Josef Spacek  | SKIM     | 22 (Bucharest, Budapest, Dnipropetrovsk, |
    |                      |          | Kazan, Kharkiv, Kiev, KualaLumpur,       |
    |                      |          | Malaga, Minsk, Moscow, Nanjing,          |
    |                      |          | NizhnyNovgorod, Novosibirsk, Prague,     |
    |                      |          | SaintPetersburg, Samara, Singapore,      |
    |                      |          | Sofia, Tbilisi, Vienna, Warsaw,          |
    |                      |          | Yekaterinburg                            |
    |                      |          |                                          |
    | Gisbert W Selke      | GWS      | 15 (Beijing, Brussels, Chicago, Glasgow, |
    |                      |          | Hamburg, KoelnBonn, Lyon, Muenchen,      |
    |                      |          | Napoli, Oslo, Rhein/Ruhr, San Francisco, |
    |                      |          | Stockholm, Stuttgart, Toulouse)          |
    |                      |          |                                          |
    | Mohammad Sajid Anwar | MANWAR   | 7 (Barcelona, Delhi, Kolkatta, London,   |
    |                      |          | Madrid, NYC, Tokyo)                      |
    |                      |          |                                          |
    | Renee Baecker        | RENEEB   | 1 (Frankfurt)                            |
    |                      |          |                                          |
    | Stefan Limbacher     | STELIM   | 1 (Nuremberg)                            |
    |                      |          |                                          |
    | Slaven Rezic         | SREZIC   | 1 (Berlin)                               |
    |                      |          |                                          |
    | Errietta Kostala     | ERRIETTA | 1 (Athens)                               |
    |                      |          |                                          |
    | Marco Fontani        | MFONTANI | 1 (Milan)                                |
    |                      |          |                                          |
    | Soren Lund           | SLU      | 1 (Copenhagen)                           |
    |                      |          |                                          |
    | FUNG Cheok Yin       | CYFUNG   | 1 (Hong Kong)                            |
    |                      |          |                                          |
    | Vitali Peil          | VPEIL    | 1 (Bielefeld)                            |
    |                      |          |                                          |
    | Giuseppe Di Terlizzi | GDT      | 1 (Rome)                                 |
    +----------------------+----------+------------------------------------------+

=cut

has [qw(name name_to_id plugins _active_link _other_links _line_stations _line_station_index _common_lines)] => (is => 'rw');
has experimental => (is => 'ro', default => sub { 0 });
has nodes   => (is => 'rw', isa => NodeMap);
has lines   => (is => 'rw', isa => Lines  );
has tables  => (is => 'rw', isa => Tables );
has routes  => (is => 'rw', isa => Routes );
has _lines  => (is => 'rw', isa => LineMap);
has bgcolor => (is => 'rw', isa => Color  );

our $AUTOLOAD;
our $PLUGINS = {
    'Map::Tube::Plugin::Graph'     => 1,
    'Map::Tube::Plugin::FuzzyFind' => 1,
};

sub AUTOLOAD {

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    my $method_map = get_method_map();
    if (exists $method_map->{$name}) {
        my $module    = $method_map->{$name}->{module};
        my $exception = $method_map->{$name}->{exception};
        $exception->throw({
            method      => "${module}::${name}",
            message     => "ERROR: Missing plugin $module.",
            filename    => $caller[1],
            line_number => $caller[2] });
    }
}

sub BUILD {
    my ($self) = @_;

    # Handle lazy attributes.
    my @attributes = (keys %{Moo->_constructor_maker_for(ref($self))->all_attribute_specs});
    unless ((grep /^xml$/, @attributes) || (grep /^json$/, @attributes)) {
        die "ERROR: Can't apply Map::Tube role, missing 'xml' or 'json'.";
    }

    $self->_init_map;
    $self->_load_plugins;
}

=head1 SYNOPSIS

=head2 Common Usage

    use strict; use warnings;
    use Map::Tube::London;

    my $map = Map::Tube::London->new;
    print $map->get_shortest_route('Baker Street', 'Euston Square'), "\n";

You should expect the result like below:

    Baker Street (Circle, Hammersmith & City, Bakerloo, Metropolitan, Jubilee), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

=head2 Special Usage

    use strict; use warnings;
    use Map::Tube::London;

    my $map = Map::Tube::London->new;
    print $map->get_shortest_route('Baker Street', 'Euston Square')->preferred, "\n";

You should now expect the result like below:

    Baker Street (Circle, Hammersmith & City, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

=head1 METHODS

=head2 get_shortest_routes($from, $to)

It expects C<$from> and C<$to> station name, required param. It returns an object
of type L<Map::Tube::Route>. On error it throws exception of type L<Map::Tube::Exception>.

=cut

sub get_shortest_route {
    my ($self, $from, $to) = @_;

    ($from, $to) =
        $self->_validate_input('get_shortest_route', $from, $to);

    my $_from = $self->get_node_by_id($from);
    my $_to   = $self->get_node_by_id($to);

    $self->_capture_common_lines($_from, $_to);

    my $reverse = 0;

    # Found common lines between start and end nodes.
    if (@{$self->{_common_lines}}) {
        my $_common_line = $self->{_common_lines}->[0];
        my $from_index   = $self->{_line_station_index}
                                ->{uc($_common_line)}
                                ->{$_from->id};
        my $to_index     = $self->{_line_station_index}
                                ->{uc($_common_line)}
                                ->{$_to->id};

        # TODO: This cause issue with unidirection route with station index.
        # $reverse = 1 if (defined $from_index
        #                  && defined $to_index
        #                  && ($from_index < $to_index));
    }

    if ($reverse) {
        ($from, $to) = ($to, $from);
        ($_from, $_to) = ($_to, $_from);
    }

    $self->_get_shortest_route($from);

    my $nodes = [];
    while (defined($to) && !(is_same($from, $to))) {
        push @$nodes, $self->get_node_by_id($to);
        $to = $self->_get_path($to);
    }

    push @$nodes, $_from;

    my $_nodes;

    if ($reverse) {
        $_nodes = [ @$nodes ];
    }
    else {
        $_nodes = [ reverse(@$nodes) ];
    }

    my $start = $_nodes->[0];
    my $end   = $_nodes->[-1];

    # If you end up with just 2 nodes i.e. start and end, then
    # double check, if start is directly linked to end node.
    if (scalar(@$_nodes) == 2) {
        my $start_name = $start->name;
        my $end_name   = $end->name;
        unless ($self->_is_directly_linked($start_name, $end_name)) {
            my @caller = caller(0);
            @caller    = caller(2) if $caller[3] eq '(eval)';
            Map::Tube::Exception::RouteNotFound->throw({
                method      => __PACKAGE__."::get_shortest_route",
                message     => "ERROR: Route not found from [$start_name] to [$end_name].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }
    }

    return Map::Tube::Route->new(
        { from  => $start,
          to    => $end,
          nodes => $_nodes,
        }
    );
}

=head2 get_all_routes($from, $to) *** EXPERIMENTAL ***

It expects C<$from> and C<$to> station name, required param. It  returns ref to a
list of objects of type L<Map::Tube::Route>. On error it throws exception of type
L<Map::Tube::Exception>.

Be carefull when using against a large map. You  may encounter warning similar to
as shown below when run against London map.

Deep recursion on subroutine "Map::Tube::_get_all_routes"

However for comparatively smaller map, like below,it is happy to give all routes.

      A(1)  ----  B(2)
     /              \
    C(3)  --------  F(6) --- G(7) ---- H(8)
     \              /
      D(4)  ----  E(5)

=cut

sub get_all_routes {
    my ($self, $from, $to) = @_;

    ($from, $to) =
        $self->_validate_input('get_all_routes', $from, $to);

    return $self->_get_all_routes([ $from ], $to);
}

=head2 name()

Returns map name.

=head2 get_node_by_id($node_id)

Returns an object of type L<Map::Tube::Node> for given C<$node_id>.

=cut

sub get_node_by_id {
    my ($self, $id) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';
    Map::Tube::Exception::MissingStationId->throw({
        method      => __PACKAGE__."::get_node_by_id",
        message     => "ERROR: Missing Station ID.",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $id;

    my $node = $self->{nodes}->{$id};
    Map::Tube::Exception::InvalidStationId->throw({
        method      => __PACKAGE__."::get_node_by_id",
        message     => "ERROR: Invalid Station ID [$id].",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $node;

    # Check if the node name appears more than once with different id.
    my @nodes = $self->_get_node_id($node->name);
    return $node if (scalar(@nodes) == 1);

    my $lines = {};
    foreach my $l (@{$node->line}) {
        $lines->{$l->name} = $l if defined $l->name;
    }
    foreach my $i (@nodes) {
        foreach my $j (@{$self->{nodes}->{$i}->line}) {
            $lines->{$j->name} = $j if defined $j->name;
        }
    }
    $node->line([ values %$lines ]);

    return $node;
}

=head2 get_node_by_name($node_name)

Returns an object of type L<Map::Tube::Node> for given C<$node_name>.

=cut

sub get_node_by_name {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';
    Map::Tube::Exception::MissingStationName->throw({
        method      => __PACKAGE__."::get_node_by_name",
        message     => "ERROR: Missing Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $name;

    my $id = $self->_get_node_id($name);
    Map::Tube::Exception::InvalidStationName->throw({
        method      => __PACKAGE__."::get_node_by_name",
        message     => "ERROR: Invalid Station Name [$name].",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $id;

    return $self->get_node_by_id($id);
}

=head2 get_line_by_id($line_id)

Returns an object of type L<Map::Tube::Line>.

=cut

sub get_line_by_id {
    my ($self, $id) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';
    Map::Tube::Exception::MissingLineId->throw({
        method      => __PACKAGE__."::get_line_by_id",
        message     => "ERROR: Missing Line ID.",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $id;

    my $line = $self->_get_line_object_by_id($id);
    Map::Tube::Exception::InvalidLineId->throw({
        method      => __PACKAGE__."::get_line_by_id",
        message     => "ERROR: Invalid Line ID [$id].",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $line;

    return $line;
}

=head2 get_line_by_name($line_name)

Returns an object of type L<Map::Tube::Line>.

=cut

sub get_line_by_name {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';
    Map::Tube::Exception::MissingLineName->throw({
        method      => __PACKAGE__."::get_line_by_name",
        message     => "ERROR: Missing Line Name.",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $name;

    my $line = $self->_get_line_object_by_name($name);
    Map::Tube::Exception::InvalidLineName->throw({
        method      => __PACKAGE__."::get_line_by_name",
        message     => "ERROR: Invalid Line Name [$name].",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $line;

    return $line;
}

=head2 get_lines()

Returns ref to a list of objects of type L<Map::Tube::Line>.

=cut

sub get_lines {
    my ($self) = @_;

    my $lines = [];
    my $other_links = $self->_other_links;
    foreach (@{$self->{lines}}) {
        next if exists $other_links->{uc($_->id)};
        push @$lines, $_ if defined $_->name;
    }

    return $lines;
}

=head2 get_stations($line_name)

Returns ref to a list of objects of type L<Map::Tube::Node> for the C<$line_name>.
If C<$line_name> is missing, it would return all stations in the map.

=cut

sub get_stations {
    my ($self, $line_name) = @_;

    my $lines    = [];
    my $stations = [];
    my $seen     = {};

    if (defined $line_name) {
        my @caller = caller(0);
        @caller    = caller(2) if $caller[3] eq '(eval)';

        my $line = $self->_get_line_object_by_name($line_name);
        Map::Tube::Exception::InvalidLineName->throw({
            method      => __PACKAGE__."::get_stations",
            message     => "ERROR: Invalid Line Name [$line_name].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $line;

        $lines = [ $self->_get_line_object_by_name($line_name) ];
    }
    else {
        $lines = $self->get_lines;
    }

    foreach my $line (@$lines) {
        foreach my $station (@{$line->{stations}}) {
            unless (exists $seen->{$station->id}) {
                push @$stations, $self->get_node_by_id($station->id);
                $seen->{$station->id} = 1;
            }
        }
    }

    return $stations;
}

=head2 get_next_stations($station_name)

Returns ref to a list of next stations from the given C<$station_name> as objects
of type L<Map::Tube::Node>.

=cut

sub get_next_stations {
    my ($self, $station_name) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';
    Map::Tube::Exception::MissingStationName->throw({
        method      => __PACKAGE__."::get_next_stations",
        message     => "ERROR: Missing Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $station_name;

    my $node_id = $self->_get_node_id($station_name);
    Map::Tube::Exception::InvalidStationName->throw({
        method      => __PACKAGE__."::get_next_stations",
        message     => "ERROR: Invalid Station Name [$station_name].",
        filename    => $caller[1],
        line_number => $caller[2] }) unless defined $node_id;

    my $nodes = [];
    my $node  = $self->get_node_by_id($node_id);
    foreach my $link (split /,/,$node->{link}) {
        push @$nodes, $self->get_node_by_id($link);
    }

    return $nodes;
}

=head2 get_linked_stations($station_name)

Returns ref to a list of linked stations from the given C<$station_name>.

=cut

sub get_linked_stations {
    my ($self, $station_name) = @_;

    my $nodes = $self->get_next_stations($station_name);
    my $linked_stations = [];
    foreach my $node (@$nodes) {
        push @$linked_stations, $node->name;
    }

    return $linked_stations;
}

=head2 bgcolor($color)

Set the background color for the map. It is optional. Please set it before making
call to method L<Map::Tube::Plugin::Graph/"as_image($line_name)">. If not set, it
will try to guess and may not be as good as you would expect.The C<$color> can be
a simply color name or hash code.

=cut

#
#
# DO NOT MAKE IT PUBLIC

sub get_map_data {
    my ($self, $caller, $method) = @_;

    my $data;
    my $xml = $self->xml;
    if ($xml ne '') {
        eval {
            $data = XML::Twig->new->parsefile($xml)->simplify(keyattr => 'stations', forcearray => 0);
            # Handle if there is only one line.
            my $lines = $data->{lines}->{line};
            if (ref($lines) eq 'HASH') {
                $data->{lines}->{line} = [ $lines ];
            }
        };
        unless ($@) {
            $self->_validate_map_structure($data, $caller);
            return $data;
        }

        $@ =~ s/\s+at\s+\S*?\.pm\s+line\s+.*$//;
        Map::Tube::Exception::MalformedMapData->throw({
            method      => $method,
            message     => "ERROR: Malformed Map Data ($xml): $@",
            filename    => $caller->[1],
            line_number => $caller->[2] });
    }
    else {
        my $json = $self->json;
        if ($json ne '') {
            eval { $data = to_perl($json) };
            unless ($@) {
                $self->_validate_map_structure($data, $caller);
                return $data;
            }

            $@ =~ s/\s+at\s+\S*?\.pm\s+line\s+.*$//;
            Map::Tube::Exception::MalformedMapData->throw({
                method      => $method,
                message     => "ERROR: Malformed Map Data ($json): $@",
                filename    => $caller->[1],
                line_number => $caller->[2] });
        }
        else {
            if (!defined $caller) {
                $method = __PACKAGE__.'::get_map_data';
                my @_caller = caller(0);
                @_caller = caller(2) if $_caller[3] eq '(eval)';
                $caller = \@_caller;
            }

            Map::Tube::Exception::MissingMapData->throw({
                method      => $method,
                message     => "ERROR: Missing Map Data.",
                filename    => $caller->[1],
                line_number => $caller->[2] });
        }
    }
}

=head1 PLUGINS

=head2 L<Map::Tube::Plugin::Graph>

The L<Map::Tube::Plugin::Graph> plugin adds the support to generate the entire map
or map for a particular line as base64 encoded string (png image).
As of C<Map::Tube> v3.54 or above, you can now set the background color explicitly.

    use strict; use warnings;
    use MIME::Base64;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new;

    # Optionally, you can override the default background color.
    $tube->bgcolor("gray");

    # Entire map image
    my $name = $tube->name;
    open(my $MAP_IMAGE, ">", "$name.png")
        or die "ERROR: Can't open [$name.png]: $!";
    binmode($MAP_IMAGE);
    print $MAP_IMAGE decode_base64($tube->as_image);
    close($MAP_IMAGE);

    # Just a particular line map image
    my $line = 'Bakerloo';
    open(my $LINE_IMAGE, ">", "$line.png")
        or die "ERROR: Can't open [$line.png]: $!";
    binmode($LINE_IMAGE);
    print $LINE_IMAGE decode_base64($tube->as_image($line));
    close($LINE_IMAGE);

Please refer to the L<documentation|Map::Tube::Plugin::Graph> for more details.

=head2 L<Map::Tube::Plugin::Formatter>

The L<Map::Tube::Plugin::Formatter> plugin adds the  support to format the object
supported by the plugin.

    use strict; use warnings;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new;

    my $node = $tube->get_node_by_name('Baker Street');
    print $node->to_xml,    "\n\n";
    print $node->to_json,   "\n\n";
    print $node->to_yaml,   "\n\n";
    print $node->to_string, "\n\n";

    my $line = $tube->get_line_by_name('Metropolitan');
    print $line->to_xml,    "\n\n";
    print $line->to_json,   "\n\n";
    print $line->to_yaml,   "\n\n";
    print $line->to_string, "\n\n";

    my $route = $tube->get_shortest_route('Baker Street', 'Wembley Park');
    print $route->to_xml,   "\n\n";
    print $route->to_json,  "\n\n";
    print $route->to_yaml,  "\n\n";
    print $route->to_string,"\n\n";

Please refer to the L<documentation|Map::Tube::Plugin::Formatter> for more info.

=head2 L<Map::Tube::Plugin::FuzzyFind>

Gisbert W. Selke, built the add-on for L<Map::Tube> to find stations and lines by
name, possibly partly or inexactly specified. The module is a Moo role which gets
plugged into the Map::Tube::* family automatically once it is installed.

    use strict; use warnings;
    use Map::Tube::London;

    my $tube = Map::Tube::London->new();

    print 'line matches exactly: ', scalar($tube->fuzzy_find(search => 'erloo', objects => 'lines')), "\n";
    print 'line contains       : ', scalar($tube->fuzzy_find(search => 'erloo', objects => 'lines', method  => 'in')), "\n";

Please refer to the L<documentation|Map::Tube::Plugin::FuzzyFind> for more info.

=head1 MAP DATA FORMAT

Map data can be represented in JSON or XML format. The preferred  format is JSON.
C<Map::Tube v3.23> or above comes with a handy script C<map-data-converter>, that
can be used to change the data format of an existing map data.Below is how we can
represent the sample map:

      A(1)  ----  B(2)
     /              \
    C(3)  --------  F(6) --- G(7) ---- H(8)
     \              /
      D(4)  ----  E(5)

=head2 JSON

   {
       "name"  : "sample map",
       "lines" : {
           "line" : [
               { "id" : "A", "name" : "A", "color" : "red"     },
               { "id" : "B", "name" : "B", "color" : "#FFFF00" }
           ]
       },
       "stations" : {
           "station" : [
               { "id" : "A1", "name" : "A1", "line" : "A",   "link" : "B2,C3"    },
               { "id" : "B2", "name" : "B2", "line" : "A",   "link" : "A1,F6"    },
               { "id" : "C3", "name" : "C3", "line" : "A,B", "link" : "A1,D4,F6" },
               { "id" : "D4", "name" : "D4", "line" : "A,B", "link" : "C3,E5"    },
               { "id" : "E5", "name" : "E5", "line" : "B",   "link" : "D4,F6"    },
               { "id" : "F6", "name" : "F6", "line" : "B",   "link" : "B2,C3,E5" },
               { "id" : "G7", "name" : "G7", "line" : "B",   "link" : "F6,H8"    },
               { "id" : "H8", "name" : "H8", "line" : "B",   "link" : "G7"       }
           ]
       }
   }

=head2 XML

    <?xml version="1.0" encoding="UTF-8"?>
    <tube name="sample map">
        <lines>
            <line id="A" name="A" color="red"    />
            <line id="B" name="B" color="#FFFF00"/>
        </lines>
        <stations>
            <station id="A1" name="A1" line="A"   link="B2,C3"   />
            <station id="B2" name="B2" line="A"   link="A1,F6"   />
            <station id="C3" name="C3" line="A,B" link="A1,D4,F6"/>
            <station id="D4" name="D4" line="A,B" link="C3,E5"   />
            <station id="E5" name="E5" line="B"   link="D4,F6"   />
            <station id="F6" name="F6" line="B"   link="B2,C3,E5"/>
            <station id="G7" name="G7" line="B"   link="F6,H8"   />
            <station id="H8" name="H8" line="B"   link="G7"      />
        </stations>
    </tube>

=head1 MAP VALIDATION

=head2 DATA VALIDATION

The package L<Test::Map::Tube> can easily be used to validate raw map data. Anyone
building a new map using L<Map::Tube> is advised to have a unit test as a part of
their distribution.Just like in L<Map::Tube::London> package,there is a unit test
something like below:

    use strict; use warnings;
    use Test::More;
    use Map::Tube::London;
    use Test::Map::Tube;
    ok_map(Map::Tube::London->new);

=head2 FUNCTIONAL VALIDATION

The package L<Test::Map::Tube> can easily be used to validate map
basic functions provided by L<Map::Tube>.

    use strict; use warnings;
    use Test::More;
    use Test::Map::Tube;
    use Map::Tube::London;
    ok_map_functions(Map::Tube::London->new);

It can also easily be used to validate map routing functions provided
by L<Map::Tube>:

    use strict; use warnings;
    use Test::More;
    use Test::Map::Tube;
    use Map::Tube::London;
    my $map = Map::Tube::London->new;
    my @routes = (
        "Route 1|Tower Gateway|Aldgate|Tower Gateway,Tower Hill,Aldgate",
        "Route 2|Liverpool Street|Monument|Liverpool Street,Bank,Monument",
    );
    ok_map_routes($map, \@routes);

=cut

#
#
# PRIVATE METHODS

sub _get_shortest_route {
    my ($self, $from) = @_;

    my $nodes = [];
    my $index = 0;
    my $seen  = {};

    $self->_init_table;
    $self->_set_length($from, $index);
    $self->_set_path($from, $from);

    my $all_nodes = $self->{nodes};
    while (defined($from)) {
        my $length = $self->_get_length($from);
        my $f_node = $all_nodes->{$from};
        $self->_set_active_links($f_node);

        if (defined $f_node) {
            my $links = [ split /\,/, $f_node->{link} ];
            while (scalar(@$links) > 0) {
                my ($success, $link) = $self->_get_next_link($from, $seen, $links);
                # was: $success or ($links = [ grep(!/\b\Q$link\E\b/, @$links) ]) and next;
                # was: next unless defined($link);  -> if this ever happens, we'll be stuck in an infinite loop
                if (!$success) {
                    # If we didn't find any existing node at all, we're done:
                    last unless defined $link;
                    # Else: we found some node but it doesn't fit our needs; so remove it from
                    # the candidates and try the next one:
                    $links = [ grep(!/\b\Q$link\E\b/, @$links) ];
                    next;
                }

                if (($self->_get_length($link) == 0) || ($length > ($index + 1))) {
                    $self->_set_length($link, $length + 1);
                    $self->_set_path($link, $from);
                    push @$nodes, $link;
                }

                $seen->{$link} = 1;
                $links = [ grep(!/\b\Q$link\E\b/, @$links) ];
            }
        }

        $index = $length + 1;
        $from  = shift @$nodes;
        $nodes = [ grep(!/\b\Q$from\E\b/, @$nodes) ] if defined $from;
    }
}

sub _get_all_routes {
    my ($self, $visited, $to) = @_;

    my $last  = $visited->[-1];
    my $nodes = $self->get_node_by_id($last)->link;
    foreach my $id (split /\,/, $nodes) {
        next if _is_visited($id, $visited);

        if (is_same($id, $to)) {
            push @$visited, $id;
            $self->_set_routes($visited);
            pop @$visited;
            last;
        }
    }

    foreach my $id (split /\,/, $nodes) {
        next if (_is_visited($id, $visited) || is_same($id, $to));

        push @$visited, $id;
        $self->_get_all_routes($visited, $to);
        pop @$visited;
    }

    return $self->{routes};
}

sub _map_node_name {
    my ($self, $name, $id) = @_;

    $self->{name_to_id}->{uc($name)} = $id;
}

sub _validate_input {
    my ($self, $method, $from, $to) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Map::Tube::Exception::MissingStationName->throw({
        method      => __PACKAGE__."::$method",
        message     => "ERROR: Missing Station Name.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($from) && defined($to));

    $from = trim($from);
    my $_from = $self->get_node_by_name($from);

    $to = trim($to);
    my $_to = $self->get_node_by_name($to);

    return ($_from->{id}, $_to->{id});
}

sub _xml_data {
    my ($self) = @_;

    return $self->get_map_data;
}

sub _init_map {
    my ($self) = @_;

    my $_lines = {};
    my $lines  = {};
    my $nodes  = {};
    my $tables = {};
    my $_other_links = {};
    my $_seen_nodes  = {};

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    my $method = __PACKAGE__."::_init_map";
    my $data   = $self->get_map_data(\@caller, $method);
    $self->{name} = $data->{name};

    # Pull all lines detail first
    # So that we can check if a station has a valid line attached.
    my @lines;
    if (exists $data->{lines} && exists $data->{lines}->{line}) {
        @lines = (ref $data->{lines}->{line} eq 'HASH')
            ? ($data->{lines}->{line})
            : @{$data->{lines}->{line}};
    }
    my $master_line_data = {};
    foreach (@lines) {
        $master_line_data->{lc $_->{id}} = 1;
    }

    my $has_station_index = {};
    foreach my $station (@{$data->{stations}->{station}}) {
        my $id = $station->{id};

        Map::Tube::Exception::DuplicateStationId->throw({
            method      => $method,
            message     => "ERROR: Duplicate Station ID [$id].",
            filename    => $caller[1],
            line_number => $caller[2] }) if (exists $_seen_nodes->{$id});

        $_seen_nodes->{$id} = 1;
        my $name = $station->{name};

        Map::Tube::Exception::DuplicateStationName->throw({
            method      => $method,
            message     => "ERROR: Duplicate Station Name [$name].",
            filename    => $caller[1],
            line_number => $caller[2] }) if (defined $self->{name_to_id}->{uc($name)});

        $self->_map_node_name($name, $id);
        $tables->{$id} = Map::Tube::Table->new({ id => $id });

        my $_station_lines = [];
        foreach my $_line (split /\,/, $station->{line}) {
            if ($_line =~ /\:/) {
                $_line = $self->_capture_line_station($_line, $id);
                $has_station_index->{$_line} = 1;
            }

            if (!exists $master_line_data->{lc $_line}) {
                Map::Tube::Exception::InvalidStationLineId->throw({
                    method      => $method,
                    message     => "ERROR: Invalid line [$_line] for station [$name].",
                    filename    => $caller[1],
                    line_number => $caller[2] });
            }

            my $uc_line = uc($_line);
            my $line    = $lines->{$uc_line};
            $line = Map::Tube::Line->new({ id => $_line }) unless defined $line;
            $_lines->{$uc_line} = $line;
            $lines->{$uc_line}  = $line;
            push @$_station_lines, $line;
        }

        if (exists $station->{other_link} && defined $station->{other_link}) {
            my @link_nodes = ();
            foreach my $_entry (split /\,/, $station->{other_link}) {
                my ($_link_type, $_nodes) = split /\:/, $_entry, 2;
                my $uc_link_type = uc($_link_type);
                my $line = $lines->{$uc_link_type};
                $line = Map::Tube::Line->new({ id => $_link_type, name => $_link_type }) unless defined $line;
                $_lines->{$uc_link_type} = $line;
                $lines->{$uc_link_type}  = $line;
                $_other_links->{$uc_link_type} = 1;

                push @$_station_lines, $line;
                push @link_nodes, (split /\|/, $_nodes);
            }

            $station->{link} .= "," if $station->{link} ne "";
            $station->{link} .= join(",", @link_nodes);
        }

        $station->{line} = $_station_lines;
        my $node = Map::Tube::Node->new($station);
        $nodes->{$id} = $node;

        foreach my $line (@{$_station_lines}) {
            next if exists $has_station_index->{$line->id};
            push @{$line->{stations}}, $node;
        }
    }

    foreach my $_line (@lines) {
        my $uc_line = uc($_line->{id});
        my $line    = $_lines->{$uc_line};
        if (defined $line) {
            $line->{name}  = $_line->{name};
            $line->{color} = $_line->{color};
            if ($has_station_index) {
                foreach (sort { $a <=> $b } keys %{$self->{_line_stations}->{$uc_line}}) {
                    my $station_id = $self->{_line_stations}->{$uc_line}->{$_};
                    $line->add_station($nodes->{$station_id});
                }
            }
            $_lines->{$uc_line} = $line;
        }
    }

    $self->_order_station_lines($nodes);

    $self->lines([ values %$lines ]);
    $self->_lines($_lines);
    $self->_other_links($_other_links);

    # Populate Node links as ref to Node object
    foreach my $node_id (keys %$nodes) {
        my $node_obj = $nodes->{$node_id};
        foreach my $link (split /\,/,$node_obj->{link}) {
            push @{$node_obj->{links}}, $nodes->{$link};
        }
    }

    $self->nodes($nodes);
    $self->tables($tables);
}

sub _is_directly_linked {
    my ($self, $start_station, $end_station) = @_;
    my $linked_stations = $self->get_linked_stations($start_station);

    return grep { $_ eq $end_station }  @$linked_stations;
}

sub _init_table {
    my ($self) = @_;

    foreach my $id (keys %{$self->{tables}}) {
        $self->{tables}->{$id}->{path}   = undef;
        $self->{tables}->{$id}->{length} = 0;
    }

    $self->{_active_links} = undef;
}

sub _load_plugins {
    my ($self) = @_;

    $self->{plugins} = [ Map::Tube::Pluggable::plugins ];
    foreach my $plugin (@{$self->plugins}) {
        # Only bother applying the approved plugins.
        next unless (exists $PLUGINS->{$plugin});
        Role::Tiny->apply_roles_to_object($self, $plugin);
    }
}

sub _capture_common_lines {
    my ($self, $from, $to) = @_;

    my $from_lines = [ map { $_->id } @{$from->line} ];
    my $to_lines   = [ map { $_->id } @{$to->line}   ];

    $self->{_common_lines} = [ common_lines($from_lines, $to_lines) ];
}

sub _get_common_lines {
    my ($nodes, $active_links) = @_;

    my %_unique_links = ();
    foreach (@{$active_links}) {
        $_unique_links{$_} = 1;
    }

    my %_common_lines = ();
    foreach my $_link (keys %_unique_links) {
        foreach my $_link_line (@{$nodes->{$_link}->line}) {
            $_common_lines{$_link_line->id} = 1;
        }
    }

    return (keys %_common_lines);
}

sub _get_next_link {
    my ($self, $from, $seen, $links) = @_;

    my $nodes        = $self->{nodes};
    my $active_links = $self->{_active_links};

    # Revert changes as it breaks routing (v3.65)
    # Commit id: 49273fd2a0baaedbfc1d02ef7
    # -------------------------------------------
    # my @common_lines = _get_common_lines(
    #     $nodes, [ @{$active_links->[0]}, @{$active_links->[1]} ]
    # );

    my @common_lines = common_lines($active_links->[0], $active_links->[1]);

    if ($self->{experimental} && scalar(@{$self->{_common_lines}})) {
        @common_lines = (@{$self->{_common_lines}}, @common_lines);
    }

    my $link = undef;
    foreach my $_link (@$links) {
        return (0, $_link) if ((exists $seen->{$_link}) || ($from eq $_link));

        my $node = $nodes->{$_link};
        next unless defined $node;

        my @lines = ();
        foreach (@{$node->{line}}) { push @lines, $_->{id}; }

        my @common = common_lines(\@common_lines, \@lines);
        return (1, $_link) if (scalar(@common) > 0);

        $link = $_link;
    }

    return (defined($link), $link);
}

sub _set_active_links {
    my ($self, $node) = @_;

    my $active_links = $self->{_active_links};
    my $links        = [ split /\,/, $node->{link} ];

    if (defined $active_links) {
        shift @$active_links;
        push @$active_links, $links;
    }
    else {
        push @$active_links, $links;
        push @$active_links, $links;
    }

    $self->{_active_links} = $active_links;
}

sub _validate_map_structure {
    my ($self, $data, $caller) = @_;

    unless (exists $data->{lines}
            && exists $data->{lines}->{line}
            && @{$data->{lines}->{line}}) {
        Map::Tube::Exception::InvalidLineStructure->throw({
            method      => __PACKAGE__."::_validate_map_structure",
            message     => "ERROR: Invalid line structure in map data.",
            filename    => $caller->[1],
            line_number => $caller->[2] });
    }

    unless (exists $data->{stations}
            && exists $data->{stations}->{station}
            && @{$data->{stations}->{station}}) {
        Map::Tube::Exception::InvalidStationStructure->throw({
            method      => __PACKAGE__."::_validate_map_structure",
            message     => "ERROR: Invalid station structure in map data.",
            filename    => $caller->[1],
            line_number => $caller->[2] });
    }
}

sub _capture_line_station {
    my ($self, $line, $station_id) = @_;

    my ($line_id, $sequence) = split /\:/, $line, 2;
    $self->{_line_stations}->{uc($line_id)}->{$sequence} = $station_id;
    $self->{_line_station_index}->{uc($line_id)}->{$station_id} = $sequence;

    return $line_id;
}

sub _validate_multi_lined_nodes {
    my ($self, $caller, $node, $id) = @_;

    my %lines = ();
    foreach (@{$node->{line}}) { $lines{$_->{id}}++; }

    my $max_link = 1;
    foreach (keys %lines) {
        $max_link = $lines{$_} if ($max_link < $lines{$_});
    }

    if ($max_link > 1) {
        my $message = sprintf("ERROR: %s has multiple lines %s,",
                              $id, join( ',', grep { $lines{$_} > 1 } keys %lines));

        Map::Tube::Exception::FoundMultiLinedStation->throw({
            method      => __PACKAGE__."::_validate_map_data",
            message     => $message,
            filename    => $caller->[1],
            line_number => $caller->[2] });
    }
}

sub _set_routes {
    my ($self, $routes) = @_;

    my $_routes = [];
    my $nodes   = $self->{nodes};
    foreach my $id (@$routes) {
        push @$_routes, $nodes->{$id};
    }

    my $from  = $_routes->[0];
    my $to    = $_routes->[-1];
    my $route = Map::Tube::Route->new({ from => $from, to => $to, nodes => $_routes });
    push @{$self->{routes}}, $route;
}

sub _get_path {
    my ($self, $id) = @_;

    return $self->{tables}->{$id}->{path};
}

sub _set_path {
    my ($self, $id, $node_id) = @_;

    return unless (defined $id && defined $node_id);
    $self->{tables}->{$id}->{path} = $node_id;
}

sub _get_length {
    my ($self, $id) = @_;

    return 0 unless (defined $id && defined $self->{tables}->{$id});
    return $self->{tables}->{$id}->{length};
}

sub _set_length {
    my ($self, $id, $value) = @_;

    return unless (defined $id && defined $value);
    $self->{tables}->{$id}->{length} = $value;
}

sub _get_table {
    my ($self, $id) = @_;

    return $self->{tables}->{$id};
}

sub _get_node_id {
    my ($self, $name) = @_;

    return unless defined $name;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    return $self->{name_to_id}->{uc($name)};
}

sub _get_line_object_by_name {
    my ($self, $name) = @_;

    $name = uc($name);
    foreach my $line_id (keys %{$self->{_lines}}) {
        my $line = $self->{_lines}->{$line_id};
        if (defined $line && defined $line->name) {
            return $line if ($name eq uc($line->name));
        }
    }

    return;
}

sub _get_line_object_by_id {
    my ($self, $id) = @_;

    $id = uc($id);
    foreach my $line_id (keys %{$self->{_lines}}) {

        my $line = $self->{_lines}->{$line_id};
        if (defined $line && defined $line->name) {
            return $line if ($id eq uc($line->id));
        }
    }

    return;
}

sub _order_station_lines {
    my ($self, $nodes) = @_;

    return unless scalar(keys %$nodes);

    foreach my $node (keys %$nodes) {
        my $_lines_h = {};
        foreach (@{$nodes->{$node}->{line}}) {
            $_lines_h->{$_->id} = $_ if defined $_->name;
        }
        my $_lines_a = [];
        foreach (sort keys %$_lines_h) {
            push @$_lines_a, $_lines_h->{$_};
        }
        $nodes->{$node}->line($_lines_a);
    }
}

sub _is_visited {
    my ($id, $list) = @_;

    foreach (@$list) {
        return 1 if is_same($_, $id);
    }

    return 0;
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube>

=head1 SEE ALSO

=over 2

=item * L<Map::Tube::CLI>

=item * L<Map::Tube::API>

=item * L<Map::Tube::Server>

=item * L<Map::Metro>

=back

=head1 CONTRIBUTORS

=over 2

=item * Michal Špaček, C<< <skim at cpan.org> >>

=item * Slaven Rezic, C<< <srezic at cpan.org> >>

=item * Gisbert W. Selke, C<< <gws at cpan.org> >>

=item * Toby Inkster, C<< <tobyink at cpan.org> >>

=item * Ed J, C<< <etj at cpan.org> >>

=back

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2025 Mohammad Sajid Anwar.

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

1; # End of Map::Tube
