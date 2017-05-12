package GraphViz::Data::Grapher;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;
use lib '../..';
use lib '..';
use GraphViz;

our $VERSION = '2.24';

=head1 NAME

GraphViz::Data::Grapher - Visualise data structures as a graph

=head1 SYNOPSIS

  use GraphViz::Data::Grapher;

  my $graph = GraphViz::Data::Grapher->new($structure);
  print $graph->as_png;

=head1 DESCRIPTION

This module makes it easy to visualise Perl data structures. Data
structures can grow quite large and it can be hard to understand the
quite how the structure fits together.

Data::Dumper can help by representing the structure as a text
hierarchy, but GraphViz::Data::Grapher goes a step further and
visualises the structure by drawing a graph which represents the data
structure.

Arrays are represented by records. Scalars are represented by
themselves. Array references are represented by a '@' symbol, which is
linked to the array. Hash references are represented by a '%' symbol,
which is linked to an array of keys, which each link to their value.
Object references are represented by 'Object', which then links to the
type of the object. Undef is represented by 'undef'.

=head1 METHODS

=head2 new

This is the constructor. It takes a list, which is the data structure
to be visualised. A GraphViz object is returned.

  my $graph = GraphViz::Data::Grapher->new([3, 4, 5], "Hello");

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @items = @_;

    my $graph = GraphViz->new( sort => 1 );

    _init( $graph, @items );

    return $graph;
}

=head2 as_*

The data structure can be visualised in a number of different
graphical formats. Methods include as_ps, as_hpgl, as_pcl, as_mif,
as_pic, as_gd, as_gd2, as_gif, as_jpeg, as_png, as_wbmp, as_ismap,
as_imap, as_vrml, as_vtx, as_mp, as_fig, as_svg. See the GraphViz
documentation for more information. The two most common methods are:

  # Print out a PNG-format file
  print $graph->as_png;

  # Print out a PostScript-format file
  print $graph->as_ps;

=cut

sub _init {
    my ( $graph, @items ) = @_;

    my @parts;

    foreach my $item (@items) {
        push @parts, _label($item);
    }

    my $colour = 'black';
    $colour = 'blue' if @parts == 1;

    my $source = $graph->add_node( { label => \@parts, color => $colour } );

    foreach my $port ( 0 .. @items - 1 ) {
        my $item = $items[$port];

        #warn "$port = $item\n";

        next unless ref $item;
        my $ref = ref $item;
        if ( $ref eq 'SCALAR' ) {
            my $target = _init( $graph, $$item );
            $graph->add_edge(
                { from => $source, from_port => $port, to => $target } );
        } elsif ( $ref eq 'ARRAY' ) {
            my $target = _init( $graph, @$item );
            $graph->add_edge(
                { from => $source, from_port => $port, to => $target } );
        } elsif ( $ref eq 'HASH' ) {
            my @hash;
            foreach my $key ( sort keys(%$item) ) {
                push @hash, $key;
            }
            my $hash
                = $graph->add_node( { label => \@hash, color => 'brown' } );
            foreach my $port ( 0 .. @hash - 1 ) {
                my $key = $hash[$port];
                my $target = _init( $graph, $item->{$key} );
                $graph->add_edge(
                    { from => $hash, from_port => $port, to => $target } );
            }
            $graph->add_edge(
                { from => $source, from_port => $port, to => $hash } );
        } else {
            my $target = $ref;
            $ref =~ s/=.+$//;
            $graph->add_node(
                { name => $target, label => $ref, color => 'red' } );
            $graph->add_edge(
                { from => $source, from_port => $port, to => $target } );
        }
    }

    return $source;
}

sub _label {
    my $scalar = shift;

    my $ref = ref $scalar;

    if ( not defined $scalar ) {
        return 'undef';
    } elsif ( $ref eq 'ARRAY' ) {
        return '@';
    } elsif ( $ref eq 'SCALAR' ) {
        return '$';
    } elsif ( $ref eq 'HASH' ) {
        return '%';
    } elsif ($ref) {
        return 'Object';
    } else {
        return $scalar;
    }
}

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000-1, Leon Brocard

This module is free software; you can redistribute it or modify it under the Perl License,
a copy of which is available at L<http://dev.perl.org/licenses/>.

=cut

1;
