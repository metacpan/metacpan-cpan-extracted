use 5.10.0;
use strict;
use warnings;

package Map::Metro::Graph;

# ABSTRACT: An entire graph
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use if $] >= 5.016000, feature => 'fc';

use Map::Metro::Elk;
use Types::Standard qw/ArrayRef Bool Int Maybe Object Str/;
use Map::Metro::Types qw/Connection Line LineStation Routing Segment Station Step Transfer/;
use Types::Path::Tiny qw/AbsFile/;
use Graph;
use List::Util qw/any none/;
use String::Trim qw/trim/;
use Eponymous::Hash qw/eh/;
use Try::Tiny;
use Safe::Isa qw/$_call_if_object/;

use Map::Metro::Exceptions;

use Map::Metro::Graph::Connection;
use Map::Metro::Graph::Line;
use Map::Metro::Graph::LineStation;
use Map::Metro::Graph::Route;
use Map::Metro::Graph::Routing;
use Map::Metro::Graph::Segment;
use Map::Metro::Graph::Station;
use Map::Metro::Graph::Step;
use Map::Metro::Graph::Transfer;
use Map::Metro::Emitter;

has filepath => (
    is => 'ro',
    isa => AbsFile,
    required => 1,
);
has wanted_hook_plugins => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Array'],
    predicate => 1,
    handles => {
        all_wanted_hook_plugins => 'elements',
    }
);
has do_undiacritic => (
    is => 'rw',
    isa => Bool,
    default => 1,
);
has default_line_change_weight => (
    is => 'ro',
    isa => Int,
    default => 3,
);
has override_line_change_weight => (
    is => 'ro',
    isa => Maybe[Int],
    predicate => 1,
);
has emit => (
    is => 'ro',
    isa => Object,
    init_arg => undef,
    lazy => 1,
    default => sub { Map::Metro::Emitter->new(wanted_hook_plugins => [shift->all_wanted_hook_plugins]) },
    handles => [qw/get_plugin all_plugins plugin_names/],
);

has stations => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Station ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_station => 'push',
        get_station => 'get',
        find_station => 'first',
        filter_stations => 'grep',
        all_stations  => 'elements',
        station_count => 'count',
    },
);
has lines => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Line ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_line => 'push',
        find_line => 'first',
        all_lines => 'elements',
    },
);
has segments => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Segment ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_segment => 'push',
        all_segments => 'elements',
        filter_segments => 'grep',
    },
);
has line_stations => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ LineStation ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_line_station => 'push',
        all_line_stations  => 'elements',
        line_station_count => 'count',
        find_line_stations => 'grep',
        find_line_station => 'first',
    },
);
has connections => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Connection ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_connection => 'push',
        all_connections  => 'elements',
        connection_count => 'count',
        find_connection => 'first',
        filter_connections => 'grep',
        get_connection => 'get',
    },
);
has transfers => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Transfer ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_transfer => 'push',
        all_transfers => 'elements',
        transfer_count => 'count',
        get_transfer => 'get',
        filter_transfers => 'grep',
    },
);
has routings => (
    is => 'ro',
    traits => ['Array'],
    isa => ArrayRef[ Routing ],
    predicate => 1,
    default => sub { [] },
    init_arg => undef,
    handles => {
        add_routing => 'push',
        all_routings => 'elements',
        routing_count => 'count',
        find_routing => 'first',
        filter_routings => 'grep',
        get_routing => 'get',
    },
);

has full_graph => (
    is => 'ro',
    lazy => 1,
    predicate => 1,
    builder => 1,
);

has asps => (
    is => 'rw',
    lazy => 1,
    builder => 'calculate_shortest_paths',
    predicate => 1,
    init_arg => undef,
);

sub _build_full_graph {
    my $self = shift;

    my $graph = Graph->new;

    foreach my $conn ($self->all_connections) {
        $graph->add_weighted_edge($conn->origin_line_station->line_station_id,
                                  $conn->destination_line_station->line_station_id,
                                  $conn->weight);
    }
    return $graph;
}
sub calculate_shortest_paths { shift->full_graph->APSP_Floyd_Warshall }

sub nocase {
    my $text = shift;
    if($] >= 5.016000) {
        $text = fc $text;
    }
    else {
        $text = lc $text;
    }
    return $text;
}

sub parse {
    my $self = shift;

    $self->build_network;
    $self->construct_connections;

    return $self;
}

sub build_network {
    my $self = shift;

    my @rows = split /\r?\n/ => $self->filepath->slurp_utf8;
    my $context = undef;

    ROW:
    foreach my $row (@rows) {
        next ROW if !length $row || $row =~ m{^[ \t]*#};

        if($row =~ m{^--(\w+)} && (any { $_ eq $1 } qw/stations transfers lines segments/)) {
            $context = $1;
            next ROW;
        }

          $context eq 'stations'  ? $self->add_station($row)
        : $context eq 'transfers' ? $self->add_transfer($row)
        : $context eq 'lines'     ? $self->add_line($row)
        : $context eq 'segments'  ? $self->add_segment($row)
        :                           ()
        ;
    }
}

around add_station => sub {
    my $next = shift;
    my $self = shift;
    my $text = shift;

    $text = trim $text;
    my @names = split m{\h*%\h*} => $text;
    my $name = shift @names;

    if(my $station = $self->get_station_by_name($name, check => 0)) {
        return $station;
    }

    my $id = $self->station_count + 1;
    my $station = Map::Metro::Graph::Station->new(original_name => $name, do_undiacritic => $self->do_undiacritic, eh $name, $id);

    foreach my $another_name (@names) {
        if($another_name =~ m{^:(.+)}) {
            $station->add_search_name($1);
        }
        else {
            $station->add_alternative_name($another_name);
        }
    }
    $self->emit->before_add_station($station);
    $self->$next($station);
};

around add_transfer => sub {
    my $next = shift;
    my $self = shift;
    my $text = shift;

    $text = trim $text;

    my($origin_station_name, $destination_station_name, $option_string) = split /\|/ => $text;
    my $origin_station = $self->get_station_by_name($origin_station_name);
    my $destination_station = $self->get_station_by_name($destination_station_name);

    my $options = defined $option_string ? $self->make_options($option_string, keys => [qw/weight/]) : {};

    my $transfer = Map::Metro::Graph::Transfer->new(origin_station => $origin_station,
                                                    destination_station => $destination_station,
                                                    %$options);

    $self->$next($transfer);
};

around add_line => sub {
    my $next = shift;
    my $self = shift;
    my $text = shift;

    $text = trim $text;
    my($id, $name, $description, $option_string) = split /\|/ => $text;

    my $options = defined $option_string ? $self->make_options($option_string, keys => [qw/color width/]) : {};
    my $line = Map::Metro::Graph::Line->new(%{ $options }, id => $id, name => $name, description => $description);

    $self->$next($line);
};

around add_segment => sub {
    my $next = shift;
    my $self = shift;
    my $text = shift;

    $text = trim $text;
    my($linestring, $start, $end, $option_string) = split /\|/ => $text;
    my @line_ids_with_dir = split m/,/ => $linestring;
    my @clean_line_ids = map { (my $clean = $_) =~ s{[^a-z0-9]}{}gi; $clean } @line_ids_with_dir;

    my $options = defined $option_string ? $self->make_options($option_string, keys => [qw/dir/]) : {};

    #* Check that lines and stations in segments exist in the other lists
    my($origin_station, $destination_station);

    try {
        $self->get_line_by_id($_) foreach @clean_line_ids;
        $origin_station = $self->get_station_by_name($start);
        $destination_station = $self->get_station_by_name($end);
    }
    catch {
        die($_->$_call_if_object('desc') || $_);
    };
    my @both_dir = ();
    my @forward = ();
    my @backward = ();
    my @segments = ();

    foreach my $line_info (@line_ids_with_dir) {
        if($line_info =~ m{^[a-z0-9]+$}i) {
            push @both_dir => $line_info;
        }
        elsif($line_info =~ m{^([a-z0-9]+)->$}i) {
            push @forward => $1;
        }
        elsif($line_info =~ m{^([a-z0-9]+)<-$}i) {
            push @backward => $1;
        }
    }

    if(scalar @both_dir) {
        push @segments => Map::Metro::Graph::Segment->new(line_ids => \@both_dir, origin_station => $origin_station, destination_station => $destination_station);
    }
    if(scalar @forward) {
        push @segments => Map::Metro::Graph::Segment->new(line_ids => \@forward, is_one_way => 1, origin_station => $origin_station, destination_station => $destination_station);
    }
    if(scalar @backward) {
        push @segments => Map::Metro::Graph::Segment->new(line_ids => \@backward, is_one_way => 1, origin_station => $destination_station, destination_station => $origin_station);
    }

    $self->$next(@segments);
};

around add_line_station => sub {
    my $next = shift;
    my $self = shift;
    my $line_station = shift;

    my $exists = $self->get_line_station_by_line_and_station_id($line_station->line->id, $line_station->station->id);
    return $exists if $exists;

    $self->$next($line_station);
    return $line_station;
};

sub get_line_by_id {
    my $self = shift;
    my $line_id = shift; # Str
    return $self->find_line(sub { $_->id eq $line_id }) || die lineid_does_not_exist_in_line_list line_id => $line_id;
}

sub get_station_by_name {
    my $self = shift;
    my $station_name = shift; # Str
    my %args = @_;
    my $check = exists $args{'check'} ? $args{'check'} : 1;

    my $station = $self->find_station(sub { nocase($_->name) eq nocase($station_name) });
    return $station if Station->check($station);

    if($check) {
        $station = $self->find_station(sub { nocase($_->original_name) eq nocase($station_name) });
        return $station if Station->check($station);

        $station = $self->find_station(sub {
            my $current_station = $_;
            if(any { nocase($station_name) eq nocase($_) } $current_station->all_alternative_names) {
                return $current_station;
            }
        });
        return $station if Station->check($station);

        $station = $self->find_station(sub {
            my $current_station = $_;
            if(any { nocase($station_name) eq nocase($_) } $current_station->all_search_names) {
                return $current_station;
            }
        });
        return $station if Station->check($station);

        die station_name_does_not_exist_in_station_list station_name => $station_name;
    }
}

sub get_station_by_id {
    my $self = shift;
    my $id = shift; # Int

    return $self->find_station(sub { $_->id == $id }) || die stationid_does_not_exist station_id => $id;
}

sub get_line_stations_by_station {
    my $self = shift;
    my $station = shift; # Station
    return $self->find_line_stations(sub { $_->station->id == $station->id });
}

sub get_line_station_by_line_and_station_id {
    my $self = shift;
    my $line_id = shift;
    my $station_id = shift;

    return $self->find_line_station(sub { $_->line->id eq $line_id && $_->station->id == $station_id });
}

sub get_line_station_by_id {
    my $self = shift;
    my $line_station_id = shift; # Int

    return $self->find_line_station(sub { $_->line_station_id == $line_station_id });
}

sub get_connection_by_line_station_ids {
    my $self = shift;
    my $first_ls_id = shift; # Int
    my $second_ls_id = shift; # Int

    my $first_ls = $self->get_line_station_by_id($first_ls_id);
    my $second_ls = $self->get_line_station_by_id($second_ls_id);

    return $self->find_connection(
        sub {
             $_->origin_line_station->line_station_id == $first_ls->line_station_id
          && $_->destination_line_station->line_station_id == $second_ls->line_station_id
        }
    );
}

sub next_line_station_id {
    my $self = shift;

    return $self->line_station_count + 1;
}

sub make_options {
    my $self = shift;
    my $string = shift;
    my %args = @_;
    my $keys = exists $args{'keys'} ? $args{'keys'} : [];

    my $options = {};
    my @options = split /, ?/ => $string;

    OPTION:
    foreach my $option (@options) {
        my($key, $value) = split /:/ => $option;

        next OPTION if scalar @$keys && (none { $key eq $_ } @$keys);
        $options->{ $key } = $value;
    }
    return $options;
}

sub construct_connections {
    my $self = shift;

    if(!($self->has_stations && $self->has_lines && $self->has_segments)) {
        die incomplete_parse mapfile => $self->filepath;
    }

    #* Walk through all segments, and all lines for
    #* that segment. Add pairwise connections between
    #* all pair of stations on the same line
    my $next_line_station_id = 0;
    SEGMENT:
    foreach my $segment ($self->all_segments) {

        LINE:
        foreach my $line_id ($segment->all_line_ids) {
            my $line = $self->get_line_by_id($line_id);

            my $origin_line_station = $self->get_line_station_by_line_and_station_id($line_id, $segment->origin_station->id)
                                      ||
                                      Map::Metro::Graph::LineStation->new(
                                          line_station_id => ++$next_line_station_id,
                                          station => $segment->origin_station,
                                          line => $line,
                                      );
            $origin_line_station = $self->add_line_station($origin_line_station);
            $segment->origin_station->add_line($line);

            my $destination_line_station = $self->get_line_station_by_line_and_station_id($line_id, $segment->destination_station->id)
                                           ||
                                           Map::Metro::Graph::LineStation->new(
                                               line_station_id => ++$next_line_station_id,
                                               station => $segment->destination_station,
                                               line => $line,
                                           );
            $destination_line_station = $self->add_line_station($destination_line_station);
            $segment->destination_station->add_line($line);

            my $weight = 1;

            my $conn = Map::Metro::Graph::Connection->new(origin_line_station => $origin_line_station,
                                                           destination_line_station => $destination_line_station,
                                                           weight => $weight);

            my $inv_conn = Map::Metro::Graph::Connection->new(origin_line_station => $destination_line_station,
                                                               destination_line_station => $origin_line_station,
                                                               weight => $weight);

            $origin_line_station->station->add_connecting_station($destination_line_station->station);
            $destination_line_station->station->add_connecting_station($origin_line_station->station) if !$segment->is_one_way;

            $self->add_connection($conn);
            $self->add_connection($inv_conn) if !$segment->is_one_way;
        }
    }

    #* Walk through all stations, and fetch all line_stations per station
    #* Then add a connection between all line_stations of every station
    STATION:
    foreach my $station ($self->all_stations) {
        my @line_stations_at_station = $self->get_line_stations_by_station($station);

        LINE_STATION:
        foreach my $line_station (@line_stations_at_station) {
            my @other_line_stations = grep { $_->line_station_id != $line_station->line_station_id } @line_stations_at_station;

            OTHER_LINE_STATION:
            foreach my $other_line_station (@other_line_stations) {

                my $weight = $self->has_override_line_change_weight ? $self->override_line_change_weight : $self->default_line_change_weight;
                my $conn = Map::Metro::Graph::Connection->new(origin_line_station => $line_station,
                                                               destination_line_station => $other_line_station,
                                                               weight => $weight);
                $self->add_connection($conn);
            }
        }
    }

    #* Walk through all transfers, and add connections between all line stations of the two stations
    TRANSFER:
    foreach my $transfer ($self->all_transfers) {
        my $origin_station = $transfer->origin_station;
        my $destination_station = $transfer->destination_station;
        my @line_stations_at_origin = $self->get_line_stations_by_station($origin_station);

        ORIGIN_LINE_STATION:
        foreach my $origin_line_station (@line_stations_at_origin) {
            my @line_stations_at_destination = $self->get_line_stations_by_station($destination_station);

            DESTINATION_LINE_STATION:
            foreach my $destination_line_station (@line_stations_at_destination) {

                my $conn = Map::Metro::Graph::Connection->new(origin_line_station => $origin_line_station,
                                                              destination_line_station => $destination_line_station,
                                                              weight => $transfer->weight);

                my $inv_conn = Map::Metro::Graph::Connection->new(origin_line_station => $destination_line_station,
                                                                  destination_line_station => $origin_line_station,
                                                                  weight => $transfer->weight);

                $origin_line_station->station->add_connecting_station($destination_line_station->station);
                $destination_line_station->station->add_connecting_station($origin_line_station->station);

                $self->add_connection($conn);
                $self->add_connection($inv_conn);
            }
        }

    }
}

# --> Station
sub ensure_station {
    my $self = shift;
    my $place = shift; # Int|Str|Station

    return $place if Station->check($place);

    try {
        if(Int->check($place)) {
            $place = $self->get_station_by_id($place);
        }
        else {
            $place = $self->get_station_by_name($place);
        }
    }
    catch {
        my $error = $_;
        die ($error->$_call_if_object('desc') || $error);
    };
    return $place;
}

# --> Routing
sub routing_for {
    my $self = shift;
    my $origin = shift;      # Int|Str|Station  The first station. Station id, name or object.
    my $destination = shift; # Int|Str|Station  The final station. Station id, name or object.

    my $origin_station = $self->ensure_station($origin);
    my $destination_station = $self->ensure_station($destination);

    my @origin_line_station_ids = map { $_->line_station_id } $self->get_line_stations_by_station($origin_station);
    my @destination_line_station_ids = map { $_->line_station_id } $self->get_line_stations_by_station($destination_station);

    if($self->has_routings) {
        my $existing_routing = $self->find_routing(sub { $_->origin_station->id == $origin_station->id && $_->destination_station->id == $destination_station->id });
        return $existing_routing if $existing_routing;
    }
    $self->emit->before_start_routing;
    my $routing = Map::Metro::Graph::Routing->new(origin_station => $origin_station, destination_station => $destination_station);

    #* Find all lines going from origin station
    #* Find all lines going to destination station
    #* Get all routes between them
    #* and then, in the third and fourth for, loop over the
    #* found routes and add info about all stations on all lines
    ORIGIN_LINE_STATION:
    foreach my $origin_id (@origin_line_station_ids) {
        my $origin = $self->get_line_station_by_id($origin_id);

        DESTINATION_LINE_STATION:
        foreach my $dest_id (@destination_line_station_ids) {
            my $dest = $self->get_line_station_by_id($dest_id);

            my $graphroute = [ $self->has_asps ? $self->asps->path_vertices($origin_id, $dest_id) : $self->full_graph->SP_Dijkstra($origin_id, $dest_id) ];

            if($origin->possible_on_same_line($dest) && !$origin->on_same_line($dest)) {
                next DESTINATION_LINE_STATION;
            }

            my $route = Map::Metro::Graph::Route->new;

            my($prev_step, $prev_conn, $next_step, $next_conn);

            LINE_STATION:
            foreach my $index (0 .. scalar @$graphroute - 2) {
                my $this_line_station_id = $graphroute->[ $index ];
                my $next_line_station_id = $graphroute->[ $index + 1 ];
                my $next_next_line_station_id = $graphroute->[ $index + 2 ] // undef;



                my $conn = $self->get_connection_by_line_station_ids($this_line_station_id, $next_line_station_id);

                #* Don't continue beyond this route, even it connections exist.
                if($index + 2 < scalar @$graphroute) {
                    $next_conn = defined $next_next_line_station_id ? $self->get_connection_by_line_station_ids($this_line_station_id, $next_line_station_id) : undef;
                    $next_step = Map::Metro::Graph::Step->new(from_connection => $next_conn) if defined $next_conn;
                }
                else {
                    $next_conn = $next_step = undef;
                }

                my $step = Map::Metro::Graph::Step->new(from_connection => $conn);
                $step->previous_step($prev_step) if $prev_step;
                $step->next_step($next_step) if $next_step;

                $next_step->previous_step($step) if defined $next_step;

                $route->add_step($step);
                $prev_step = $step;
                $step = $next_step;

            }

            LINE_STATION:
            foreach my $index (0 .. scalar @$graphroute - 1) {
                my $line_station = $self->get_line_station_by_id($graphroute->[$index]);

                $route->add_line_station($line_station);
            }

            next DESTINATION_LINE_STATION if $route->transfer_on_first_station;
            next DESTINATION_LINE_STATION if $route->transfer_on_final_station;

            $routing->add_route($route);
        }
    }
    $self->emit->before_add_routing($routing) if $self->has_wanted_hook_plugins;
    $self->add_routing($routing);

    return $routing;
}

# --> ArrayRef[Routing]  Routings between every pair of Stations
sub all_pairs {
    my $self = shift;

    my $routings = [];
    $self->calculate_shortest_paths;

    STATION:
    foreach my $station ($self->all_stations) {
        my @other_stations = grep { $_->id != $station->id } $self->all_stations;

        OTHER_STATION:
        foreach my $other_station (@other_stations) {
            push @$routings => $self->routing_for($station, $other_station);
        }
    }
    return $routings;
}

sub to_hash {
    my $self = shift;

    return {
        routings => [
            map { $_->to_hash } $self->all_routings
        ],
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Graph - An entire graph

=head1 VERSION

Version 0.2405, released 2016-07-23.



=head1 SYNOPSIS

    my $graph = Map::Metro->new('Stockholm')->parse;

    my $routing = $graph->routing_for('Universitetet',  'Kista');

    # And then it's traversing time. Also see the
    # Map::Metro::Plugin::Hook::PrettyPrinter hook
    say $routing->origin_station->name;
    say $routing->destination_station->name;

    foreach my $route ($routing->all_routes) {
        foreach my $step ($route->all_steps) {
            say 'Transfer!' if $step->was_line_transfer;
            say $step->origin_line_station->line->id;
            say $step->origin_line_station->station->name;
        }
        say '----';
    }

    #* The constructed Graph object is also available
    my $full_graph = $graph->full_graph;

=head1 DESCRIPTION

This class is at the core of L<Map::Metro>. After a map has been parsed the returned instance of this class contains
the entire network (graph) in a hierarchy of objects.

=head1 ATTRIBUTES


=head2 filepath

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#AbsFile">AbsFile</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#AbsFile">AbsFile</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 default_line_change_weight

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>3</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>3</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 do_undiacritic

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head2 full_graph

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 override_line_change_weight

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Int">Int</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Int">Int</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 wanted_hook_plugins

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 asps

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read/write</td>
</tr>
</table>

<p></p>

=end markdown

=head2 connections

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Connection">Connection</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Connection">Connection</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 emit

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Object">Object</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Object">Object</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 line_stations

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#LineStation">LineStation</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#LineStation">LineStation</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 lines

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Line">Line</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Line">Line</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 routings

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Routing">Routing</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Routing">Routing</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 segments

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Segment">Segment</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Segment">Segment</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 stations

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Map::Metro::Types#Station">Station</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Map::Metro::Types#Station">Station</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head2 transfers

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Transfer">Transfer</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Transfer">Transfer</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p></p>

=end markdown

=head1 METHODS

=head2 routing_for

    my $routing = $graph->routing_for($origin_station,  $destination_station);

C<$origin_station> and C<$destination_station> can be either a station id, a station name or a L<Station|Map::Metro::Graph::Station> object. Both are required, but they can be of different types.

Returns a L<Routing|Map::Metro::Graph::Routing>.

=head2 all_pairs

Takes no arguments. Returns an array reference of L<Routings|Map::Metro::Graph::Routing> between every combination of L<Stations|Map::Metro::Graph::Station>.

=head2 asps

L<Map::Metro> uses L<Graph> under the hood. This method returns the L<Graph/"All-Pairs Shortest Paths (APSP)"> object returned
by the APSP_Floyd_Warshall() method. If you prefer to traverse the graph via this object, observe that the vertices is identified
by their C<line_station_id> in L<Map::Metro::Graph::LineStation>.

Call this method after creation if you prefer long startup times but faster searches.

=head2 full_graph

This returns the complete L<Graph> object created from parsing the map.

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
