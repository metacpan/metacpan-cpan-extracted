package Map::Tube::CLI;

use strict;
use warnings;
use version;

our $VERSION   = qv('v1.0.0');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::CLI - Command Line Interface for Map::Tube::* map.

=head1 VERSION

Version v1.0.0

=cut

use 5.006;
use utf8::all;
use Carp qw(croak);
use Data::Dumper;
use MIME::Base64;
use Map::Tube::Utils qw(is_valid_color);
use Map::Tube::Exception::FoundUnsupportedMap;
use Map::Tube::Exception::InvalidBackgroundColor;
use Map::Tube::Exception::InvalidLineName;
use Map::Tube::Exception::InvalidStationName;
use Map::Tube::Exception::MissingStationName;
use Map::Tube::Exception::MissingMapName;
use Map::Tube::Exception::MissingSupportedMap;
use Map::Tube::CLI::Option;
use Module::Pluggable
    search_path => [ 'Map::Tube' ],
    require     => 1,
    inner       => 0,
    max_depth   => 3;

use Path::Tiny;
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
        -l --line=String     Line name to map
        -b --bgcolor=String  Map background color
        --line_mappings      Generate line mappings as table
        --line_notes         Generate line notes
        -M --list_maps       List supported maps
        -L --list_lines      List lines in given map
        -S --list_stations   List stations in given map
        -t --tabular         Show route as table (not as list)
        -f --force           Force unsupported map (map name becomes case sensitive)
        -D --debug           Run in debug mode
        -V --version         Show version information

        --usage              show a short help message
        -h                   show a compact help message
        --help               show a long help message
        --man                show the manual

=head1 COMMON USAGES

=head2 Shortest Route

You can ask for the shortest route in the London Tube Map as below: (Under Windows use double quotes.)

    $ map-tube --map London --start 'Baker Street' --end 'Wembley Park'

    Baker Street (Bakerloo, Circle, Hammersmith & City, Jubilee, Metropolitan), Finchley Road (Jubilee, Metropolitan), Wembley Park (Jubilee, Metropolitan)

=head2 Preferred Shortest Route

Now a request for the preferred route:

    $ map-tube --map London --start 'Baker Street' --end 'Euston Square' --preferred

    Baker Street (Circle, Hammersmith & City, Metropolitan), Great Portland Street (Circle, Hammersmith & City, Metropolitan), Euston Square (Circle, Hammersmith & City, Metropolitan)

=head2 Preferred Shortest Route in Tabular Form

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

=head2 Generate Full Map

To generate a graphical representation of the entire map, follow the command
below. This will generate a PNG file named after the map in your current working
directory. (It will silently overwrite any pre-existing file of the same name.)

    $ map-tube --map Delhi --generate_map

In case you want a different background color to the map then you can try this:

    $ map-tube --map Delhi --bgcolor gray --generate_map

=head2 Generate Just a Line Map

To generate a graphical representation of just a particular line, follow
the command below. This will generate a PNG file named after the line in your
current working directory. (It will silently overwrite any pre-existing file
of the same name.)

    $ map-tube --map London --line Bakerloo --generate_map

In case you want a different background color to the map then you can try this:

    $ map-tube --map London --line DLR --bgcolor yellow --generate_map

=head2 Generate Line Mappings as a Table

    $ map-tube --map London --line Bakerloo --line_mappings

=head2 Generate Line Notes

    $ map-tube --map London --line Bakerloo --line_notes

=head2 List the Lines for the Given Map

    $ map-tube --map London --list_lines

=head2 List the Stations for the Given Map

    $ map-tube --map London --list_stations

=head2 List all Supported Maps

This will show you a list of all officially supported maps. It will also show you
which of these maps are not currently installed on your machine.

    $ map-tube --list_maps

=head2 Using a Map that is Not Officially Supported

It is also possible to use tube maps that are not officially supported, e.g.,
privately created maps: (This is also helpful while developing a new map.)

    $ map-tube --map 'Slippery Rock' --start 'College Park' --end 'Greyhound station' --force

=head2 General Error

If encountering an invalid map or a missing map (i.e not installed), you get an error
message like below:

    $ map-tube --map xYz --start 'Baker Street' --end 'Euston Square'
    ERROR: Unsupported Map [xYz].

This will produce a similar message if you do not have the tube map of Kazan installed;
if you do have it, it will notify you that the starting station does not exist in this map:

    $ map-tube --map Kazan --start 'Baker Street' --end 'Euston Square'
    ERROR: Missing Map [Kazan].

=head1 SUPPORTED MAPS

The command line parameter C<map> can take one of the following map names. It is
case insensitive, i.e. 'London' and 'lOndOn' are the same.
Use the C<--list_maps> option describe above to get an up-to-date version of this list.
Use the C<--force> option described above to use locally installed maps that are not on
that list.

You could use L<Task::Map::Tube::Bundle> to install the supported maps. Please make
sure you have the latest maps when you install.

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

=item * L<London|Map::Tube::Leipzig>

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

    my $plugins = [ plugins ];
    my $map = $self->{map};
    if ($map) {
        foreach my $plugin (@$plugins) {
            my $key = _map_key($plugin);
            if (defined $key && (uc($map) eq $key)) {
                $self->{maps}->{uc($key)} = $plugin->new;
            }
        }
    }

    if ($self->force) {
        if ($map =~ /^[A-Za-z]+$/) {
            $self->{maps}->{uc($map)} = "Map::Tube::$map"->new;
        }
        else {
            my @caller = caller(0);
            @caller = caller(2) if $caller[3] eq '(eval)';

            Map::Tube::Exception::FoundUnsupportedMap->throw({
                method      => __PACKAGE__."::BUILD",
                message     => "ERROR: Can't force invalid map [$map].",
                filename    => $caller[1],
                line_number => $caller[2] });
        }
    }

    $self->_validate_param;
}

=head1 METHODS

=head2 run()

This is the only method provided by the package L<Map::Tube::CLI>. It does not
expect any parameter. Here is the code from the supplied C<map-tube> script.

    use strict; use warnings;
    use Map::Tube::CLI;

    Map::Tube::CLI->new_with_options->run;

=cut

sub run {
    my ($self) = @_;

    my $map_obj = $self->map ? $self->{maps}->{uc($self->map)} : undef;

    # Handle these two options first because map name may not be present:
    if ($self->version) {
        print _prepare_version_info($map_obj, $self->map), "\n";
        return;
    }
    elsif ($self->list_maps) {
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

    if ($self->generate_map) {
        $map_obj->bgcolor($self->bgcolor) if defined $self->bgcolor;
        my $image_file = _clean_path( ( $self->line // $self->map ) . '.png' );
        my $image_data = $map_obj->as_image($self->line);

        open(my $IMAGE, '>', $image_file);
        binmode($IMAGE);
        print $IMAGE decode_base64($image_data);
        close($IMAGE);
    }
    elsif ($self->line_mappings) {
        printf("\n=head1 DESCRIPTION\n\n%s Metro Map: %s Line.\n\n", $self->map, $self->line);
        print _prepare_line_mappings($map_obj, $self->line);
    }
    elsif ($self->line_notes) {
        print _prepare_line_notes($map_obj, $self->map, $self->line);
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
            printf("Metro Map %s: Route from %s to %s.\n\n", $self->map, $self->start, $self->end);
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
    my ($map, $map_name, $line_name) = @_;

    my $line_map_notes = {};
    foreach my $station (map { $_->name } @{ $map->get_stations($line_name) }) {
        _add_notes($map, $line_name, $line_map_notes, $station);
    }

    my $all_lines = $map->get_lines;
    my $line_package = {};
    foreach my $line (@$all_lines) {
        my $_line_name = $line->name;
        next if (uc($line_name) eq uc($_line_name));
        next unless (scalar(@{$line->get_stations}));
        $line_package->{$_line_name} = 1;
    }

    my $notes = "\n";
    $notes   .= "=head1 NOTE\n\n";
    $notes   .= "=over 2\n";

    my @stations = keys %$line_map_notes;
    if ( eval { require Unicode::Collate; 1 } ) {
        my $collator = Unicode::Collate->new(level => 1);
        @stations = $collator->sort(@stations);
    } else {
        @stations = sort { lc($a) cmp lc($b) } @stations;
    }

    foreach my $station (@stations) {
        my $delim = ' ';
        my $lines   = $line_map_notes->{$station};
        my $_notes .= sprintf("\n=item * The station \"%s\" is also part of\n", $station);
        foreach my $line (@$lines) {
            next unless (exists $line_package->{$line});
            $_notes .= sprintf("        %s L<%s Line|Map::Tube::%s::Line::%s>\n",
                               $delim, $line, $map_name, _guess_package_name($line));
            $delim = '|';
        }
        $notes .= $_notes if $delim;
    }

    $notes .= "\n=back\n";

    return $notes;
}

sub _prepare_version_info {
   my ($map, $map_name) = @_;
    my $msg = "Map::Tube::CLI version $VERSION, Map::Tube version: $Map::Tube::VERSION";
    if ($map_name) {
        my $supported_maps  = _supported_maps();
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
    my $supported_maps  = _supported_maps();
    my %plugins = map { $_ => 1 } plugins;
    my @map_list;
    for my $map ( sort values %$supported_maps ) {
        my $map_name = '(not installed)';
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

sub _add_notes {
    my ($map_object, $line_name, $notes, $station_name) = @_;

    my $station_lines = $map_object->get_node_by_name($station_name)->line;
    my $lines = [];
    foreach my $line (@$station_lines) {
        my $_line_name = $line->name;
        next if ($_line_name eq $line_name);
        push @$lines, $_line_name;
    }
    return unless (scalar(@$lines));

    $notes->{$station_name} = $lines;
}

sub _map_key {
    my ($name) = @_;
    return unless defined $name;

    my $maps = _supported_maps();
    foreach my $map (keys %$maps) {
        return $map if ($maps->{$map} eq $name);
    }

    return;
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

    my $supported_maps = _supported_maps();
    if ($self->force) {
        $supported_maps->{uc($map)} //= 'Map::Tube::'. $map;
    }

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

        # warn "--line option will be ignored" if defined $line;     # *** Should we warn if the --line option has been used for no good? ***

        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [start].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $start;

        Map::Tube::Exception::MissingStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Missing Station Name [end].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $end;

        Map::Tube::Exception::InvalidStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Invalid Station Name [$start].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $self->{maps}->{uc($map)}->get_node_by_name($start);

        Map::Tube::Exception::InvalidStationName->throw({
            method      => __PACKAGE__."::_validate_param",
            message     => "ERROR: Invalid Station Name [$end].",
            filename    => $caller[1],
            line_number => $caller[2] })
            unless defined $self->{maps}->{uc($map)}->get_node_by_name($end);
    }

}

sub _clean_path {
    my ($tainted_path) = @_;

    # Force string value (in case of malicious use of dualvars):
    $tainted_path = "$tainted_path";

    # Basic file name cleaning; printable characters only
    $tainted_path =~ /^([[:print:]]+)$/
        or croak "Non-printable characters detected in file name";
    my $clean_path = $1;

    # Exclude redirection characters ( < | > ) from path
    $clean_path =~ s/[<>\|]//g;

    # Reduce to basename (no paths allowed):
    # This ensures the user cannot use "../../" to escape the current directory
    $clean_path = path($clean_path)->basename;

    # Confirm it's a regular file, if it already exists:
    # We check here so the error message contains the simple name, not the absolute path.
    if (-e $clean_path && !-f $clean_path) {
        croak "File exists but is not a regular file: $clean_path";
    }

    # Canonicalize path (Now safe to make absolute for internal use):
    $clean_path = path($clean_path)->realpath;

    # Return cleaned path
    return $clean_path;
}

sub _supported_maps {

    return {
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
    };
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Map-Tube-CLI>

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
