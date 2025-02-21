#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use File::Spec;
use Test::Lib;
use Test::More tests => 3;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'unusual-station-name.xml' );
my $tube = Sample->new( xml => $dataname );

eval { $tube->as_image; };
is $@, '';

my $dot = graph_map_image( $tube, 'dot' );
use Data::Dump qw(dump);
like( $dot, qr(Nice station name),     'Output to GraphViz' );
like( $dot, qr(S:trange station name), 'Output to GraphViz' );

sub graph_map_image {
    my ($tube, $fmt, $global_attrs ) = @_;
    my $g = $tube->as_graph;
    my $l2c = $g->get_graph_attribute('line2colour');
    for my $v ($g->vertices) {
      my %lines;
      @lines{map $g->get_multiedge_ids(@$_), $g->edges_at($v)} = ();
      next if keys %lines != 1;
      my $l = (keys %lines)[0];
      next unless defined (my $color = $l2c->{$l});
      my $attrs = $g->get_vertex_attributes($v);
      $attrs->{graphviz}{color} = $color;
      $attrs->{graphviz}{fontcolor} = $color;
      $g->set_vertex_attribute($v, graphviz=>$attrs->{graphviz});
    }
    my %seen;
    $g->filter_edges(sub { !$seen{$_[1]}{$_[2]}++ });
    GraphViz2->from_graph($g)->run(format => $fmt)->dot_output;
}
