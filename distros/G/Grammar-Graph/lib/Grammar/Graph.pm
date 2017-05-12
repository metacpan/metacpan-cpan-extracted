#####################################################################
# Base class for markers
#####################################################################
package Grammar::Graph::Marker;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Empty';

has 'of' => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# StartOf
#####################################################################
package Grammar::Graph::StartOf;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Marker';

#####################################################################
# FinalOf
#####################################################################
package Grammar::Graph::FinalOf;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Marker';

#####################################################################
# Base class for sentinels
#####################################################################
package Grammar::Graph::Sentinel;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Empty';

has 'link' => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# Prefix
#####################################################################
package Grammar::Graph::Prefix;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Sentinel';

#####################################################################
# Suffix
#####################################################################
package Grammar::Graph::Suffix;
use Modern::Perl;
use Moose;
extends 'Grammar::Graph::Sentinel';

#####################################################################
# Grammar::Graph
#####################################################################
package Grammar::Graph;
use 5.012000;
use strict;
use warnings;
use base qw(Graph::Directed);
use Grammar::Formal;
use List::UtilsBy qw/partition_by/;
use List::MoreUtils qw/uniq/;
use List::Util qw/shuffle sum max/;
use Storable qw/freeze thaw/;
use Graph::SomeUtils qw/:all/;

local $Storable::canonical = 1;

our $PREFIX_SUFFIX_SEP = " # ";

our $VERSION = '0.02';

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub _fa_next_id {
  my ($self) = @_;
  
  my $next_id = $self->get_graph_attribute('fa_next_id');
  
  $next_id = do {
    my $max = max(grep { /^[0-9]+$/ } $self->vertices) // 0;
    $max + 1;
  } if not defined $next_id or $self->has_vertex($next_id);

  $self->set_graph_attribute('fa_next_id', $next_id + 1);

  return $next_id;
}

sub fa_add_state {
  my ($self, $expect) = @_;
  
  $expect //= Grammar::Formal::Empty->new;
  
  my $id = $self->_fa_next_id();
  $self->add_vertex($id);
  $self->set_vertex_attribute($id, 'label', $expect)
    if defined $expect;

  return $id;
}

sub fa_all_e_reachable {
  my ($self, $v) = @_;
  my %seen;
  my @todo = ($v);
  while (@todo) {
    my $c = pop @todo;
    my $label = $self->get_vertex_attribute($c, 'label');
    next if $label and not $label->isa('Grammar::Formal::Empty');
    push @todo, grep { not $seen{$_}++ } $self->successors($c);
  }
  keys %seen;
}

#####################################################################
# Clone a subgraph between two vertices
#####################################################################
sub _clone_subgraph_between {
  my ($self, $src, $dst) = @_;

  my %want = map { $_ => 1 }
    graph_vertices_between($self, $src, $dst);

  my %map;
  my @prefixes;
  
  while (my ($k, $yes) = each %want) {
    next unless $yes;
    my $label = $self->get_vertex_attribute($k, 'label');
    push @prefixes, $label if
      $label and $label->isa('Grammar::Graph::Prefix');
    $map{$k} = $self->fa_add_state($label);
  }
  
  for my $p (@prefixes) {
    my @old_link = split/$PREFIX_SUFFIX_SEP/, $p->link;
    my @new_link = map { $map{$_} } @old_link;

    die "Trying to clone Prefix without Suffix"
      unless defined $new_link[1];

    $self->set_vertex_attribute($new_link[0], 'label',
      Grammar::Graph::Prefix->new(link =>
        join $PREFIX_SUFFIX_SEP, @new_link)
    );
    $self->set_vertex_attribute($new_link[1], 'label',
      Grammar::Graph::Suffix->new(link =>
        join $PREFIX_SUFFIX_SEP, @new_link)
    );
  }
  
  while (my ($old, $new) = each %map) {
    for (grep { $want{$_} } $self->successors($old)) {
      $self->add_edge($new, $map{$_});
    }
  }
  
  return ($map{$src}, $map{$dst});
};

#####################################################################
# Generate a graph with all rules with edges over ::References
#####################################################################
sub _fa_ref_graph {
  my ($self) = @_;
  my $symbols = $self->get_graph_attribute('symbol_table');
  my $ref_graph = Graph::Directed->new;

  while (my ($r1, $v) = each %{$symbols}) {
    for (graph_all_successors_and_self($self, $v->{start_vertex})) {
      my $label = $self->get_vertex_attribute($_, 'label');
      if ($label and $label->isa('Grammar::Formal::Reference')) {
        my $r2 = $self->get_vertex_attribute($_, 'label')->expand;
        $ref_graph->add_edge($r1 . '', $r2 . '');
      }
    }
  }

  return $ref_graph;
}

#####################################################################
# ...
#####################################################################
sub _do_replace_thing {
  my ($self, $direct, $start, $final) = @_;

  my $label = $self->get_vertex_attribute($direct, 'label');
  my $prefix = $self->fa_add_state();
  my $suffix = $self->fa_add_state();
  my $link = join $PREFIX_SUFFIX_SEP, $prefix, $suffix;

  my $prefix_p = Grammar::Graph::Prefix->new(link => $link);
  my $suffix_p = Grammar::Graph::Suffix->new(link => $link);
  $self->set_vertex_attribute($prefix, 'label', $prefix_p);
  $self->set_vertex_attribute($suffix, 'label', $suffix_p);
  
  $self->add_edge($_, $prefix) for $self->predecessors($direct);
  $self->add_edge($suffix, $_) for $self->successors($direct);

  $self->add_edge($final, $suffix);
  $self->add_edge($prefix, $start);

  graph_delete_vertex_fast($self, $direct);
}

#####################################################################
# ...
#####################################################################
sub _find_refs {
  my ($self, $id, $v) = @_;
  grep {
    $self->has_vertex_attribute($_, 'label') and
    $self->get_vertex_attribute($_, 'label')
      ->isa('Grammar::Formal::Reference') and
    $self->get_vertex_attribute($_, 'label')
      ->expand eq $id;
  } graph_all_successors_and_self($self, $v);
}

sub _replace_direct_recursion {
  my ($self, $id) = @_;
  
  my $symbols = $self->get_graph_attribute('symbol_table');
  my $v = $symbols->{$id}{start_vertex};

  my @direct_refs = _find_refs($self, $id, $v);
  
  for my $direct (@direct_refs) {
    my $final = $symbols->{$id}{final_vertex};
    my $start = $symbols->{$id}{start_vertex};
    _do_replace_thing($self, $direct, $start, $final);
  }
}

sub _replace_strongly_connected_component {
  my ($self, $comb) = @_;
  my $symbols = $self->get_graph_attribute('symbol_table');
  
  my %backup = map { $_ => [
    _clone_subgraph_between($self,
      $symbols->{$_}{start_vertex},
      $symbols->{$_}{final_vertex})
  ] } split/\+/, $comb;
  
  my %expanded;

  for my $last (split/\+/, $comb) {
    my @other = grep { $_ ne $last } split/\+/, $comb;
    
    for my $id (@other) {
      _replace_direct_recursion($self, $id);

      my @things = map { _find_refs($self, $id,
        $symbols->{$_}{start_vertex}) }
        split/\+/, $comb;
      
      for (@things) {
        my ($start, $final) = _clone_subgraph_between($self,
          $symbols->{$id}{start_vertex},
          $symbols->{$id}{final_vertex});
        _do_replace_thing($self, $_, $start, $final);
      }
    }

    _replace_direct_recursion($self, $last);
    
    # ...
    $expanded{$last} = [
      _clone_subgraph_between($self,
        $symbols->{$last}{start_vertex},
        $symbols->{$last}{final_vertex})
    ];
    
    # restore from backup
    while (my ($id, $start_final) = each %backup) {
      graph_delete_vertices_fast($self,
        graph_all_successors_and_self($self, $symbols->{$id}{start_vertex})
      );

      my ($start, $final) = _clone_subgraph_between($self,
        @$start_final);
      $symbols->{$id}{start_vertex} = $start;
      $symbols->{$id}{final_vertex} = $final;
    }
  }
  
  while (my ($id, $start_final) = each %expanded) {
    graph_delete_vertices_fast($self,
      graph_all_successors_and_self($self, $symbols->{$id}{start_vertex})
    );
    $symbols->{$id}{start_vertex} = $start_final->[0];
    $symbols->{$id}{final_vertex} = $start_final->[1];
  }
}

sub fa_expand_references {
  my ($self) = @_;
  my $ref_graph = $self->_fa_ref_graph;
  my $symbols = $self->get_graph_attribute('symbol_table');
  my $scg = $ref_graph->strongly_connected_graph;
  my @topo = reverse $scg->toposort;
  
  for (my $ix = 0; $ix < @topo; ++$ix) {
    my $comp = $topo[$ix];

    if ($comp =~ /\+/) {
      _replace_strongly_connected_component($self, $comp);
    } else {
      _replace_direct_recursion($self, $comp);
    }

    for my $id (split/\+/, $comp) {

      my @things = map { _find_refs($self, $id,
      $symbols->{$_}{start_vertex}) }
        $ref_graph->predecessors($id);
      
      for my $v (@things) {

        next unless $self->has_vertex($v);
      
        my ($src, $dst) = $self->_clone_subgraph_between(
          $symbols->{$id}{start_vertex},
          $symbols->{$id}{final_vertex});
          
        for my $o ($self->predecessors($v)) {
          $self->add_edge($o, $src);
        }
        
        for my $o ($self->successors($v)) {
          $self->add_edge($dst, $o);
        }

        graph_delete_vertex_fast($self, $v);
      }
    }
  }
}

#####################################################################
# Remove unlabeled vertices
#####################################################################
sub fa_remove_useless_epsilons {
  my ($graph, @todo) = @_;
  my %deleted;
  for my $v (sort @todo) {
    my $label = $graph->get_vertex_attribute($v, 'label');
    next if defined $label and ref($label) ne 'Grammar::Formal::Empty';
    next unless $graph->successors($v);
    next unless $graph->predecessors($v);
    for my $src ($graph->predecessors($v)) {
      for my $dst ($graph->successors($v)) {
        $graph->add_edge($src, $dst);
      }
    }
    $deleted{$v}++;
  }
  graph_delete_vertices_fast($graph, keys %deleted);
};

#####################################################################
# Merge character classes
#####################################################################
sub fa_merge_character_classes {
  my ($self) = @_;
  
  my %groups = partition_by {
    freeze [[sort $self->predecessors($_)], [sort $self->successors($_)]];
  } grep {
    my $label = $self->get_vertex_attribute($_, 'label');
    $label and $label->isa('Grammar::Formal::CharClass');
  } $self->vertices;
  
  require Set::IntSpan;
  while (my ($k, $v) = each %groups) {
    next unless @$v > 1;
    my $union = Set::IntSpan->new;
    for my $vertex (@$v) {
      my $label = $self->get_vertex_attribute($vertex, 'label');
      $union->U($label->spans);
    }
    my $class = Grammar::Formal::CharClass->new(spans => $union);
    my $state = $self->fa_add_state($class);
    $self->add_edge($_, $state) for $self->predecessors($v->[0]);
    $self->add_edge($state, $_) for $self->successors($v->[0]);
    graph_delete_vertices_fast($self, @$v);
  }
}

#####################################################################
# Merge character classes
#####################################################################
sub fa_separate_character_classes {
  my ($self) = @_;
  
  require Set::IntSpan::Partition;
  
  my @vertices = grep {
    my $label = $self->get_vertex_attribute($_, 'label');
    $label and $label->isa('Grammar::Formal::CharClass')
  } $self->vertices;

  my @classes = map {
    $self->get_vertex_attribute($_, 'label')->spans;
  } @vertices;
  
  my %map = Set::IntSpan::Partition::intspan_partition_map(@classes);
  
  for (my $ix = 0; $ix < @vertices; ++$ix) {
    for (@{ $map{$ix} }) {
      my $state = $self->fa_add_state(
        Grammar::Formal::CharClass->new(spans => $_));
      
      for my $p ($self->predecessors($vertices[$ix])) {
        $self->add_edge($p, $state);
      }
      for my $s ($self->successors($vertices[$ix])) {
        $self->add_edge($state, $s);
      }
    }
    
    graph_delete_vertex_fast($self, $vertices[$ix]);
  }
  
}

#####################################################################
# ...
#####################################################################
sub _delete_not_allowed {
  my ($self) = @_;
  graph_delete_vertex_fast($self, $_) for grep {
    my $label = $self->get_vertex_attribute($_, 'label');
    $label and $label->isa('Grammar::Formal::NotAllowed');
  } $self->vertices;
}

#####################################################################
# ...
#####################################################################
sub _delete_unreachables {
  my ($self) = @_;
  my $symbols = $self->get_graph_attribute('symbol_table');
  my %keep;
  
  $keep{$_}++ for map {
    my @suc = graph_all_successors_and_self($self, $_->{start_vertex});
    # Always keep final vertices
    my @fin = $_->{final_vertex};
    (@suc, @fin);
  } values %$symbols;

  graph_delete_vertices_fast($self, grep {
    not $keep{$_}
  } $self->vertices);
}

#####################################################################
# Constructor
#####################################################################
sub from_grammar_formal {
  my ($class, $formal, %options) = @_;
  my $self = $class->new;
  
  _add_to_automaton($formal, $self);
  _delete_not_allowed($self);
  fa_remove_useless_epsilons($self, $self->vertices);
  _delete_unreachables($self);
  
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
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $ps);
    $fa->add_edge($pf, $s3);
    $fa->add_edge($s3, $s4);
    $fa->add_edge($s2, $s3) if $min == 0;
    $fa->add_edge($s3, $s2); # loop
    return ($s1, $s4);
  }
  
  my $s1 = $fa->fa_add_state;
  my $first = $s1;
  
  while ($min--) {
    my ($src, $dst) = _add_to_automaton($child, $fa, $root);
    $fa->add_edge($s1, $src);
    $s1 = $dst;
    $max-- if defined $max;
  }

  if (defined $max and $max == 0) {
    my $s2 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    return ($first, $s2);
  }  

  do {
    my ($src, $dst) = _add_to_automaton($child, $fa, $root);
    $fa->add_edge($s1, $src);
    my $sx = $fa->fa_add_state;
    $fa->add_edge($dst, $sx);
    $fa->add_edge($s1, $sx); # optional because min <= 0 now
    $fa->add_edge($sx, $s1) if not defined $max; # loop
    $s1 = $sx;
  } while (defined $max and --$max);

  my $s2 = $fa->fa_add_state;
  $fa->add_edge($s1, $s2);

  return ($first, $s2);
}

#####################################################################
# Collection of sub routines that write patterns to the graph
#####################################################################
my %pattern_converters = (

  'Grammar::Formal::CharClass' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state($pattern);
    my $s3 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    return ($s1, $s3);
  },

  'Grammar::Formal::ProseValue' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state($pattern);
    my $s3 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    return ($s1, $s3);
  },

  'Grammar::Formal::Reference' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state($pattern);
    my $s3 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    return ($s1, $s3);
  },

  'Grammar::Formal::NotAllowed' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state($pattern);
    my $s3 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    return ($s1, $s3);
  },

  'Grammar::Formal::Whatever' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state($pattern);
    my $s3 = $fa->fa_add_state;

    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    $fa->add_edge($s1, $s3);
    $fa->add_edge($s2, $s2);
    
    return ($s1, $s3);
  },

  'Grammar::Formal::Range' => sub {
    my ($pattern, $fa, $root) = @_;
    my $char_class = Grammar::Formal::CharClass
      ->from_numbers($pattern->min .. $pattern->max);
    return _add_to_automaton($char_class, $fa, $root);
  },

  'Grammar::Formal::AsciiInsensitiveString' => sub {
    my ($pattern, $fa, $root) = @_;

    use bytes;

    my @spans = map {
      Grammar::Formal::CharClass
        ->from_numbers(ord(lc), ord(uc))
    } split//, $pattern->value;

    my $group = Grammar::Formal::Empty->new;

    while (@spans) {
      $group = Grammar::Formal::Group->new(p1 => pop(@spans), p2 => $group);
    }

    return _add_to_automaton($group, $fa, $root);
  },

  'Grammar::Formal::CaseSensitiveString' => sub {
    my ($pattern, $fa, $root) = @_;

    my @spans = map {
      Grammar::Formal::CharClass
        ->from_numbers(ord)
    } split//, $pattern->value;
    
    my $group = Grammar::Formal::Empty->new;

    while (@spans) {
      $group = Grammar::Formal::Group->new(p1 => pop(@spans), p2 => $group);
    }

    return _add_to_automaton($group, $fa, $root);
  },

  'Grammar::Formal::Grammar' => sub {
    my ($pattern, $fa, $root) = @_;
    
    my %map = map {
      $_ => [ _add_to_automaton($pattern->rules->{$_}, $fa) ]
    } keys %{ $pattern->rules };
    
    return unless defined $pattern->start;

    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($ps, $pf) = @{ $map{ $pattern->start } };
    $fa->add_edge($s1, $ps);
    $fa->add_edge($pf, $s2);

    return ($s1, $s2);
  },

  'Grammar::Formal' => sub {
    my ($pattern, $fa, $root) = @_;
    
    my %map = map {
      $_ => [ _add_to_automaton($pattern->rules->{$_}, $fa) ]
    } keys %{ $pattern->rules };
    
    # root, so we do not return src and dst
    return;
  },

  'Grammar::Formal::Rule' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;

    my $table = $fa->get_graph_attribute('symbol_table') // {};
    $fa->set_graph_attribute('symbol_table', $table);
    $table->{$pattern} //= {};
    $table->{$pattern}{start_vertex} = $s1;
    $table->{$pattern}{final_vertex} = $s2;
    $table->{$pattern}{shortname} = $pattern->name;
    $fa->set_vertex_attribute($s1, 'label', 
      Grammar::Graph::StartOf->new(of => "$pattern"));
    $fa->set_vertex_attribute($s2, 'label', 
      Grammar::Graph::FinalOf->new(of => "$pattern"));
    
    my ($ps, $pf) = _add_to_automaton($pattern->p, $fa, [$pattern, $s1, $s2]);
    $fa->add_edge($s1, $ps);
    $fa->add_edge($pf, $s2);
    
    return ($s1, $s2);
  },

  'Grammar::Formal::BoundRepetition' => sub {
    my ($pattern, $fa, $root) = @_;
    return _bound_repetition($pattern->min, $pattern->max, $pattern->p, $fa, $root);
  },

  'Grammar::Formal::SomeOrMore' => sub {
    my ($pattern, $fa, $root) = @_;
    return _bound_repetition($pattern->min, undef, $pattern->p, $fa, $root);
  },

  'Grammar::Formal::OneOrMore' => sub {
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
  },

  'Grammar::Formal::ZeroOrMore' => sub {
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
  },

  'Grammar::Formal::Empty' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s3 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    $fa->add_edge($s1, $s2);
    $fa->add_edge($s2, $s3);
    return ($s1, $s3);
  },

  'Grammar::Formal::Choice' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($p1s, $p1f) = _add_to_automaton($pattern->p1, $fa, $root);
    my ($p2s, $p2f) = _add_to_automaton($pattern->p2, $fa, $root);
    $fa->add_edge($s1, $p1s);
    $fa->add_edge($s1, $p2s);
    $fa->add_edge($p1f, $s2);
    $fa->add_edge($p2f, $s2);
    return ($s1, $s2);
  },

  'Grammar::Formal::Group' => sub {
    my ($pattern, $fa, $root) = @_;
    my $s1 = $fa->fa_add_state;
    my $s2 = $fa->fa_add_state;
    my ($p1s, $p1f) = _add_to_automaton($pattern->p1, $fa, $root);
    my ($p2s, $p2f) = _add_to_automaton($pattern->p2, $fa, $root);
    $fa->add_edge($p1f, $p2s);
    $fa->add_edge($s1, $p1s);
    $fa->add_edge($p2f, $s2);
    return ($s1, $s2);
  },

);


sub _add_to_automaton {
  my ($pattern, $self, $root) = @_;
  if ($pattern_converters{ref $pattern}) {
    return $pattern_converters{ref $pattern}->($pattern, $self, $root);
  }
  my $s1 = $self->fa_add_state;
  my $s2 = $self->fa_add_state($pattern);
  my $s3 = $self->fa_add_state;
  $self->add_edge($s1, $s2);
  $self->add_edge($s2, $s3);
  return ($s1, $s3);
}

1;

__END__

=head1 NAME

Grammar::Graph - Graph representation of formal grammars

=head1 SYNOPSIS

  use Grammar::Graph;
  my $g = Grammar::Graph->from_grammar_formal($formal);
  my $symbols = $g->get_graph_attribute('symbol_table');
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

=item C<fa_add_state($label)>

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
C<Grammar::Graph::StartOf> and C<Grammar::Graph::FinalOf> nodes, and
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

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
