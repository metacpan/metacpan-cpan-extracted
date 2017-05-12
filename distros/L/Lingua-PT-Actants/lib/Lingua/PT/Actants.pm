package Lingua::PT::Actants;
# ABSTRACT: compute verb actants for Portuguese
$Lingua::PT::Actants::VERSION = '0.05';
use strict;
use warnings;

use Storable qw/dclone/;

sub new {
  my ($class, %args) = @_;
  my $self = bless({ }, $class);

  if (exists($args{conll})) {
    $self->{conll} = $args{conll};
  }
  else {
    # FIXME PLN::PT
  }

  # initial data -- conll format
  $self->{data} = $self->_conll2data($self->{conll});

  # build a tree from the list of deps
  $self->{tree} = $self->_data2tree($self->{data});

  # split tree into one tree per verb+conj
  my $tree = dclone($self->{tree});
  $self->{deps}   = [ reverse $self->_tree2deps($tree) ];

  # simplify each dep tree verbs
  my @deps = @{dclone($self->{deps})};
  $self->{simple} = [ map {$self->_tree2simple($_)} @deps ];

  return $self;
}

# conll -> data
sub _conll2data {
  my ($self, $conll) = @_;

  my @data;
  foreach my $line (split /\n/, $conll) {
    next if $line =~ m/^\s*$/;

    my @l = split /\s+/, $line;
    push @data, {
        id=>$l[0], form=>$l[1], pos=>$l[3], dep=>$l[6], rule=>$l[7]
      };
  }

  return [@data];
}

# data -> tree
sub _data2tree {
  my ($self, $data) = @_;

  my $root;
  foreach (@$data) {
    $root = $_ if $_->{rule} eq 'ROOT';
  }

  $root = $self->_node($root, $data);

  return $root;
}

sub _node {
  my ($self, $node, $data) = @_;

  my @child = ();
  foreach (@$data) {
    push @child, $self->_node($_, $data) if ($_->{dep} == $node->{id});
  }
  $node->{child} = [@child];

  return $node;
}

# tree -> deps
sub _tree2deps {
  my ($self, $node, @deps) = @_;

  if ($node->{pos} eq 'VERB') {
    my @child = ();
    foreach my $c (@{ $node->{child} }) {
      if ($c->{pos} eq 'VERB' and $c->{rule} eq 'conj') {
        push @deps, $self->_tree2deps($c, @deps);
      }
      else {
        push @child, $c;
      }
    }
    $node->{child} = [@child];
  }
  push @deps, $node;

  return @deps;
}

# tree -> simple tree
# FIXME make recursive
sub _tree2simple {
  my ($self, $node) = @_;

  if ($node->{pos} eq 'VERB') {
    my $found = undef;
    foreach my $c (@{ $node->{child} }) {
      $found = $c if ($c->{pos} eq 'VERB');
    }
    if ($found) {
      my @child;
      foreach (@{ $node->{child} }, @{$found->{child}}) {
        push @child, $_ unless $_->{id} == $found->{id};
      }
      $found->{child} = [@child];
      $node = $found;
    }
  }

  return $node;
}

sub tree2dot {
  my ($self, $tree) = @_;

  my $data = $self->{$tree};
  my @graphs = ();
  if (ref($data) eq 'ARRAY') { push @graphs, @$data; }
  else { push @graphs, $data; }

  my $dot = "digraph G {\ncharset= \"UTF-8\";\n";
  foreach (@graphs) {
    my $rand = int(rand(1000));
    $dot .= " subgraph G_$rand {\n";
    $dot .= join("\n", $self->_deps2nodes($rand, $_));
    $dot .= join("\n", $self->_deps2edges($rand, $_));
    $dot .= "\n }\n";
  }
  $dot .= "\n}\n";
}

sub _deps2nodes {
  my ($self, $prefix, $node) = @_;
  my @lines;

  push @lines, " node [label=\"$node->{form}\"] N_${prefix}_$node->{id};";
  foreach (@{$node->{child}}) {
    push @lines, $self->_deps2nodes($prefix, $_);
  }

  return @lines;
}

sub _deps2edges {
  my ($self, $prefix, $node) = @_;
  my @lines;

  foreach (@{$node->{child}}) {
    push @lines,  " N_${prefix}_$node->{id} -> N_${prefix}_$_->{id} [label=\"$_->{rule}\"];";
    push @lines, $self->_deps2edges($prefix, $_);
  }

  return @lines;
}

sub cores2dot {
  my ($self, @cores) = @_;

  my $dot = "digraph G {\ncharset= \"UTF-8\";\n";
  foreach my $core (@cores) {
    my $rand = int(rand(1000));
    $dot .= " subgraph G_$rand {\n";
    foreach ($core->{verb}, @{$core->{cores}}) {
      $dot .= " node [label=\"$_->{form}\"] N_$_->{id};";
    }
    foreach (@{$core->{cores}}) {
      $dot .= "  N_$core->{verb}->{id} -> N_$_->{id};\n";
    }
    $dot .= "\n }\n";
  }
  $dot .= "\n}\n";

  return $dot;
}

sub text {
  my ($self) = @_;

  return join(' ', map {$_->{form}} @{$self->{data}});
}

sub actants {
  my ($self, %args) = @_;

  my @cores = $self->acts_cores;
  my @syns = $self->acts_syns(@cores);

  return ([@cores], [@syns]);
}

# compute actant cores
sub acts_cores {
  my ($self) = @_;
  my $data = $self->{simple};
  my @final;

  foreach my $tree (@$data) {
    my $verb = dclone($tree);
    delete $verb->{child};

    my @cores = ();
    my @children = @{$tree->{child}};

    foreach my $i (@children) {
      if ($self->_score($i) > 0) {
        push @cores, $i;
      }
      push @children, @{$i->{child}} if $i->{child};
    }
    push @final, { verb=>$verb, cores=>[@cores] };
  }

  $self->{cores} = [@final];

  return @final;
}

sub cores_simple {
  my ($self, @cores) = @_;
  @cores = @{$self->{cores}} unless @cores;

  my @simple;
  foreach (@cores) {
    my $verb = $_->{verb}->{form};
    my @cs = @{$_->{cores}};
    @cs = map {$_->{form}} @cs;
    push @simple, { $verb => [@cs] };
  }

  return @simple;
}

sub acts_syns {
  my ($self, @cores) = @_;
  @cores = @{$self->{cores}} unless @cores;

  my @syns;
  foreach (@cores) {
    my $verb = $_->{verb};
    my @cs = @{ $_->{cores} };
    my @curr;

    foreach my $c (@cs) {
      my @tokens = ($c);
      my @child = exists($c->{child}) ? @{$c->{child}} : ();
      foreach (@child) {
        unless (_is_core($_, @cs)) {
          push @tokens, $_;
          push @child, @{$_->{child}};
        }
      }
      @tokens = sort {$a->{id} <=> $b->{id}} @tokens;
      delete($_->{child}) foreach (@tokens);
      push @curr, [@tokens];
    }

    push @syns, { verb=>$verb, syns=>[@curr] };
  }

  return @syns;
}

sub _is_core {
  my ($c, @cs) = @_;

  foreach (@cs) {
    return 1 if $_->{id} == $c->{id};
  }

  return 0;
}

sub _score {
  my ($self, $token) = @_;
  my $score = 0;

  # token POS component
  $score +=  8  if ($token->{pos} =~ m/^(noun|propn|prop)$/i);
  $score += -10 if ($token->{pos} =~ m/^(punct)$/i);

  # token rule component
  $score += 4 if ($token->{rule} =~ m/^(nsubj|nsubjpass)$/i);
  $score += 2 if ($token->{rule} =~ m/^(nmod)$/i);

  return $score;
}

sub syns_simple {
  my ($self, @syns) = @_;

  my @simple;
  foreach (@syns) {
    my $verb = $_->{verb}->{form};
    my @curr;
    foreach my $s (@{$_->{syns}}) {
      push @curr, join(' ', map {$_->{form}} @$s);
    };
    
    push @simple, { $verb => [@curr] };
  }

  return @simple;
}

sub pp_acts_cores {
  my ($self, @cores) = @_;

  my $r = "# Actants syntagma cores\n";
  foreach (@cores) {
    my ($verb, @tokens) = ($_->{verb}, @{$_->{cores}} );

    $r .= " Verb: $verb->{form}\n";
    foreach (@tokens) {
      $r .= sprintf "  = %s\n", $_->{form};
    }
  }

  return $r;
}

sub pp_acts_syntagmas {
  my ($self, @syns) = @_;

  my $r = "# Actants syntagmas\n";
  foreach (@syns) {
    my ($verb, @list) = ($_->{verb}, @{ $_->{syns} });

    $r .= " Verb: $verb->{form}\n";
    foreach (@list) {
      $r .= sprintf "  = %s\n", join(' ', map {$_->{form}} @$_);
    }
  }

  return $r;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::PT::Actants - compute verb actants for Portuguese

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # using as a library
    use Lingua::PT::Actants;
    my $a = Lingua::PT::Actants->new( conll => $input );
    my $actants = $a->actants;  # a list cores per main verb found

    # example from the command line
    $ cat examples/input-1.txt
    1   A       _   DET     DET     _   2   det     _   _
    2   Maria   _   PROPN   PROPN   _   3   nsubj   _   _
    3   tem     _   VERB    VERB    _   0   ROOT    _   _
    4   razão   _   NOUN    NOUN    _   3   dobj    _   _
    5   .       _   PUNCT   PUNCT   _   3   punct   _   _

    $ actants examples/input-1.txt
    A Maria tem razão .
    
    # Actants syntagma cores
     Verb: tem
      = Maria
      = razão
    
    # Actants syntagmas
     Verb: tem
      = A Maria
      = razão

=head1 DESCRIPTION

This module implements an algorithm that computes the actants, and
corresponding syntagmas, for a sentence.

For a complete example visit this
L<page|http://norma-simplex.nrc.pt/docs/acts-1.html>.

=head1 METHODS

=head2 new

Create a new object, pass as argument the input text in CONLL format.

=head2 text

Returns the original text.

=head2 acts_cores

Compute the core (a token) of the actants syntagmas.

=head2 acts_syntagmas

Given the actants cores compute the full syntagma (phrase) for each core.

=head2 actants

Compute actants for a sentence, returns a list of actants found.

=head2 pp_acts_cores

Pretty print actants cores, mainly to be used by the command line interface.

=head2 pp_acts_syntagmas

Pretty print actants syntagmas, mainly to be used by the command line interface.

=head1 ACKNOWLEDGEMENTS

This work is a result of the project “SmartEGOV: Harnessing EGOV for Smart
Governance (Foundations, methods, Tools) / NORTE-01-0145-FEDER-000037”,
supported by Norte Portugal Regional Operational Programme (NORTE 2020),
under the PORTUGAL 2020 Partnership Agreement, through the European Regional
Development Fund (EFDR).

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
