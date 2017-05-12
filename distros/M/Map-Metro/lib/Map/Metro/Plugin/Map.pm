use 5.10.0;
use strict;
use warnings;

package Map::Metro::Plugin::Map;

# ABSTRACT: How to make your own map
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use File::ShareDir 'dist_dir';
use Path::Tiny;
use Types::Standard qw/Bool ArrayRef Str/;
use Types::Path::Tiny qw/Path/;

has mapfile => (
    is => 'ro',
    isa => Path,
    predicate => 1,
    coerce => 1,
);
has do_undiacritic => (
    is => 'rw',
    isa => Bool,
    default => 1,
);
has hooks => (
    is => 'ro',
    isa => ArrayRef[ Str ],
    traits => ['Array'],
    default => sub { [] },
    handles => {
        all_hooks => 'elements',
    },
);

sub mapdir {
    my $self = shift;
    return $self->mapfile->parent if $self->mapfile->is_absolute; # work with old api
    my $package = $self->map_package;
    $package =~ s{::}{-}g;
    return path(dist_dir($package));
}
sub maplocation {
    my $self = shift;
    return $self->mapfile if $self->mapfile->is_absolute; # work with old api
    return $self->mapdir->child($self->mapfile);
}

sub version {
    my $self = shift;
    return 0 if $self->mapfile->is_absolute; # work with old api when we had no map_version()
    return $self->map_version;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Map::Metro::Plugin::Map - How to make your own map

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SYNOPSIS

    # This is a modified part of the map from Map::Metro::Plugin::Map::Stockholm

    --stations
    Stadshagen
    Fridhemsplan
    Rådhuset
    T-Centralen

    # comments are possible
    Gamla stan
    Slussen
    Medborgarplatsen
    Skanstull
    Gullmarsplan
    Globen
    Sergels torg
    Nybroplan

    --transfers
    T-Centralen|Sergels torg|weight:4

    --lines
    10|T10|Blue line
    11|T11|Blue line
    19|T19|Green line|color:#79c142
    7|L7|Spårväg city

    --segments
    10->,11<-|Stadshagen|Fridhemsplan % Västermalmsgallerian
    10,11|Fridhemsplan|Rådhuset % :Radhuset
    10,11|Rådhuset|T-Centralen
    10,11|T-Centralen|Kungsträdgården
    19|T-Centralen|Gamla stan
    19|Gamla stan|Slussen
    19|Slussen|Medborgarplatsen
    19|Medborgarplatsen|Skanstull
    19|Skanstull|Gullmarsplan
    19|Gullmarsplan|Globen
    7|Sergels torg|Nybroplan

=head1 DESCRIPTION

It is straightforward to create a map file. It consists of four parts:

=head2 --stations

This is a list of all stations in the network. Currently only one value per line. Don't use C<|> in station names.

=head2 --transfers

This is a list of L<Transfers|Map::Metro::Graph::Transfer>. If two stations share at least one line they are B<not> transfers. Three groups of data per line (delimited by C<|>):

=over 4

=item The first station.

=item The following station.

=item Optional options.

=back

The options in turn is a comma separated list of colon separated key-value pairs. Currently the only supported option is:

=over 4

=item weight. Integer. Set a custom weight for the 'cost' of making this transfer. Default value is 5. (Travelling between two
      stations on the same line cost 1, and changing lines at a station costs 3).

=back

=head2 --lines

This is a list of all lines in the network. Three values per line (delimited by C<|>):

* Line id (only a-z, A-Z and 0-9 allowed). Used in segments.

* Line name. This should preferably be short(ish) and a common name for the line.

* Line description. This can be a longer common name for the line.

* Optional options, a comma separated list of colon separated key-value pairs:

=over 4

* color. Hexadecimal, preceeded by '#'. Can be used by visualization tools to give lines their regular colours.

* width. Integer. Can be used by visualization tools to give lines different widths, for example differentiate different types of transport.

=back

=head2 --segments

This is a list of all L<Segments|Map::Metro::Graph::Segment> in the network. (A segment is a pair of consecutive stations.) Three groups of data per line (delimited by C<|>):

* A list of line ids (comma delimited). This references the line list above. The list of line ids represents all lines travelling between the two stations.

* The first station.

* The following station

In the synopsis, segments part starts like this:

    10->,11<-|Stadshagen|Fridhemsplan % Västermalmsgallerian
    10,11|Fridhemsplan|Rådhuset % :Radhuset

First, the arrow notation describes the direction of travel (the default is both ways, all three can be combined in one segment definition).

C<-E<gt>> means that the line only travels I<from> Stadshagen I<to> Fridhemsplan.

C<E<lt>-> means that the line only travels I<from> Fridhemsplan I<to> Stadshagen.

Second, the C<%> notation makes it possible to attach more names to the station.

If the name begins with a C<:> it is considered a I<search name>. This mean that it is possible to search, but it is generally not displayed (eg. by the L<PrettyPrinter|Map::Metro::Plugin::Hook::PrettyPrinter> hook).

If the name doesn't begin with a C<:> it is considered an I<alternative name>. The L<PrettyPrinter|Map::Metro::Plugin::Hook::PrettyPrinter> hook displays them as "first given name/alternative name".

=head3 When to use what?

B<Alternative names> are used when the I<same station> is known as both names. This is not very common.

B<Search names> is mostly useful when a station has changed names (keep the old name as a search name)

Overriding station names through a hook (as L<Map::Metro::Plugin::Hook::Helsinki::Swedish> does) can be a good way to present translations or transliterations of station names.

Just make sure that no names collide.

=head1 WHAT NOW?

Start a distribution called C<Map::Metro::Plugin::Map::$city>.

=head2 With Dist::Zilla

The easiest way to do that is to use L<Dist::Zilla> with L<Dist::Zilla::MintingProfile::MapMetro::Map>. See also L<Task::MapMetro::Dev>.

    $ dzil new -P MapMetro::Map  Map::Metro::Plugin::Map::TheCity

=head2 Without Dist::Zilla

Save the map file as C<map-$city.metro> in the C<share> directory.

Say we make a map for London; then C<Map::Metro::Plugin::Map::London> would look like this:

    use strict;

    package Map::Metro::Plugin::Map::London;

    our $VERSION = 0.01;

    use Moose;
    with 'Map::Metro::Plugin::Map';

    has '+mapfile' => (
        default => 'map-london.metro',
    );
    sub map_version {
        return $VERSION;
    }
    sub map_package {
        return __PACKAGE__;
    }

    1;

=head2 Diacritics?

By default, station names with diacritics get their un-diacritic form added as a search name. If this causes problems with a map file, add this to the module definition and it is turned off:

    has '+do_undiacritic' => (
        default => 0,
    );

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
