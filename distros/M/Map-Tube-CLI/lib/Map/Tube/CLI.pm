package Map::Tube::CLI;

use strict;
use warnings;
use version;

our $VERSION   = qv('v1.1.0');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::CLI - Command Line Interface for Map::Tube::* map.

=head1 VERSION

Version v1.1.0

=cut

use 5.014;
use utf8::all;
use Map::Tube::Utils qw(is_valid_color);
use Map::Tube::Exception::FoundUnsupportedMap;
use Map::Tube::Exception::InvalidBackgroundColor;
use Map::Tube::Exception::InvalidLineName;
use Map::Tube::Exception::InvalidStationName;
use Map::Tube::Exception::MissingStationName;
use Map::Tube::Exception::MissingMapName;
use Map::Tube::Exception::MissingSupportedMap;
use Map::Tube::CLI::Option;
# Defined in a BEGIN block because Module::Pluggable's 'only' option below is
# evaluated at compile time, i.e. before any ordinary sub further down this file
# would exist.
BEGIN {
    my %SUPPORTED_MAPS = (
        'ATHENS'          => 'Map::Tube::Athens',
        'BARCELONA'       => 'Map::Tube::Barcelona',
        'BEIJING'         => 'Map::Tube::Beijing',
        'BERLIN'          => 'Map::Tube::Berlin',
        'BIELEFELD'       => 'Map::Tube::Bielefeld',
        'BUCHAREST'       => 'Map::Tube::Bucharest',
        'BRUSSELS'        => 'Map::Tube::Brussels',
        'BUDAPEST'        => 'Map::Tube::Budapest',
        'CHICAGO'         => 'Map::Tube::Chicago',
        'COPENHAGEN'      => 'Map::Tube::Copenhagen',
        'DELHI'           => 'Map::Tube::Delhi',
        'DNIPROPETROVSK'  => 'Map::Tube::Dnipropetrovsk',
        'FRANKFURT'       => 'Map::Tube::Frankfurt',
        'GLASGOW'         => 'Map::Tube::Glasgow',
        'HAMBURG'         => 'Map::Tube::Hamburg',
        'HANNOVER'        => 'Map::Tube::Hannover',
        'HONGKONG'        => 'Map::Tube::Hongkong',
        'KAZAN'           => 'Map::Tube::Kazan',
        'KHARKIV'         => 'Map::Tube::Kharkiv',
        'KIEV'            => 'Map::Tube::Kiev',
        'KOELNBONN'       => 'Map::Tube::KoelnBonn',
        'KOLKATTA'        => 'Map::Tube::Kolkatta',
        'KUALALUMPUR'     => 'Map::Tube::KualaLumpur',
        'LEIPZIG'         => 'Map::Tube::Leipzig',
        'LONDON'          => 'Map::Tube::London',
        'LYON'            => 'Map::Tube::Lyon',
        'MADRID'          => 'Map::Tube::Madrid',
        'MALAGA'          => 'Map::Tube::Malaga',
        'MILAN'           => 'Map::Tube::Milan',
        'MINSK'           => 'Map::Tube::Minsk',
        'MOSCOW'          => 'Map::Tube::Moscow',
        'MUENCHEN'        => 'Map::Tube::Muenchen',
        'NAPOLI'          => 'Map::Tube::Napoli',
        'NUREMBERG'       => 'Map::Tube::Nuremberg',
        'NYC'             => 'Map::Tube::NYC',
        'NANJING'         => 'Map::Tube::Nanjing',
        'NIZHNYNOVGOROD'  => 'Map::Tube::NizhnyNovgorod',
        'NOVOSIBIRSK'     => 'Map::Tube::Novosibirsk',
        'OSLO'            => 'Map::Tube::Oslo',
        'PARIS'           => 'Map::Tube::Paris',
        'PRAGUE'          => 'Map::Tube::Prague',
        'RHEINRUHR'       => 'Map::Tube::RheinRuhr',
        'ROME'            => 'Map::Tube::Rome',
        'SAINTPETERSBURG' => 'Map::Tube::SaintPetersburg',
        'SAMARA'          => 'Map::Tube::Samara',
        'SANFRANCISCO'    => 'Map::Tube::SanFrancisco',
        'SINGAPORE'       => 'Map::Tube::Singapore',
        'SOFIA'           => 'Map::Tube::Sofia',
        'STOCKHOLM'       => 'Map::Tube::Stockholm',
        'STUTTGART'       => 'Map::Tube::Stuttgart',
        'SYDNEY'          => 'Map::Tube::Sydney',
        'TBILISI'         => 'Map::Tube::Tbilisi',
        'TOKYO'           => 'Map::Tube::Tokyo',
        'TOULOUSE'        => 'Map::Tube::Toulouse',
        'VIENNA'          => 'Map::Tube::Vienna',
        'WARSAW'          => 'Map::Tube::Warsaw',
        'YEKATERINBURG'   => 'Map::Tube::Yekaterinburg',
    );

    sub supported_maps { return { %SUPPORTED_MAPS } }

}

# Only the officially supported maps are scanned and loaded. Everything else
# under Map::Tube::* (Map::Tube::Server, Map::Tube::Node, ...) is skipped, so a
# missing dependency of an unrelated module cannot produce warnings here.
use Module::Pluggable
    search_path => [ 'Map::Tube' ],
    only        => [ values %{ supported_maps() } ],
    require     => 1,
    inner       => 0,
    max_depth   => 3;

# use Path::Tiny;
use Text::ASCIITable;
use Try::Tiny;
use Moo;
use namespace::autoclean;
use MooX::Options;
with 'Map::Tube::CLI::Option';

=head1 DESCRIPTION

This module provides a simple command line interface  to the package consuming L<Map::Tube>.
The distribution also contains a script C<map-tube> for use at the command line which uses this package.

=head1 SYNOPSIS

You can list all command line options by giving the C<-h> flag.

    $ map-tube -h
    USAGE: map-tube [-h] [options...]

        -m --map=String      Map name
        -s --start=String    Start station name
        -e --end=String      End station name
        -p --preferred       Show preferred route
        -g --generate_map    Generate map as image
        -i --image=String    Name of image file or format (optional; default
                             format: PNG)
        --layout=String      Layout strategy for image (default: dot)
        -b --bgcolor=String  Map background color
        -l --line=String     Line name to map
        --line_mappings      Generate line mappings as table
        --line_notes         Generate line notes
        -M --list_maps       List supported maps
        -L --list_lines      List lines in given map
        -S --list_stations   List stations in given map
        -F --fuzzy           Fuzzy station name matching (on by default if
                             needed; switch off with --no-fuzzy)
        -P --penalty=Real    Change hop count penalty for line changes (default: 0.5)
        -t --tabular         Show routes and notes in tabular format
        -f --force           Force unsupported map (map name becomes case sensitive)
        -D --debug           Run in debug mode
        -V --version         Show version information

        --usage              show a short help message
        -h                   show a compact help message
        --help               show a long help message
        --man                show the manual

=head1 COMMON USAGES

=head2 Finding the Shortest Route

=head3 Shortest Route

You can ask for the shortest route in the London Tube Map as below: (Under Windows use double quotes.)

    $ map-tube --map London --start 'Baker Street' --end 'Wembley Park'

    Baker Street (Bakerloo, Circle, Hammersmith & City, Jubilee, Metropolitan), Finchley Road (Jubilee, Metropolitan), Wembley Park (Jubilee, Metropolitan)

If any of the station names does not exist literally (up to capitalisation),
fuzzy matching will be attempted. If this yields unique stations, they will be
used. Otherwise, the candidate stations are displayed and no route will be
calculated. You can always force fuzzy matching by adding the "--fuzzy"
command line argument.

=head3 Preferred Shortest Route

Now a request for the preferred route:

    $ map-tube --map London --start 'Baker Street' --end 'Euston Square' --preferred

    Baker Street (Circle, Hammersmith & City, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

=head3 Preferred Shortest Route in Tabular Form

And a request for the preferred route displayed as a table: (This also shows the use of short options.)

    $ map-tube -m London -s 'Baker Street' -e 'Euston Square' -p -t
    Metro Map London: Route from Baker Street to Euston Square.

    .--------------------------------------------------------------------.
    | Station Name          | Lines                                      |
    +-----------------------+--------------------------------------------+
    | Baker Street          | Circle, Hammersmith and City, Metropolitan |
    | Great Portland Street | Circle, Hammersmith and City, Metropolitan |
    | Euston Square         | Circle, Hammersmith and City, Metropolitan |
    '-----------------------+--------------------------------------------'

    Baker Street (Circle, Hammersmith & City, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

=head3 Handling of Tube Line Changes

Counting the number of hops is one valid way to measure the distance between two stations.
Practically speaking, however, having to change lines will add to the perceived distance.
To account for this, Map::Tube puts a penalty of one half hop on each line change required,
i.e., routes with fewer line changes are slightly more welcome. You can either switch off
this behaviour by

    $ map-tube -m London -s 'Baker Street' -e 'Euston Square' --penalty 0

or put an even heavier penalty on line changes:

    $ map-tube -m London -s 'Baker Street' -e 'Euston Square' --penalty 2

(In this particular case, the output will be identical because there are no line changes involved.)

=head3 Station Names

Ideally you will know the exact names of the stations, like in the
examples above. If you don't, you can always get a full list of station
names with the C<--list-stations> argument (cf. below). But Map::Tube
tries to help you if it cannot find the exact station name (case never
matters anyway). In this case, it will try to find a similar name.
(What exactly is meant by "similar" is a bit involved; never mind.) If
it finds a unique candidate, it will use that and notify you that it did
some guessing:

    $ map-tube -m London -s Baker -e 'Euston Square'
    Metro Map London: Route from Baker Street (guessed) to Euston Square.

    .--------------------------------------------------------------------.
    | Station Name          | Lines                                      |
    +-----------------------+--------------------------------------------+
    | Baker Street          | Circle, Hammersmith and City, Metropolitan |
    | Great Portland Street | Circle, Hammersmith and City, Metropolitan |
    | Euston Square         | Circle, Hammersmith and City, Metropolitan |
    '-----------------------+--------------------------------------------'

If no clear best guess can be found, you will be offered with some possibilities:

    $ map-tube -m London -s "Back Street" -e 'Euston Square'
    Map::Tube::CLI::run(): ERROR: Invalid Station Name [Back Street]; maybe one of Baker Street
    (Bakerloo, Circle, Hammersmith and City, Jubilee, Metropolitan), Becontree (District),
    Bond Street (Central, Elizabeth, Jubilee), Old Street (Northern), Wood Street (Weaver)?
    (status: 101) file C:/Strawberry/perl/site/lib/Map/Tube/CLI.pm on line 454

You can also use regular expressions:

    $ map-tube -m London -s "Bak.*St.*" -e 'Euston Square'
    Metro Map London: Route from Baker Street (guessed) to Euston Square.

    .--------------------------------------------------------------------.
    | Station Name          | Lines                                      |
    +-----------------------+--------------------------------------------+
    | Baker Street          | Circle, Hammersmith and City, Metropolitan |
    | Great Portland Street | Circle, Hammersmith and City, Metropolitan |
    | Euston Square         | Circle, Hammersmith and City, Metropolitan |
    '-----------------------+--------------------------------------------'

If you can always force fuzzy matching with the argument C<--fuzzy>, or you can
completely disable it with C<--no-fuzzy>.


=head2 Images of Maps

=head3 Generate an Image of the Full Map

To generate a graphical representation of the entire map, follow the command
below. This will generate a PNG file named after the map in your current working
directory. (It will silently overwrite any pre-existing file of the same name.)

    $ map-tube --map Delhi --generate_map

In case you want a different background color to the map then you can try this:

    $ map-tube --map Delhi --bgcolor gray --generate_map

The output file name is chosen automatically according to the map. It will be displayed
on the console. If you want a different file name, do this:

    $ map-tube --map Delhi --generate_map --image Delhicious.png

This allows you also to pick other output formats than PNG. E.g., you might
want a vector graphics file:

    $ map-tube --map Delhi --generate_map --image Delhivector.svg

Or if you are happy with the default file name but still want to have a non-standard format:

    $ map-tube --map Delhi --generate_map --image pdf

Which output formats you can choose depends on your particular GraphViz
installation, so check the GraphViz documentation.

There is a number of different approaches to the layout of such
diagrams, and GraphViz offers several (again, consult the GraphvIz
documentation). The default is C<dot>, but often C<neato> or C<sfdp>
also offer good representations. Which one is "best" is a matter of
taste and also depends on the map at hand.  Try this:

    $ map-tube --map Delhi --generate_map --layout neato

=head3 Generate Just a Line Map

To generate a graphical representation of just a particular line, follow
the command below. This will generate a PNG file named after the line in your
current working directory. (It will silently overwrite any pre-existing file
of the same name.)

    $ map-tube --map London --line Bakerloo --generate_map

In case you want a different background color to the map then you can try this:

    $ map-tube --map London --line DLR --bgcolor yellow --generate_map

=head2 Additional Information on Lines, Stations, and Maps

=head3 Generate Line Mappings as a Table

This will show all stops on the given lane, as far as possible in the correct order:

    $ map-tube --map London --line Bakerloo --line_mappings

All that has been said above about output file names, image formats and layout algorithms
applies also to line maps.

=head3 Generate Line Notes

This will show which other lines are serving the stations on the given line.
Stations are ordered alphabetically. Only stations that are served by at least
one additional line are shown.

    $ map-tube --map London --line Bakerloo --line_notes

It can also be displayed in tabular form:

    $ map-tube --map London --line Bakerloo --line_notes --tabular

=head3 List the Lines for the Given Map

    $ map-tube --map London --list_lines

=head3 List the Stations for the Given Map

    $ map-tube --map London --list_stations

=head3 List all Supported Maps

This will show you a list of all officially supported maps. It will also show you
which of these maps are not currently installed on your machine.

    $ map-tube --list_maps

=head2 Using a Map that is Not Officially Supported

It is also possible to use tube maps that are not officially supported, e.g.,
privately created maps: (This is also helpful while developing a new map.)

    $ map-tube --map 'Slippery Rock' --start 'College Park' --end 'Greyhound station' --force

=head2 Error Handling

If encountering an invalid map or a missing map (i.e not installed), you get an error
message like below:

    $ map-tube --map xYz --start 'Baker Street' --end 'Euston Square'
    ERROR: Unsupported Map [xYz].

The following will produce a similar message if you do not have the tube map of Kazan installed;
if you do have it, it will notify you that the starting station does not exist in this map:

    $ map-tube --map Kazan --start 'Baker Street' --end 'Euston Square'
    ERROR: Missing Map [Kazan].

=head1 SUPPORTED MAPS

The command line parameter C<map> can take one of the following map names. It is
case insensitive, i.e. 'London' and 'lOndOn' are the same.
Use the C<--list_maps> option described above to get an up-to-date version of this list.
Use the C<--force> option described above to use locally installed maps that are not on
that list.

Note that not all officially supported maps might be available at your site. The
C<--list-maps> option will show which aren't. You can either install any missing map
from CPAN, or you could use L<Task::Map::Tube::Bundle> to install the supported maps.
Please make sure you have the latest maps when you install.

=over 4

=item * L<Athens|Map::Tube::Athens>

=item * L<Barcelona|Map::Tube::Barcelona>

=item * L<Beijing|Map::Tube::Beijing>

=item * L<Berlin|Map::Tube::Berlin>

=item * L<Bielefeld|Map::Tube::Bielefeld>

=item * L<Brussels|Map::Tube::Brussels>

=item * L<Bucharest|Map::Tube::Bucharest>

=item * L<Budapest|Map::Tube::Budapest>

=item * L<Chicago|Map::Tube::Chicago>

=item * L<Copenhagen|Map::Tube::Copenhagen>

=item * L<Delhi|Map::Tube::Delhi>

=item * L<Dnipropetrovsk|Map::Tube::Dnipropetrovsk>

=item * L<Frankfurt|Map::Tube::Frankfurt>

=item * L<Glasgow|Map::Tube::Glasgow>

=item * L<Hamburg|Map::Tube::Hamburg>

=item * L<Hongkong|Map::Tube::Hongkong>

=item * L<Kazan|Map::Tube::Kazan>

=item * L<Kharkiv|Map::Tube::Kharkiv>

=item * L<Kiev|Map::Tube::Kiev>

=item * L<KoelnBonn|Map::Tube::KoelnBonn>

=item * L<Kolkatta|Map::Tube::Kolkatta>

=item * L<KualaLumpur|Map::Tube::KualaLumpur>

=item * L<Leipzig|Map::Tube::Leipzig>

=item * L<London|Map::Tube::London>

=item * L<Lyon|Map::Tube::Lyon>

=item * L<Madrid|Map::Tube::Madrid>

=item * L<Malaga|Map::Tube::Malaga>

=item * L<Milan|Map::Tube::Milan>

=item * L<Minsk|Map::Tube::Minsk>

=item * L<Moscow|Map::Tube::Moscow>

=item * L<Muenchen|Map::Tube::Muenchen>

=item * L<Napoli|Map::Tube::Napoli>

=item * L<Nuremberg|Map::Tube::Nuremberg>

=item * L<NYC|Map::Tube::NYC>

=item * L<Nanjing|Map::Tube::Nanjing>

=item * L<NizhnyNovgorod|Map::Tube::NizhnyNovgorod>

=item * L<Novosibirsk|Map::Tube::Novosibirsk>

=item * L<Oslo|Map::Tube::Oslo>

=item * L<Paris|Map::Tube::Paris>

=item * L<Prague|Map::Tube::Prague>

=item * L<RheinRuhr|Map::Tube::RheinRuhr>

=item * L<Rome|Map::Tube::Rome>

=item * L<SaintPetersburg|Map::Tube::SaintPetersburg>

=item * L<Samara|Map::Tube::Samara>

=item * L<SanFrancisco|Map::Tube::SanFrancisco>

=item * L<Singapore|Map::Tube::Singapore>

=item * L<Sofia|Map::Tube::Sofia>

=item * L<Stockholm|Map::Tube::Stockholm>

=item * L<Stuttgart|Map::Tube::Stuttgart>

=item * L<Sydney|Map::Tube::Sydney>

=item * L<Tbilisi|Map::Tube::Tbilisi>

=item * L<Toulouse|Map::Tube::Toulouse>

=item * L<Tokyo|Map::Tube::Tokyo>

=item * L<Vienna|Map::Tube::Vienna>

=item * L<Warsaw|Map::Tube::Warsaw>

=item * L<Yekaterinburg|Map::Tube::Yekaterinburg>

=back

=cut

sub BUILD {
    my ($self) = @_;

    my $plugins     = [ plugins ];
    my $map_name    = $self->{map};
    my $map_uc_name = uc($map_name//'');
    my $all_maps    = supported_maps();
    if (defined $map_name && exists $all_maps->{$map_uc_name}) {
        my $map_full_name = $all_maps->{$map_uc_name};
        $self->{maps}->{$map_uc_name} = $_->new for ( grep { defined($_) && ($_ eq $map_full_name)} @$plugins);
    }

    if ($self->force) {
        if ($map_name =~ /^[-_A-Za-z0-9]+$/) {
            # Unsupported maps are not loaded by Module::Pluggable, so load it here.
            my $class = "Map::Tube::$map_name";
            (my $file = "$class.pm") =~ s{::}{/}g;
            unless (eval { require $file; 1 }) {
                my $error  = $@ || 'unknown error';
                $error =~ s/\s+\z//;
                my @caller = caller(0);
                @caller = caller(2) if $caller[3] eq '(eval)';

                Map::Tube::Exception::FoundUnsupportedMap->throw({
                    method      => __PACKAGE__."::BUILD",
                    message     => "ERROR: Can't load forced map [$map_name]: $error",
                    filename    => $caller[1],
                    line_number => $caller[2] });
            }
            $self->{maps}->{$map_uc_name} = $class->new;
        }
        else {
            my @caller = caller(0);
            @caller = caller(2) if $caller[3] eq '(eval)';

            Map::Tube::Exception::FoundUnsupportedMap->throw({
                method      => __PACKAGE__."::BUILD",
                message     => "ERROR: Can't force invalid map name [$map_name].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }
    }

    $self->_validate_param;

}

=head1 METHODS

=head2 run()

This is the main method provided by the package L<Map::Tube::CLI>. It does not
expect any parameter. Here is the code from the supplied C<map-tube> script.

    use strict; use warnings;
    use Map::Tube::CLI;

    Map::Tube::CLI->new_with_options->run;

=cut

sub run {
    my ($self) = @_;

    my $map_obj = $self->map ? $self->{maps}->{uc($self->map)} : undef;

    # Handle these options first because map name may not be present and is not needed:
    if ($self->version) {
        print _prepare_version_info($map_obj, $self->map), "\n";
        return;
    }
    if ($self->list_maps) {
        my $map_list = _prepare_map_list();
        if ($self->tabular) {
            my $map_table = Text::ASCIITable->new;
            $map_table->setCols('Map Name','Description');
            $map_table->addRow(@$_) for @$map_list;
            print "Supported Metro Maps\n\n";
            no warnings;
            print $map_table;
        } else {
            no warnings;
            print join(', ', @$_), "\n" for @$map_list;
        }
        return;
    }
    if (defined $self->penalty) {
        if ($map_obj->can('line_change_penalty')) {
            $map_obj->line_change_penalty($self->penalty)
        } else {
            warn "Your Map::Tube does not support line change penalties. Please upgrade.\n";
        }
    }

    if ($self->generate_map) {
        $map_obj->bgcolor($self->bgcolor) if defined $self->bgcolor;
        my %graph_args = ( line_name=>$self->line, output_file=>undef );
        if ($self->image) {
            my %img_formats = map { lc($_) => 1 } $map_obj->list_formats();
            if ( exists $img_formats{lc($self->image)} ) {
                $graph_args{format} = lc($self->image);
            }
            else {
                $graph_args{output_file} = $self->image;
                if ( $self->image =~ /.([^.]+)$/ && exists $img_formats{lc($1)} ) {
                    $graph_args{format} = lc($1);
                }
            }
        }
        $graph_args{driver} = $self->layout if $self->layout;
        if ($map_obj->can('render')) {
            my (undef, $fname) = $map_obj->render(%graph_args);
            print "Image written to $fname\n" if $fname;
        }
        else {
            warn "You do not seem to have Map::Tube::Plugin::Graph installed.\n";
        }
    }
    elsif ($self->line_mappings) {
        printf("\n=head1 DESCRIPTION\n\n%s Metro Map: %s Line.\n\n", $self->map, $self->line) unless $self->tabular;
        print _prepare_line_mappings($map_obj, $self->line);
    }
    elsif ($self->line_notes) {
        printf "\n=head1 NOTE\n\n=over 2\n" unless $self->tabular;
        print $self->_prepare_line_notes($map_obj);
        print "\n=back\n" unless $self->tabular;
    }
    elsif ($self->list_lines) {
        print join(",\n", sort @{$map_obj->get_lines}), "\n";
    }
    elsif ($self->list_stations) {
        my $station_list_table = _prepare_station_list($map_obj);
        printf("Metro Map %s: Stations.\n\n", $self->map);
        print $station_list_table;
    }
    else {
        my $route = $map_obj->get_shortest_route($self->start, $self->end);
        $route = $route->preferred if $self->preferred;
        if ($self->tabular) {
            my $route_table = Text::ASCIITable->new;
            $route_table->setCols('Station Name','Lines');
            $route_table->alignCol('Lines','left');
            for my $station(@{$route->nodes()}) {
                $route_table->addRow($station->name, join(', ', @{ $station->line }));
            }
            printf("Metro Map %s: Route from %s%s to %s%s.\n\n", $self->map,
                   $self->start, $self->{start_remark}//'', $self->end, $self->{end_remark}//'');
            print $route_table;
        } else {
            no warnings;
            print $route, "\n";
        }
        if ($self->debug) {
            print "\n---------DEBUG-----------\n";
            foreach my $id (sort keys %{$map_obj->{tables}}) {
                print "$map_obj->{tables}->{$id}\n";
            }
            print "-------------------------\n";
        }
        print "$@\n" if $@;
    }
}

=head2 supported_maps()

This method will produce information on the maps that are generally
recognized by the package L<Map::Tube::CLI>.  It does not expect any
parameter.  It will return a reference to a hash whose keys are plain
text city names (in ALL-CAPS) and whose values are the names of the
modules that implement the maps.

Note that "generally recognized" does not imply that the city/module in question
is actually available on your machine.

=cut


#
#
# PRIVATE METHODS

sub _prepare_line_mappings {
    my ($map, $line_name) = @_;

    my $map_table = Text::ASCIITable->new;
    $map_table->setCols('Station Name','Connected To');

    foreach my $station (map { $_->name } @{ $map->get_stations($line_name) }) {
        $map_table->addRow($station, join(", ", @{$map->get_linked_stations($station, $line_name)}));
    }

    return $map_table;
}

sub _prepare_line_notes {
    my ($self, $map) = @_;
    my $map_name = $self->map;
    my $line_name = $self->line;

    my $line_name_uc = uc($line_name);
    my $line_package = { map  { $_->{name} => 1 }
                         grep { $line_name_uc ne uc($_->name) &&  scalar(@{$_->get_stations}) }
                         @{$map->get_lines}
                       };

    my $notes = $self->tabular ? Text::ASCIITable->new : "";
    $notes->setCols("Line $line_name Station",'is also served by line(s)') if $self->tabular;

    my @stations = map { $_->name } @{ $map->get_stations($line_name) };
    if ( eval { require Unicode::Collate; 1 } ) {
        my $collator = Unicode::Collate->new(level => 1);
        @stations = $collator->sort(@stations);
    } else {
        @stations = sort { lc($a) cmp lc($b) } @stations;
    }

    foreach my $station (@stations) {
        my @lines = grep { $_ ne $line_name && exists $line_package->{$_} } map { $_->name } @{ $map->get_node_by_name($station)->line };
        next unless @lines;
        if ($self->tabular) {
            $notes->addRow($station, join(", ", @lines));
        }
        else {
            my $delim = ' ';
            foreach my $line (@lines) {
                $notes .= sprintf("\n=item * The station \"%s\" is also part of\n", $station) if $delim eq ' ';
                $notes .= sprintf("        %s L<%s Line|Map::Tube::%s::Line::%s>\n",
                                  $delim, $line, $map_name, _guess_package_name($line));
                $delim = '|';
            }
        }
    }

    return $notes;
}

sub _prepare_version_info {
   my ($map, $map_name) = @_;
    my $msg = "Map::Tube::CLI version $VERSION, Map::Tube version: $Map::Tube::VERSION";
    if ($map_name) {
        my $supported_maps  = supported_maps();
        my $map_module_name = $supported_maps->{uc($map_name)} // ( 'Map::Tube::' . $map_name );
        my $version_ref     = $map_module_name . '::VERSION';
        my $map_desc        = $map ? $map->name() // $map_name : '';
        my $map_version;
        {
            no strict;
            $map_version = ${$version_ref} // 'unknown';
        }
        $msg .= ", map $map_name: $map_desc version: $map_version";
    }
    return $msg;
}

sub _prepare_map_list {
    my $supported_maps  = supported_maps();
    my %plugins = map { $_ => 1 } plugins;
    my @map_list;
    for my $map ( sort values %$supported_maps ) {
        my $map_name = '(not installed or not loadable)';
        if (exists $plugins{$map}) {
            try {
                $map_name = $map->new->name();
            } catch {
                $map_name = '(not loadable)';
            }
        }
        $map =~ s/^.*:://;
        push(@map_list, [$map, $map_name]);
    }

    return \@map_list;
}

sub _prepare_station_list {
    my ($map) = @_;

    my $station_table = Text::ASCIITable->new;
    $station_table->setCols('Station Name','Served by lines');
    $station_table->alignCol('Served by lines','left');

    my @stations = @{ $map->get_stations() };

    if ( eval { require Unicode::Collate; 1 } ) {
        my $collator = Unicode::Collate->new(level => 1);
        @stations = $collator->sort(@stations);
    } else {
        @stations = sort { lc($a) cmp lc($b) } @stations;
    }

    foreach my $station (@stations) {
      $station_table->addRow( $station->name, join(', ', @{ $station->line }));
    }

    return $station_table;
}

sub _guess_package_name {
    my ($name) = @_;

    my $_name;
    foreach my $token (split /\s/,$name) {
        next if ($token =~ /\&/);
        $_name .= ucfirst(lc($token));
    }

    return $_name;
}

sub _identify_station {
    my ($self, $station) = @_;
    my @caller = caller(1);
    @caller = caller(3) if $caller[3] eq '(eval)';
    my $map_obj = $self->{maps}->{uc($self->map)};
    my $remark = '';
    my $station_node;
    try {
        $station_node = $map_obj->get_node_by_name($station) unless $self->fuzzy;
    } catch {
    };
    if (!defined $station_node) {
       if ((!defined $self->fuzzy || $self->fuzzy) && $map_obj->can('fuzzy_find')) {
            # Try fuzzy matching.
            # Different strategies depending on whether we have a common regex meta character ( '.', '?', '*', '+', '[' ).
            my @fuzzy_methods;
            push( @fuzzy_methods, 'start', 'in' ) unless $station =~ /[?*+\[]/;
            push( @fuzzy_methods, 'regex' )       if     $station =~ /^[^?*].*[.?*+\[]/;
            push( @fuzzy_methods, 'levenshtein', 'doublemetaphone', 'ngrams' ) unless $station =~/[?*+\[]/;
            my @stations;
            for my $method (@fuzzy_methods) {
                @stations = $map_obj->fuzzy_find(search=>$station, objects=>'stations', method=>$method);
                last if @stations;
            }
            if (@stations == 1) {
                $station = $stations[0]->name();
                $remark = ' (guessed)';
            }
            elsif (@stations == 0) {
                Map::Tube::Exception::InvalidStationName->throw({
                    method      => __PACKAGE__."::run",
                    message     => ( $self->fuzzy
                                     ? "ERROR: No Fuzzy Match for Station Name [$station]."
                                     : "ERROR: Invalid Station Name [$station]."
                                   ),
                    filename    => $caller[1],
                    line_number => $caller[2] });
            }
            else {
                @stations = ( ( map { $_ ->name() } @stations[0..9] ), '...' ) if @stations > 10;
                Map::Tube::Exception::InvalidStationName->throw({
                    method      => __PACKAGE__."::run",
                    message     => ( $self->fuzzy
                                     ? ( "ERROR: Station Not Identified; maybe one of " . join(', ', @stations ) . "?" )
                                     : ( "ERROR: Invalid Station Name [$station]; maybe one of " . join(', ', @stations ) . "?" )
                                   ),
                    filename    => $caller[1],
                    line_number => $caller[2] });
            }
        }
        else {
            warn "You do not seem to have Map::Tube::Plugin::FuzzyFind installed, " .
                 "so you must enter station names correctly.\n" unless $map_obj->can('fuzzy_find');
            Map::Tube::Exception::InvalidStationName->throw({
                method      => __PACKAGE__."::run",
                message     => "ERROR: Invalid Station Name [$station].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }
    }

    return ( $station, $remark );
}

sub _validate_param {
    my ($self) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    my $start   = $self->start;
    my $end     = $self->end;
    my $map     = $self->map;
    my $line    = $self->line;
    my $bgcolor = $self->bgcolor;

    return if $self->version || $self->list_maps;

    Map::Tube::Exception::MissingMapName->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Missing Map Name.",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined $map);

    my $supported_maps = supported_maps();
    $supported_maps->{uc($map)} //= 'Map::Tube::'. $map if $self->force;

    Map::Tube::Exception::FoundUnsupportedMap->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Unsupported Map [$map].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (exists $supported_maps->{uc($map)});

    Map::Tube::Exception::MissingSupportedMap->throw({
        method      => __PACKAGE__."::_validate_param",
        message     => "ERROR: Missing Map [$map].",
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (exists $self->{maps}->{uc($map)});

    if ($self->generate_map) {
        if (defined $bgcolor && !(is_valid_color($bgcolor))) {
            Map::Tube::Exception::InvalidBackgroundColor->throw({
                method      => __PACKAGE__."::_validate_param",
                message     => "ERROR: Invalid background Color [$bgcolor].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }

        if (defined $line) {
            Map::Tube::Exception::InvalidLineName->throw({
                method      => __PACKAGE__."::_validate_param",
                message     => "ERROR: Invalid Line Name [$line].",
                filename    => $caller[1],
                line_number => $caller[2] })
                unless defined $self->{maps}->{uc($map)}->get_line_by_name($line);
        }
    }

    if ($self->line_mappings || $self->line_notes) {

        Map::Tube::Exception::InvalidLineName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Invalid Line Name [$line].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $self->{maps}->{uc($map)}->get_line_by_name($line);
    }

    unless (   $self->generate_map
            || $self->line_mappings
            || $self->line_notes
            || $self->list_lines
            || $self->list_stations) {

        warn "--line option will be ignored" if defined $line;     # --line option has been used for no good

        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [start].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $start;
        ($self->{start}, $self->{start_remark}) = $self->_identify_station($start);

        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [end].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $end;
        ($self->{end}, $self->{end_remark}) = $self->_identify_station($end);

    }

}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 CONTRIBUTORS

Gisbert W. Selke, C<< <gws at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube-CLI/issues>.
I will  be notified and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::CLI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube-CLI/issues>

=item * Search MetaCPAN

L<http://metacpan.org/dist/Map-Tube-CLI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of Map::Tube::CLI
