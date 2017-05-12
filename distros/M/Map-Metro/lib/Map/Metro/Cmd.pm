use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd;

# ABSTRACT: The command line interface
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use MooseX::App qw/Config Color/;
use MooseX::AttributeShortcuts;

use Map::Metro;
use Map::Metro::Shim;

app_description 'Command line interface to Map::Metro';

app_usage qq{map_metro.pl <command> [ <city> ]  [ <arguments> ]};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd - The command line interface

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SYNOPSIS

    #* General form
    $ map-metro.pl <command> [ <city> ] [ <arguments> ]

    #* Prints the route using the PrettyPrinter hook plugin
    $ map-metro.pl route Stockholm 'Sundbybergs centrum' T-Centralen

=head1 DESCRIPTION

This collection of commands exposes several parts of the L<Map::Metro> api.

=head1 COMMANDS

If a command takes C<$city>, it is mandatory. Normally it should be a module name in the C<Map::Metro::Plugin::Map> namespace (but only the significant part is necessary). If, however, it contains
att least one dot it is assumed to be a file path to a map file. The map file is parsed via L<Map::Metro::Shim>.

=head2 map-metro.pl all_routes $city

Does B<route> for all stations in the C<Map::Metro::Plugin::Map::$city> map. This gets exponentially slower with bigger maps.

=head2 map-metro.pl available

Lists all installed maps on the system.

=head2 map-metro.pl graphviz $city --into=$file

Creates a png via L<GraphViz2>.

If I<into=$file> is given the png is saved with that filename, otherwise a timestamped file will be saved in the current directory.

=head2 map-metro.pl lines $city

Lists all lines in the C<Map::Metro::Plugin::Map::$city> map.

=head2 map-metro.pl metro_to_tube $city

Converts C<Map::Metro::Plugin::Map::$city> into a L<Map::Tube> ready xml-file. The file is saved in the current working directory with a timestamped filename.

=head2 map-metro.pl route $city $from $to

B<C<$from>>

Mandatory. The starting station, can be either a station id (integer), or a station name (string). Must be of the same type as B<C<$to>>. Use quotes if the name contains spaces.

B<C<$to>>

Mandatory. The finishing station, can be either a station id (integer), or a station name (string). Must be of the same type as B<C<$from>>. Use quotes if the name contains spaces.

Searches for routes in the C<Map::Metro::Plugin::Map::$city> between C<$from> and C<$to>.

=head2 map-metro.pl stations $city

Lists all stations in the  C<Map::Metro::Plugin::Map::$city> map. This displays station ids for easy search with B<route>.

=head2 map-metro.pl help

It's there if you need it...

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
