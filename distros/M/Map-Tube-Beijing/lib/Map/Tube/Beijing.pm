# -*- perl -*-

#
# Author: Gisbert W. Selke, TapirSoft Selke & Selke GbR.
#
# Copyright (C) 2015, 2025 Gisbert W. Selke. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: gws@cpan.org
#

package Map::Tube::Beijing;
use 5.12.0;
use version 0.77 ( );
use strict;
use warnings;

our $VERSION = version->declare('v0.12.5');

=encoding utf8

=head1 NAME

Map::Tube::Beijing - Interface to the Beijing tube map

=cut

use File::Share ':all';
use Moo;
use namespace::clean;

my %nametypes = map { $_ => 1 } qw(alt); # The permissible alternative nametypes. In our case, just 'alt'

has xml      => ( is  => 'ro', lazy => 1, default => sub { return dist_file('Map-Tube-Beijing', 'beijing-map.xml') } );
has nametype => ( is  => 'ro', default => '',
				  isa => sub { die __PACKAGE__ . ": ERROR: Invalid nametype for constructor: '$_[0]'" unless ( ( $_[0] eq '') || exists($nametypes{ $_[0] } ) ) },
                );

with 'Map::Tube';

before _validate_map_structure => sub {
  $_[1] = _relocate_alternatives( $_[1], '_' . $_[0]->{nametype} ) if ( exists( $_[0]->{nametype}) && ( $_[0]->{nametype} ne '' ) );
  $_[1] = _remove_alternatives( $_[1] );
};

sub _relocate_alternatives {
  my( $branch, $suffix ) = @_;
  for my $key( keys %{ $branch } ) {
    if ( ref( $branch->{$key} ) eq 'HASH' ) {
	  $branch->{$key} = _relocate_alternatives( $branch->{$key}, $suffix );
    } elsif ( ( ref( $branch->{$key} ) eq '' ) && ( $key eq ( 'name' . $suffix ) ) ) {
      $branch->{'name'} = $branch->{ 'name' . $suffix };
    } elsif ( ref( $branch->{$key} ) eq 'ARRAY' ) {
	  $branch->{$key} = [ map { _relocate_alternatives( $_, $suffix ) } @{ $branch->{$key} } ];
    }
  }
  return $branch;
}

sub _remove_alternatives {
  my($branch) = @_;
  for my $key( keys %{ $branch } ) {
    if ( ref( $branch->{$key} ) eq 'HASH' ) {
	  $branch->{$key} = _remove_alternatives( $branch->{$key} );
	} elsif ( ( ref( $branch->{$key} ) eq '' ) && ( $key eq 'name' ) ) {
	  for my $suffix ( keys(%nametypes) ) {
		delete $branch->{ $key . '_' . $suffix };
	  }
    } elsif ( ref( $branch->{$key} ) eq 'ARRAY' ) {
	  $branch->{$key} = [ map { _remove_alternatives($_) } @{ $branch->{$key} } ];
	}
  }
  return $branch;
}

=head1 SYNOPSIS

    use Map::Tube::Beijing;
	my $tube = Map::Tube::Beijing->new( nametype => 'alt' );

	my $route = $tube->get_shortest_route('Yonghegong Lama Temple', 'Chongwenmen')->preferred( );

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube
stations in Beijing. All interesting methods are provided by the role
L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

    use Map::Tube::Beijing;
	my $tube_chin = Map::Tube::Beijing->new( );
    my $tube_pinyin = Map::Tube::Beijing->new( nametype => 'alt' );

This will read the tube information from the shared file F<beijing-map.xml>,
which is part of the distribution. Without argument, full Chinese characters
(simplified) will be used. With the value C<'alt>' for C<nametype>, pinyin
transliteration into Western characters will be used. Other values will throw
an error.

=head2 nametype( )

This yields the nametype that was specified with the constructor call, or '' if none.


=head2 xml( )

This read-only accessor returns whatever was specified as the XML source at
construction.


=head1 MAP DATA FORMAT

The data format for Map::Tube instances is described in the documentation for L<Map::Tube>.
The Beijing map, however, comes either with station and line names in the original Chinese
writing or in pinyin, i.e., in Latin alphabet letters that are a rough representation of
the pronunciation. To this end, all tags that have a C<name> attribute containing the name
in Chinese script also have a C<name_alt> attribute with the pinyin writing. When reading the
map data and no C<nametype> is given, all the C<name_alt> attributes are deleted, so that
the L<Map::Tube> software sees only a standard data structure. However, if C<nametype=alt>
was specified when instantiating L<Map::Data::Beijing>, the C<name_alt> attributes will be
copied into the C<name> atributes, and, again, the C<name_alt> attributes themselves are
removed.

This mechanism may also be employed also for other countries/regions where more than one language
and/or writing system is used. E.g., for Swiss subway systems it is conceivable to have up to four
different languages. C<name> might be used for the French name, C<name_d> for the German name,
C<name_i> for Italian, and C<name_r> for Romansh.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR.

=head1 COPYRIGHT AND LICENCE

The data for the XML file were mainly taken from the appropriate English-language Wikipedia
pages. They are CC BY-SA 2.0.
The module itself is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>.

=cut

1;
