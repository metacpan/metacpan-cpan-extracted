use strict;
use warnings;
use Test::More;
use Graph::Directed;
use List::UtilsBy qw/sort_by/;
use Graph::Feather;
use JSON;

my @meta = map {
  [ split/\s+/, s/^\s+|\s+$//gr ]
} grep {
  /\S/
} split/\n/, q{
  _  add_vertex                  g v
  _  add_edge                    g v v 
  b  has_vertex                  g v
  b  has_edge                    g v v
  _  delete_vertex               g v
  _  delete_vertices             g vs
  _  delete_edge                 g v v
  _  delete_edges                g vs
  _  add_vertices                g vs
  _  add_edges                   g es
  vs vertices                    g
  es edges                       g

  vs successors                  g v
  vs successorless_vertices      g
  vs predecessors                g v 
  vs predecessorless_vertices    g

  vs all_successors              g v
  vs all_predecessors            g v

  es edges_at                    g v
  es edges_to                    g v
  es edges_from                  g v

  _  set_vertex_attribute        g v n .
  .  get_vertex_attribute        g v n
  b  has_vertex_attribute        g v n
  _  delete_vertex_attribute     g v n
  ss get_vertex_attribute_names  g v
  _  delete_vertex_attributes    g v

  _  set_edge_attribute          g v v n .
  .  get_edge_attribute          g v v n 
  b  has_edge_attribute          g v v n
  _  delete_edge_attribute       g v v n
  ss get_edge_attribute_names    g v v 
  _  delete_edge_attributes      g v v

  _  set_graph_attribute         g n .
  .  get_graph_attribute         g n
  b  has_graph_attribute         g n
  _  delete_graph_attribute      g n
  ss get_graph_attribute_names   g 
  _  delete_graph_attributes     g 

  hr get_vertex_attributes       g v
  hr get_edge_attributes         g v v
  hr get_graph_attributes        g 

  _  set_vertex_attributes       g v hr
  _  set_edge_attributes         g v v hr
  _  set_graph_attributes        g hr
};

my $max_vertices = 16;

sub r_arg {
  return $_[ int rand scalar @_ ];
}

sub r_vertex {
  return r_arg(1 .. $max_vertices - 1);
}

sub r_name {
  return r_arg qw/colour weight label age/;
}

sub r_value {
  return r_arg(qw/pale 314159 _____ LART/, undef);
}

sub r_method {
  return r_arg @meta;
}

sub r_edges {
  map { [ r_vertex(), r_vertex() ] } 0 .. int rand 10;
}

sub r_vertices { 
  map { r_vertex() } 0 .. int rand 10;
}

sub r_hr {
  return {
    map { r_name(), r_value() } 1 .. int rand 4
  };
}

for my $i ( 0 .. 1000 ) {
  my $d = Graph::Directed->random_graph(
    vertices => int(rand($max_vertices)),
  );

  # https://github.com/neilb/Graph/issues/5
  $d->delete_vertex(0);

  my $f = Graph::Feather->new(
    vertices => [ $d->vertices ],
    edges => [ $d->edges ],
  );

  for my $j ( 0 .. int(rand( scalar @meta ) ) ) {
    my ($return_type, $method_name, undef, @arg_types) =
      @{ r_method() };

    my %arg_map = (
      'v'  => \&r_vertex,
      'vs' => \&r_vertices,
      'es' => \&r_edges,
      'n'  => \&r_name,
      '.'  => \&r_value,
      'hr' => \&r_hr,
    );

    my @args = map { $arg_map{$_}->() } @arg_types;

    # needs even number of vertices
    next if $method_name eq 'delete_edges' and @args & 1;

    my @return_d;
    my @return_f;

    for my $pair ([$d, \@return_d], [$f, \@return_f]) {
      
      my ($g, $return) = @$pair;

      if ($return_type =~ /^(vs|ss)$/) {
        @$return = sort_by { $_ } $g->$method_name(@args);

      } elsif ($return_type =~ /^(es)$/) {
        @$return = sort_by { join ",", @$_ } $g->$method_name(@args);

      } elsif ($return_type =~ /^(b)$/) {
        @$return = !! scalar $g->$method_name(@args);

      } elsif ($return_type =~ /^(hr)$/) {
        my $hr = $g->$method_name(@args);
        my @keys = sort keys %$hr;
        my @vals = map { $hr->{$_} } @keys;
        @$return = (@keys, @vals);

      } else {
        @$return = scalar $g->$method_name(@args);
      }
    }

    my @mapped = map { $_ // '<undef>' } @args;

    @mapped = JSON->new->encode([@args ]);


    if ($return_type eq '_') {
      ok 1, "$method_name(@mapped)";
      next;
    }

    next if is_deeply \@return_f, \@return_d, "$method_name(@mapped)";
    next;

    require YAML::XS;
    warn YAML::XS::Dump {
      d => \@return_d,
      f => \@return_f,
      dd => { vertices => [ $d->vertices ], edges => [ $d->edges ] },
      fd => { vertices => [ $f->vertices ], edges => [ $f->edges ] },
    };

  }

}

done_testing();
