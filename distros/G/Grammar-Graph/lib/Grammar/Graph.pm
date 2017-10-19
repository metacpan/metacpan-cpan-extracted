#####################################################################
# Types
#####################################################################
package Grammar::Graph::Types;
use Modern::Perl;
use parent qw/Type::Library/;
use Type::Utils;
use Types::Standard qw/Int/;

declare 'Vertex',
  as Int,
  where { $_ > 0 };

#####################################################################
# Role for non-terminal names
#####################################################################
package Grammar::Graph::Named;
use Modern::Perl;
use Moose::Role;

has 'name' => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# Role for coupled vertices
#####################################################################
package Grammar::Graph::Coupled;
use Modern::Perl;
use Moose::Role;

has 'partner' => (
  is       => 'ro',
  required => 1,
  writer   => '_set_partner',
  isa      => Grammar::Graph::Types::Vertex(),
);

#####################################################################
# Start
#####################################################################
package Grammar::Graph::Start;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Empty';
with 'Grammar::Graph::Coupled',
     'Grammar::Graph::Named';
     
#####################################################################
# Final
#####################################################################
package Grammar::Graph::Final;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Empty';
with 'Grammar::Graph::Coupled',
     'Grammar::Graph::Named';

#####################################################################
# Conditionals
#####################################################################
package Grammar::Graph::Conditional;
use Modern::Perl;
use Moose;

extends qw/Grammar::Formal::Empty/;
with qw/Grammar::Graph::Coupled/;

has 'p1' => (
  is       => 'ro',
  required => 1,
  isa      => Grammar::Graph::Types::Vertex()
);

has 'p2' => (
  is       => 'ro',
  required => 1,
  isa      => Grammar::Graph::Types::Vertex()
);

has 'name' => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# If (start of conditional)
#####################################################################
package Grammar::Graph::If;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Conditional';

#####################################################################
# Fi (end of conditional)
#####################################################################
package Grammar::Graph::Fi;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Conditional';

#####################################################################
# Operands
#####################################################################
package Grammar::Graph::Operand;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Empty';
with qw/Grammar::Graph::Coupled/;

#####################################################################
# Prelude (character before any other)
#####################################################################
package Grammar::Graph::Prelude;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::CharClass';
with qw/Grammar::Graph::Coupled/;

has '+spans'  => (
  required => 0,
  default  => sub {
    Set::IntSpan->new([-1])
  },
);

#####################################################################
# Postlude (character after any other)
#####################################################################
package Grammar::Graph::Postlude;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::CharClass';
with qw/Grammar::Graph::Coupled/;

has '+spans'  => (
  required => 0,
  default  => sub {
    Set::IntSpan->new([-1])
  },
);

#####################################################################
# Grammar::Graph
#####################################################################
package Grammar::Graph;
use 5.012000;
use Modern::Perl;
use Grammar::Formal;
use List::UtilsBy qw/partition_by/;
use List::MoreUtils qw/uniq/;
use List::Util qw/shuffle sum max/;
use Storable qw/freeze thaw/;
use Graph::SomeUtils qw/:all/;
use Graph::Directed;
use Moose;

#####################################################################
# Globals
#####################################################################

local $Storable::canonical = 1;

our $VERSION = '0.20';

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

#####################################################################
# Attributes
#####################################################################

has 'g' => (
  is       => 'ro',
  required => 1,
  isa      => 'Graph::Directed',
  default  => sub { Graph::Directed->new },
);

has 'symbol_table' => (
  is       => 'ro',
  required => 1,
  isa      => 'HashRef',
  default  => sub { {} },
);

has 'start_vertex' => (
  is       => 'ro',
  required => 0, # FIXME?
  writer   => '_set_start_vertex',
  isa      => Grammar::Graph::Types::Vertex(),
);

has 'final_vertex' => (
  is       => 'ro',
  required => 0, # FIXME?
  writer   => '_set_final_vertex',
  isa      => Grammar::Graph::Types::Vertex(),
);

has 'pattern_converters' => (
  is       => 'ro',
  required => 1,
  isa      => 'HashRef[CodeRef]',
  default  => sub { {
    'Grammar::Formal::CharClass' => \&convert_char_class,
    'Grammar::Formal::ProseValue' => \&convert_prose_value,
    'Grammar::Formal::Reference' => \&convert_reference,
    'Grammar::Formal::NotAllowed' => \&convert_not_allowed,

    'Grammar::Formal::Range' => \&convert_range,
    'Grammar::Formal::AsciiInsensitiveString'
      => \&convert_ascii_insensitive_string,
    'Grammar::Formal::CaseSensitiveString'
      => \&convert_case_sensitive_string,

    'Grammar::Formal::Grammar' => \&convert_grammar,
    'Grammar::Formal' => \&convert_grammar_formal,
    'Grammar::Formal::Rule' => \&convert_rule,

    'Grammar::Formal::BoundedRepetition'
      => \&convert_bounded_repetition,

    'Grammar::Formal::SomeOrMore' => \&convert_some_or_more,
    'Grammar::Formal::OneOrMore' => \&convert_one_or_more,
    'Grammar::Formal::ZeroOrMore' => \&convert_zero_or_more,

    'Grammar::Formal::Empty' => \&convert_empty,

    'Grammar::Formal::Group' => \&convert_group,

    'Grammar::Formal::Choice' => \&convert_choice,
    'Grammar::Formal::Conjunction' => \&convert_conjunction,
    'Grammar::Formal::Subtraction' => \&convert_subtraction,

    'Grammar::Formal::OrderedChoice' => \&convert_ordered_choice,
    'Grammar::Formal::OrderedConjunction'
      => \&convert_ordered_conjunction,

  } },
);

sub reversed_copy {
  my ($self) = @_;

  my $g = Graph::Directed->new;

  $g->add_edge(reverse @$_) for $self->g->edges;

  my $copy = $self->new(%{ $self }, g => $g);

  for my $v ($self->g->vertices) {
    my $label = $self->get_vertex_label($v);
    next unless $label;
    if (0 && UNIVERSAL::can($label, 'partner')) {
      my $cloned = $label->new(%$label, partner => $v);
      $copy->set_vertex_label($label->partner, $cloned);
    } else {
      my $cloned = $label->new(%$label);
      $copy->set_vertex_label($v, $cloned);
    }
  }

  $copy->_set_start_vertex($self->final_vertex);
  $copy->_set_final_vertex($self->start_vertex);

  return $copy;
}

#####################################################################
# Helper functions
#####################################################################
sub _copy_predecessors {
  my ($self, $src, $dst) = @_;
  $self->g->add_edge($_, $dst)
    for $self->g->predecessors($src);
}

sub _copy_successors {
  my ($self, $src, $dst) = @_;
  $self->g->add_edge($dst, $_)
    for $self->g->successors($src);
}

sub _find_endpoints {
  my ($self, $id) = @_;

  my $symbols = $self->symbol_table;
  my $start = $symbols->{$id}{start_vertex};
  my $final = $symbols->{$id}{final_vertex};
  
  return ($start, $final);
}

#####################################################################
# ...
#####################################################################

sub register_converter {
  my ($self, $class, $code) = @_;
  $self->pattern_converters->{$class} = $code;
}

sub find_converter { 
  my ($self, $pkg) = @_;
  return $self->pattern_converters->{$pkg};
}

#####################################################################
# ...
#####################################################################

sub _fa_next_id {
  my ($self) = @_;
  
  my $next_id = $self->g->get_graph_attribute('fa_next_id');
  
  $next_id = do {
    my $max = max(grep { /^[0-9]+$/ } $self->g->vertices) // 0;
    $max + 1;
  } if not defined $next_id or $self->g->has_vertex($next_id);

  $self->g->set_graph_attribute('fa_next_id', $next_id + 1);

  return $next_id;
}

sub fa_add_state {
  my ($self, %o) = @_;
  
  my $expect = $o{p} // Grammar::Formal::Empty->new;
  
  my $id = $self->_fa_next_id();
  $self->g->add_vertex($id);
  $self->set_vertex_label($id, $expect)
    if defined $expect;

  return $id;
}

sub fa_all_e_reachable {
  my ($self, $v) = @_;
  my %seen;
  my @todo = ($v);
  while (@todo) {
    my $c = pop @todo;
    next if $self->is_terminal_vertex($c);
    push @todo, grep { not $seen{$_}++ } $self->g->successors($c);
  }
  keys %seen;
}

# from => $vertex, 
# want => sub { ... }, 
# next => sub { ... },

# self => 'always|never|if_reachable'
# vertex_if => sub { ... }
# successors_if => sub { ... }

sub all_reachable {
  my ($g, $source, $cond) = @_;
  $cond //= sub { 1 };
  my %seen;
  my @todo = ($source);
  my %ok;
  while (defined(my $v = pop @todo)) {
    $ok{$_}++ for $g->successors($v);
    push @todo, grep {
      $cond->($_) and not $seen{$_}++
    } $g->successors($v);
  }
  keys %ok;
};

#####################################################################
# Helper function to clone label when cloning subgraph
#####################################################################
sub _clone_label {
  my ($self, $label, $want, $map) = @_;

  return unless UNIVERSAL::can($label, 'meta');

  my %ref_vertex_map;

  for my $att ($label->meta->get_all_attributes) {

    my $tc = $att->type_constraint;

    next unless $tc;
    next unless $tc->equals(Grammar::Graph::Types::Vertex());

    warn "Trying to clone subgraph without cloning label vertices (" . $att->name . ")"
      unless $want->{ $att->get_value($label) };

    $map->{ $att->get_value($label) } //= $self->fa_add_state();

    $ref_vertex_map{ $att->name } =
      $map->{ $att->get_value($label) };
  }

  return $label->new(%$label, %ref_vertex_map)
}

#####################################################################
# Clone a subgraph between two vertices
#####################################################################
sub _clone_subgraph_between {
  my ($self, $src, $dst) = @_;

  my %want = map { $_ => 1 }
    graph_vertices_between($self->g, $src, $dst);

  my %map;
  
  for my $k (keys %want) {

    $map{$k} //= $self->fa_add_state();

    my $label = $self->get_vertex_label($k);
    my $cloned_label = _clone_label($self, $label, \%want, \%map);

    $self->set_vertex_label($map{$k}, 
      $cloned_label // $label);
  }

  while (my ($old, $new) = each %map) {
    for (grep { $want{$_} } $self->g->successors($old)) {
      $self->g->add_edge($new, $map{$_});
    }
  }
  
  return ($map{$src}, $map{$dst}, \%map);
}

sub _clone_non_terminal {
  my ($self, $id) = @_;
  return $self->_clone_subgraph_between(
    $self->symbol_table->{$id}{start_vertex},
    $self->symbol_table->{$id}{final_vertex},
  );
}

#####################################################################
# Generate a graph with all rules with edges over ::References
#####################################################################
sub _fa_ref_graph {
  my ($self) = @_;
  my $symbols = $self->symbol_table;
  my $ref_graph = Graph::Directed->new;

  for my $r1 (keys %$symbols) {
    my $v = $symbols->{$r1};
    for (graph_all_successors_and_self($self->g, $v->{start_vertex})) {
      next unless $self->vertex_isa($_, 'Grammar::Formal::Reference');
      my $label = $self->get_vertex_label($_);
      my $r2 = $label->expand;
      $ref_graph->add_edge("$r1", "$r2");
#      $ref_graph->add_edge("$r1", "$_");
#      $ref_graph->add_edge("$_", "$r2");
    }
  }

  return $ref_graph;
}

#####################################################################
# ...
#####################################################################
sub fa_expand_one_by_copying {
  my ($self, $id) = @_;

  my %id_to_refs = partition_by {
    $self->get_vertex_label($_)->expand . ''
  } grep {
    $self->vertex_isa($_, 'Grammar::Formal::Reference')
  } $self->g->vertices;

  for my $v (@{ $id_to_refs{$id} }) {
    my $label = $self->get_vertex_label($v);

    my ($src, $dst) = $self->_clone_non_terminal($id);

    $self->_copy_predecessors($v, $src);
    $self->_copy_successors($v, $dst);
    graph_delete_vertex_fast($self->g, $v);
  }
}

sub fa_expand_references {
  my ($self) = @_;
  my $symbols = $self->symbol_table;

  my $ref_graph = $self->_fa_ref_graph;
  my $scg = $ref_graph->strongly_connected_graph;

  my @topo = grep { not $ref_graph->has_edge($_, $_) }
    reverse $scg->toposort;

  for my $id (@topo) {
    # NOTE: Relies on @topo containing invalid a+b+c+... IDs
    $self->fa_expand_one_by_copying($id);
  }

  for my $v ($self->g->vertices) {
    my $label = $self->get_vertex_label($v);

    next unless $self->vertex_isa($v, 'Grammar::Formal::Reference');

    my $id = $label->expand;

    # TODO: explain
    # TODO: remove
#    next if $scg->has_vertex("$id")
#      && !$ref_graph->has_edge("$id", "$id");

    my $v1 = $self->fa_add_state();
    my $v2 = $self->fa_add_state();

    my $name = $label->expand->name;

    my $p1 = Grammar::Graph::Start->new(
      partner => $v2, name => $name);
      
    my $p2 = Grammar::Graph::Final->new(
      partner => $v1, name => $name);

    $self->set_vertex_label($v1, $p1);
    $self->set_vertex_label($v2, $p2);

    my ($start, $final) = $self->_find_endpoints($id);

    $self->_copy_predecessors($v, $v1);
    $self->_copy_successors($start, $v1);

    $self->_copy_successors($v, $v2);
    $self->_copy_predecessors($final, $v2);
    
    graph_delete_vertex_fast($self->g, $v);
  }

  for my $v ($self->g->vertices) {
    die if $self->vertex_isa($v, 'Grammar::Formal::Reference');
  }

}

#####################################################################
# Encapsulate ...
#####################################################################

sub _find_id_by_shortname {
  my ($self, $shortname) = @_;

  for my $k (keys %{ $self->symbol_table }) {
    next unless $self->symbol_table->{$k}{shortname} eq $shortname;
    return $k;
  }
}

sub fa_prelude_postlude {
  my ($self, $shortname) = @_;

  my $s1 = $self->fa_add_state();
  my $s2 = $self->fa_add_state();

  my $sS = $self->fa_add_state();
  my $sF = $self->fa_add_state();

  my $p1 = Grammar::Graph::Prelude->new(partner => $s2);
  my $p2 = Grammar::Graph::Postlude->new(partner => $s1);

  my $pS = Grammar::Graph::Start->new(name => "", partner => $sF);
  my $pF = Grammar::Graph::Final->new(name => "", partner => $sS);

  $self->set_vertex_label($s1, $p1);
  $self->set_vertex_label($s2, $p2);

  $self->set_vertex_label($sS, $pS);
  $self->set_vertex_label($sF, $pF);

  my $id = _find_id_by_shortname($self, $shortname);

  die unless defined $id;

  my $rd = $self->symbol_table->{$id};

=pod

  _copy_predecessors($self, $rd->{start_vertex}, $s1);
  _copy_successors($self, $rd->{start_vertex}, $s1);
  graph_isolate_vertex($self->g, $rd->{start_vertex});

  _copy_predecessors($self, $rd->{final_vertex}, $s2);
  _copy_successors($self, $rd->{final_vertex}, $s2);
  graph_isolate_vertex($self->g, $rd->{final_vertex});

  $self->g->add_edge($rd->{start_vertex}, $s1);
  $self->g->add_edge($s2, $rd->{final_vertex});

=cut

  $self->g->add_edge($sS, $s1);
  $self->g->add_edge($s1, $rd->{start_vertex});
  $self->g->add_edge($rd->{final_vertex}, $s2);
  $self->g->add_edge($s2, $sF);

  $self->_set_start_vertex($sS);
  $self->_set_final_vertex($sF);
}

#####################################################################
# Remove unlabeled vertices
#####################################################################
sub fa_remove_useless_epsilons {
  my ($graph, @todo) = @_;
  my %deleted;

  for my $v (sort @todo) {
    my $label = $graph->get_vertex_label($v);
    next if defined $label and ref($label) ne 'Grammar::Formal::Empty';
    next unless $graph->g->successors($v); # FIXME(bh): why?
    next unless $graph->g->predecessors($v); # FIXME(bh): why?
    for my $src ($graph->g->predecessors($v)) {
      for my $dst ($graph->g->successors($v)) {
        $graph->g->add_edge($src, $dst);
      }
    }
    $deleted{$v}++;
  }
  graph_delete_vertices_fast($graph->g, keys %deleted);
};

#####################################################################
# Merge character classes
#####################################################################
sub fa_merge_character_classes {
  my ($self) = @_;
  
  my %groups = partition_by {
    freeze [
      [sort $self->g->predecessors($_)],
      [sort $self->g->successors($_)]
    ];
  } grep {
    my $label = $self->get_vertex_label($_);
    $label and $label->isa('Grammar::Formal::CharClass');
  } $self->g->vertices;
  
  require Set::IntSpan;

  while (my ($k, $v) = each %groups) {
    next unless @$v > 1;
    my $union = Set::IntSpan->new;
    my $min_pos;

    for my $vertex (@$v) {
      my $label = $self->get_vertex_label($vertex);
      $union->U($label->spans);
      $min_pos //= $label->position;
      $min_pos = $label->position if defined $label->position
        and $label->position < $min_pos;
    }

    my $class = Grammar::Formal::CharClass->new(
      spans => $union,
      position => $min_pos
    );

    my $state = $self->fa_add_state(p => $class);

    $self->_copy_predecessors($v->[0], $state);
    $self->_copy_successors($v->[0], $state);

    graph_delete_vertices_fast($self->g, @$v);
  }
}

#####################################################################
# Separate character classes
#####################################################################
sub fa_separate_character_classes {
  my ($self) = @_;
  
  require Set::IntSpan::Partition;
  
  my @vertices = grep {
    my $label = $self->get_vertex_label($_);
    $label and $label->isa('Grammar::Formal::CharClass')
  } $self->g->vertices;

  my @classes = map {
    $self->get_vertex_label($_)->spans;
  } @vertices;
  
  my %map = Set::IntSpan::Partition::intspan_partition_map(@classes);
  
  for (my $ix = 0; $ix < @vertices; ++$ix) {
    for (@{ $map{$ix} }) {
    
      my $label = $self->get_vertex_label($vertices[$ix]);

      my $state = $self->fa_add_state(p =>
        Grammar::Formal::CharClass->new(spans => $_,
          position => $label->position));
      
      $self->_copy_predecessors($vertices[$ix], $state);
      $self->_copy_successors($vertices[$ix], $state);
    }
    
    graph_delete_vertex_fast($self->g, $vertices[$ix]);
  }
  
}

#####################################################################
# ...
#####################################################################
sub _delete_not_allowed {
  my ($self) = @_;
  graph_delete_vertex_fast($self->g, $_) for grep {
    my $label = $self->get_vertex_label($_);
    $label and $label->isa('Grammar::Formal::NotAllowed');
  } $self->g->vertices;
}

#####################################################################
# ...
#####################################################################
sub _delete_unreachables {
  my ($self) = @_;
  my $symbols = $self->symbol_table;
  my %keep;
  
  $keep{$_}++ for map {
    my @suc = graph_all_successors_and_self($self->g, $_->{start_vertex});
    # Always keep final vertices
    my @fin = $_->{final_vertex};
    (@suc, @fin);
  } values %$symbols;

  graph_delete_vertices_fast($self->g, grep {
    not $keep{$_}
  } $self->g->vertices);
}

#####################################################################
# Utils
#####################################################################
sub get_vertex_label {
  my ($self, $v) = @_;
  return $self->g->get_vertex_attribute($v, 'label');
} 

sub set_vertex_label {
  my ($self, $v, $value) = @_;
  $self->g->set_vertex_attribute($v, 'label', $value);
} 

sub vertex_isa {
  my ($self, $v, $pkg) = @_;
  return UNIVERSAL::isa($self->get_vertex_label($v), $pkg);
}

sub vertex_partner {
  my ($self, $v) = @_;
  my $label = $self->get_vertex_label($v);
  return unless $label;
  return unless UNIVERSAL::can($label, 'partner');
  return $label->partner;
}

sub is_terminal_vertex {
  my ($self, $v) = @_;
  return unless $self->get_vertex_label($v);
  return not $self->vertex_isa($v, 'Grammar::Formal::Empty');
}

sub is_push_vertex {
  my ($self, $v) = @_;
  return $self->vertex_isa($v, 'Grammar::Graph::Start')
    || $self->vertex_isa($v, 'Grammar::Graph::If');
}

sub is_pop_vertex {
  my ($self, $v) = @_;
  return $self->vertex_isa($v, 'Grammar::Graph::Final')
    || $self->vertex_isa($v, 'Grammar::Graph::Fi');
}

sub is_matching_couple {
  my ($self, $v1, $v2) = @_;
  my $label = $self->get_vertex_label($v1);
  return unless UNIVERSAL::can($label, 'partner');
  return $label->partner eq $v2;
}

#####################################################################
# Constructor
#####################################################################
sub _graph_copy_graph_without_terminal_out_edges {
  my ($self) = @_;

  my $tmp = $self->g->copy;

  for my $v ($tmp->vertices) {
    next unless $self->is_terminal_vertex($v);
    for my $s ($tmp->successors($v)) {
      $tmp->delete_edge($v, $s);
    }
  }

  return $tmp
}

sub _create_vertex_to_topological {
  my ($self) = @_;

  my $tmp = _graph_copy_graph_without_terminal_out_edges($self);

  my %result;

  my $ix = 1;
  for my $scc ($tmp->strongly_connected_graph->toposort) {
    # TODO: use get_graph_attribute subvertices instead of split
    $result{$_} = $ix for split/\+/, $scc;
    $ix++;
  }

  return %result;
}

sub _create_vertex_to_scc {
  my ($self) = @_;

  my $tmp = _graph_copy_graph_without_terminal_out_edges($self);

  my %result;

  for my $scc ($tmp->strongly_connected_graph->toposort) {
    # TODO: use get_graph_attribute subvertices instead of split
    next unless $tmp->has_edge($scc, $scc) or $scc =~ /\+/;
    $result{$_} = $scc for split/\+/, $scc;
  }

  return %result;
}

#####################################################################
# ...
#####################################################################

sub fa_drop_rules_not_needed_for {
  my ($self, $shortname) = @_;

  my $ref_graph = $self->_fa_ref_graph();
  my $id = $self->_find_id_by_shortname($shortname);
  my %keep = map { $_ => 1 } $id, $ref_graph->all_successors($id);

  delete $self->symbol_table->{$_} for grep {
    not $keep{$_}
  } keys %{ $self->symbol_table };
}

#####################################################################
# ...
#####################################################################
sub fa_truncate {
  my ($self) = @_;
  graph_truncate_to_vertices_between($self->g,
    $self->start_vertex, $self->final_vertex);
}

#####################################################################
# Constructor
#####################################################################
sub from_grammar_formal {
  my ($class, $formal, $shortname, %options) = @_;
  my $self = $class->new;

  _add_to_automaton($formal, $self);
  _delete_not_allowed($self);
  fa_remove_useless_epsilons($self, $self->g->vertices);
  _delete_unreachables($self);

  my $id = _find_id_by_shortname($self, $shortname);

  my ($start_vertex, $final_vertex) = _find_endpoints($self, $id);

  $self->_set_start_vertex($start_vertex);
  $self->_set_final_vertex($final_vertex);

  $self->fa_prelude_postlude($shortname);

  return $self;
}

#####################################################################
# Helper function to write some forms of repetition to the graph
#####################################################################
sub _bound_repetition {
  my ($min, $max, $child, $fa, $root) = @_;

  die if defined $max and $min > $max;
  
  if ($min <= 1 and not defined $max) {
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my $s3 = $fa->fa_add_state;
    my $s4 = $fa->fa_add_state;
    my ($ps, $pf) = _add_to_automaton($child, $fa, $root);
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $ps);
    $fa->g->add_edge($pf, $s3);
    $fa->g->add_edge($s3, $s4);
    $fa->g->add_edge($s2, $s3) if $min == 0;
    $fa->g->add_edge($s3, $s2); # loop
    return ($s1, $s4);
  }
  
  my $s1 = $fa->fa_add_state;
  my $first = $s1;
  
  while ($min--) {
    my ($src, $dst) = _add_to_automaton($child, $fa, $root);
    $fa->g->add_edge($s1, $src);
    $s1 = $dst;
    $max-- if defined $max;
  }

  if (defined $max and $max == 0) {
    my $s2 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    return ($first, $s2);
  }  

  do {
    my ($src, $dst) = _add_to_automaton($child, $fa, $root);
    $fa->g->add_edge($s1, $src);
    my $sx = $fa->fa_add_state;
    $fa->g->add_edge($dst, $sx);
    $fa->g->add_edge($s1, $sx); # optional because min <= 0 now
    $fa->g->add_edge($sx, $s1) if not defined $max; # loop
    $s1 = $sx;
  } while (defined $max and --$max);

  my $s2 = $fa->fa_add_state;
  $fa->g->add_edge($s1, $s2);

  return ($first, $s2);
}

#####################################################################
# Collection of sub routines that write patterns to the graph
#####################################################################
sub convert_char_class {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state(p => $pattern);
    my $s3 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $s3);
    return ($s1, $s3);
  }

sub convert_prose_value {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state(p => $pattern);
    my $s3 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $s3);
    return ($s1, $s3);
  }

sub convert_reference {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state(p => $pattern);
    my $s3 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $s3);
    return ($s1, $s3);
  }

sub convert_not_allowed {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state(p => $pattern);
    my $s3 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $s3);
    return ($s1, $s3);
  }

sub convert_range {
    my ($pattern, $fa, $root) = @_;
    my $char_class = Grammar::Formal::CharClass
      ->from_numbers_pos($pattern->position, $pattern->min .. $pattern->max);
    return _add_to_automaton($char_class, $fa, $root);
  }

sub convert_ascii_insensitive_string {
    my ($pattern, $fa, $root) = @_;

    use bytes;

    my @spans = map {
      Grammar::Formal::CharClass
        ->from_numbers_pos($pattern->position, ord(lc), ord(uc))
    } split//, $pattern->value;

    my $group = Grammar::Formal::Empty->new;

    while (@spans) {
      $group = Grammar::Formal::Group->new(
        position => $pattern->position,
        p1 => pop(@spans),
        p2 => $group);
    }

    return _add_to_automaton($group, $fa, $root);
  }

sub convert_case_sensitive_string {
    my ($pattern, $fa, $root) = @_;

    my @spans = map {
      Grammar::Formal::CharClass
        ->from_numbers_pos($pattern->position, ord)
    } split//, $pattern->value;
    
    my $group = Grammar::Formal::Empty->new;

    while (@spans) {
      $group = Grammar::Formal::Group->new(
        p1 => pop(@spans),
        p2 => $group
      );
    }

    return _add_to_automaton($group, $fa, $root);
  }

sub convert_grammar {
    my ($pattern, $fa, $root) = @_;
    
    my %map = map {
      $_ => [ _add_to_automaton($pattern->rules->{$_}, $fa) ]
    } keys %{ $pattern->rules };
    
    return unless defined $pattern->start;

    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($ps, $pf) = @{ $map{ $pattern->start } };
    $fa->g->add_edge($s1, $ps);
    $fa->g->add_edge($pf, $s2);

    return ($s1, $s2);
  }

sub convert_grammar_formal {
    my ($pattern, $fa, $root) = @_;
    
    my %map = map {
      $_ => [ _add_to_automaton($pattern->rules->{$_}, $fa) ]
    } keys %{ $pattern->rules };
    
    # root, so we do not return src and dst
    return;
  }

sub convert_rule {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;

    my $table = $fa->symbol_table;

    # FIXME(bh): error if already defined?

    $table->{$pattern} //= {};
    $table->{$pattern}{start_vertex} = $s1;
    $table->{$pattern}{final_vertex} = $s2;
    $table->{$pattern}{shortname} = $pattern->name;

    my $r1 = Grammar::Graph::Start->new(
      name => $pattern->name,
      partner => $s2,
      position => $pattern->position
    );

    my $r2 = Grammar::Graph::Final->new(
      name => $pattern->name,
      partner => $s1,
      position => $pattern->position
    );

    $fa->set_vertex_label($s1, $r1);
    $fa->set_vertex_label($s2, $r2);
    
    my ($ps, $pf) = _add_to_automaton(
      $pattern->p, $fa, [$pattern, $s1, $s2]);
      
    $fa->g->add_edge($s1, $ps);
    $fa->g->add_edge($pf, $s2);
    
    return ($s1, $s2);
  }

sub convert_bounded_repetition {
    my ($pattern, $fa, $root) = @_;
    return _bound_repetition($pattern->min, $pattern->max, $pattern->p, $fa, $root);
  }

sub convert_some_or_more {
    my ($pattern, $fa, $root) = @_;
    return _bound_repetition($pattern->min, undef, $pattern->p, $fa, $root);
  }

sub convert_one_or_more {
    my ($self, $fa, $root) = @_;
    my $s1 = $fa->add_state;
    my $s2 = $fa->add_state;
    my $s3 = $fa->add_state;
    my $s4 = $fa->add_state;
    my ($ps, $pf) = $self->p->add_to_automaton($fa, $root);
    $fa->add_e_transition($s1, $s2);
    $fa->add_e_transition($s2, $ps);
    $fa->add_e_transition($pf, $s3);
    $fa->add_e_transition($s3, $s4);
    $fa->add_e_transition($s3, $s2);
    
    return ($s1, $s4);
  }

sub convert_zero_or_more {
    my ($self, $fa, $root) = @_;
    my $s1 = $fa->add_state;
    my $s2 = $fa->add_state;
    my $s3 = $fa->add_state;
    my $s4 = $fa->add_state;
    my ($ps, $pf) = $self->p->add_to_automaton($fa, $root);
    $fa->add_e_transition($s1, $s2);
    $fa->add_e_transition($s2, $ps);
    $fa->add_e_transition($pf, $s3);
    $fa->add_e_transition($s3, $s4);
    $fa->add_e_transition($s3, $s2);
    $fa->add_e_transition($s2, $s3); # zero
    
    return ($s1, $s4);
  }

sub convert_empty {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s3 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    $fa->g->add_edge($s1, $s2);
    $fa->g->add_edge($s2, $s3);
    return ($s1, $s3);
  }

sub convert_choice {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($p1s, $p1f) = _add_to_automaton($pattern->p1, $fa, $root);
    my ($p2s, $p2f) = _add_to_automaton($pattern->p2, $fa, $root);
    $fa->g->add_edge($s1, $p1s);
    $fa->g->add_edge($s1, $p2s);
    $fa->g->add_edge($p1f, $s2);
    $fa->g->add_edge($p2f, $s2);
    return ($s1, $s2);
  }

sub convert_group {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($p1s, $p1f) = _add_to_automaton($pattern->p1, $fa, $root);
    my ($p2s, $p2f) = _add_to_automaton($pattern->p2, $fa, $root);
    $fa->g->add_edge($p1f, $p2s);
    $fa->g->add_edge($s1, $p1s);
    $fa->g->add_edge($p2f, $s2);
    return ($s1, $s2);
  }

sub convert_conjunction {
    my ($pattern, $fa, $root) = @_;

    return _convert_binary_operation($pattern,
      $fa, $root, "conjunction");
}

sub convert_ordered_conjunction {
    my ($pattern, $fa, $root) = @_;

    return _convert_binary_operation($pattern,
      $fa, $root, "ordered_conjunction");
}

sub convert_ordered_choice {
    my ($pattern, $fa, $root) = @_;

    return _convert_binary_operation($pattern,
      $fa, $root, "ordered_choice");
}

sub _convert_binary_operation {
    my ($pattern, $fa, $root, $op) = @_;
    my $s1 = $fa->fa_add_state();
    my $s2 = $fa->fa_add_state();
    my $s3 = $fa->fa_add_state();
    my $s4 = $fa->fa_add_state();

    my $op1 = Grammar::Graph::Operand->new(
      position => $pattern->position, partner => $s3);
    my $op2 = Grammar::Graph::Operand->new(
      position => $pattern->position, partner => $s3);
    my $op3 = Grammar::Graph::Operand->new(
      position => $pattern->position, partner => $s4);
    my $op4 = Grammar::Graph::Operand->new(
      position => $pattern->position, partner => $s4);

    my $c1 = $fa->fa_add_state(p => $op1);
    my $c2 = $fa->fa_add_state(p => $op2);
    my $c3 = $fa->fa_add_state(p => $op3);
    my $c4 = $fa->fa_add_state(p => $op4);
    
    my ($p1s, $p1f) = _add_to_automaton($pattern->p1, $fa, $root);
    my ($p2s, $p2f) = _add_to_automaton($pattern->p2, $fa, $root);

    my $l3 = Grammar::Graph::If->new(
      position => $pattern->position,
      partner => $s4,
      p1 => $c1,
      p2 => $c2,
      name => $op
    );

    my $l4 = Grammar::Graph::Fi->new(
      position => $pattern->position,
      partner => $s3,
      p1 => $c3,
      p2 => $c4,
      name => $op
    );

    $fa->set_vertex_label($s3, $l3);
    $fa->set_vertex_label($s4, $l4);

    $fa->g->add_edge($c1, $p1s);
    $fa->g->add_edge($c2, $p2s);
    $fa->g->add_edge($p1f, $c3);
    $fa->g->add_edge($p2f, $c4);

    $fa->g->add_edge($s3, $c1);
    $fa->g->add_edge($s3, $c2);
    $fa->g->add_edge($c3, $s4);
    $fa->g->add_edge($c4, $s4);

    $fa->g->add_edge($s1, $s3);
    $fa->g->add_edge($s4, $s2);
    
    return ($s1, $s2);
}

sub convert_subtraction {
  my ($pattern, $fa, $root) = @_;
  return _convert_binary_operation($pattern, $fa, $root, "and_not");
}

sub _add_to_automaton {
  my ($pattern, $self, $root) = @_;
  my $converter = $self->find_converter(ref $pattern);
  if ($converter) {
    return $converter->($pattern, $self, $root);
  }
  my $s1 = $self->fa_add_state;
  my $s2 = $self->fa_add_state(p => $pattern);
  my $s3 = $self->fa_add_state;
  $self->g->add_edge($s1, $s2);
  $self->g->add_edge($s2, $s3);
  return ($s1, $s3);
}

1;

__END__

=head1 NAME

Grammar::Graph - Graph representation of formal grammars

=head1 SYNOPSIS

  use Grammar::Graph;
  my $g = Grammar::Graph->from_grammar_formal($formal);
  my $symbols = $g->symbol_table;
  my $new_state = $g->fa_add_state();
  ...

=head1 DESCRIPTION

Graph representation of formal grammars.

=head1 METHODS

=over

=item C<from_grammar_formal($grammar_formal)>

Constructs a new C<Grammar::Graph> object from a L<Grammar::Formal>
object. C<Grammar::Graph> derives from L<Graph>. The graph has a
graph attribute C<symbol_table> with an entry for each rule identifying
C<start_vertex>, C<final_vertex>, C<shortname>, and other properties.

=item C<fa_add_state(p => $label)>

Adds a new vertex to the graph and optionally labeles it with the
supplied label. The vertex should be assumed to be a random integer.
Care should be taken when adding vertices to the graph through other
means to avoid clashes.

=item C<fa_all_e_reachable($v)>

Returns the successors of $v and transitively any successors that can
be reached without going over a vertex labeled by something other than
C<Grammar::Formal::Empty>-derived objects. In other words, all the
vertices that can be reached without going over an input symbol.

=item C<fa_expand_references()>

Modifies the graph such that vertices are no longer labeled with 
C<Grammar::Formal::Reference> nodes provided there is an entry for
the referenced symbol in the Graph's C<symbol_table>. Recursive and
cyclic references are linearised by vertices labeled with special
C<Grammar::Graph::Start> and C<Grammar::Graph::Final> nodes, and
they in turn are protected by C<Grammar::Graph::Prefix> and linked
C<Grammar::Graph::Suffix> nodes (the former identify the rule, the
latter identify the reference) to ensure the nesting relationship
can be fully recovered.

=item C<fa_merge_character_classes()>

Vertices labeled with a C<Grammar::Formal::CharClass> node that share
the same set of predecessors and successors are merged into a single
vertex labeled with a C<Grammar::Formal::CharClass> node that is the
union of original vertices.

=item C<fa_separate_character_classes()>

Collects all vertices labeled with a C<Grammar::Formal::CharClass> node
in the graph and replaces them with vertices labeled with
C<Grammar::Formal::CharClass> nodes such that an input symbol matches
at most a single C<Grammar::Formal::CharClass>.

=item C<fa_remove_useless_epsilons()>

Removes vertices labeled with nothing or C<Grammar::Formal::Empty> nodes
by connecting all predecessors to all successors directly. The check for
C<Grammar::Formal::Empty> is exact, derived classes do not match.

=back

=head1 EXPORTS

None.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014-2017 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
