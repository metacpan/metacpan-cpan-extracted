# -*- perl -*-

#
# Author: Gisbert W. Selke, TapirSoft Selke & Selke GbR.
#
# Copyright (C) 2015 Gisbert W. Selke. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: gws@cpan.org
#


package Map::Tube::Beijing;
use strict;
use warnings;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

Map::Tube::Beijing - Interface to the Beijing tube map

=cut

use File::Share ':all';
use XML::Simple;
use Moo;
use namespace::clean;

has xml      => ( is  => 'ro', lazy => 1, default => sub { return dist_file('Map-Tube-Beijing', 'beijing-map.xml') } );
has nametype => ( is  => 'ro', default => '',
                  isa => sub { die "Illegal nametype '$_[0]'" unless $_[0] =~ /^(alt)?$/ },
                );

with 'Map::Tube';

around BUILDARGS => sub {
  my($orig, $class, @args) = @_;
  my %args;
  if ( ( @args == 1 ) && ( ref($args[0]) == 'HASH' ) ) {
    %args = %{ $args[0] };
  } else {
    %args = @args;
  }

  if ( exists($args{nametype}) && ( $args{nametype} ne '' ) ) {
    $args{xml} = XMLout( _xmlmod(
                                  XMLin( dist_file('Map-Tube-Beijing', 'beijing-map.xml'),
                                         KeyAttr => [ ], KeepRoot => 1,
                                       ),
                                  '_' . $args{nametype},
                                ),
                         XMLDecl => 1, KeepRoot => 1,
                       );
  }

  return $class->$orig(%args);

};


sub _xmlmod {
  my ( $branch, $suffix ) = @_;
  for my $key( keys %{ $branch } ) {
    if ( ref( $branch->{$key} ) eq 'HASH' ) {
      $branch->{$key} = _xmlmod( $branch->{$key}, $suffix );
    } elsif ( ( ref( $branch->{$key} ) eq '' ) && ( $key eq ( 'name' . $suffix ) ) ) {
      $branch->{'name'} = $branch->{ 'name' . $suffix };
    } elsif ( ( ref( $branch->{$key} ) eq '' ) && ( $key eq ( 'line' . $suffix ) ) ) {
      $branch->{'line'} = $branch->{ 'line' . $suffix };
    } elsif ( ref( $branch->{$key} ) eq 'ARRAY' ) {
      $branch->{$key} = [ map { _xmlmod( $_, $suffix ) } @{ $branch->{$key} } ];
    }
  }
  return $branch;
}

=head1 SYNOPSIS

    use Map::Tube::Beijing;
    my $tube = Map::Tube::Beijing->new();

    my $route = $tube->get_shortest_route('Yonghegong', 'Chongwenmen');

    print "Route: $route\n";

=head1 DESCRIPTION

This module allows to find the shortest route between any two given tube
stations in Beijing. All interesting methods are provided by the role
L<Map::Tube>.

=head1 METHODS

=head2 CONSTRUCTOR

    use Map::Tube::Beijing;
    my $tube_chin = Map::Tube::Beijing->new();
    my $tube_pinyin = Map::Tube::Beijing->new( nametype => 'alt' );

This will read the tube information from the shared file F<beijing-map.xml>,
which is part of the distribution. Without argument, full Chinese characters
(simplified) will be used. With the value C<'alt>' for C<nametype>, pinyin
transliteration into Western characters will be used. Other values will throw
an error.

=head1 ERRORS

If something goes wrong, maybe because the map information file was corrupted,
the constructor will die.

=head1 AUTHOR

Gisbert W. Selke, TapirSoft Selke & Selke GbR.

=head1 COPYRIGHT AND LICENCE

The data for the XML file were mainly taken from the appropriate Wikipedia
pages. They are CC BY-SA 2.0.
The module itself is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Map::Tube>, L<Map::Tube::GraphViz>.

=cut

1;
