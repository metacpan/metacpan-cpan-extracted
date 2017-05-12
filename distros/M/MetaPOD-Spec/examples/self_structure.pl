#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Data::Dump qw(pp);
use Path::Tiny qw(path);
use Path::Iterator::Rule;
use MetaPOD::Assembler;
use GraphViz2;

my $output = path($FindBin::Bin);

my $root = path($FindBin::Bin)->parent()->child('lib');

my $rule = Path::Iterator::Rule->new()->name(qr/^.*.pm/);
my $it   = $rule->iter("$root");

my $assembler = MetaPOD::Assembler->new();
my $g         = GraphViz2->new(
  graph => {
    rankdir     => 'LR',
    splines     => 'spline',
    concentrate => 1,
    compound    => 1,
    sep         => 0.1,
    mindist     => 0.1,
    smoothing   => 'triangle',

    #  overlap => 'false',
    #    mode   => 'ipsep',
  },
  global => {
    record_shape => 'Mrecord',
  },

  #  ratio   => 'compress',
  node    => { 'shape' => 'record', style => 'dotted' },
  edge    => { minlen  => 1 },
  verbose => 1,
);

my $shapes = {
  'class'        => [ 'shape' => 'Mrecord', style    => 'solid', fontsize => 7,       height => 0.1, color => '#7e1e9c' ],
  'role'         => [ 'shape' => 'Mrecord', fontsize => '7',     style    => 'solid', height => 0.1, color => '#15b01a' ],
  'single_class' => [ 'shape' => 'Mrecord', style    => 'solid', fontsize => 7,       height => 0.1, color => '#0343df' ],

};
my (@edgesame) = (
  fontsize    => 6,
  dir         => 'forward',
  'arrowhead' => 'open',
  arrowsize   => 0.5,
  headclip    => 1,
  tailclip    => 1,
);
my $edges = {
  'is_inherit' => [ @edgesame, label => 'inherited by', weight => 100, color => '#ff81c0', ],
  'is_do'      => [ @edgesame, label => 'consumed by',  weight => 1,   color => '#653700', ],

};

my @assemblies;

while ( my $file = $it->() ) {
  push @assemblies, { file => $file, result => $assembler->assemble_file($file) };
}

my %namespaces;

for my $asm (@assemblies) {
  my $ns = $asm->{result}->namespace;
  if ( not exists $namespaces{$ns} ) {
    $namespaces{$ns} = {};
  }
  if ( not exists $namespaces{$ns}->{interfaces} ) {
    $namespaces{$ns}->{interfaces} = {};
  }
  if ( not exists $namespaces{$ns}->{group} ) {
    $namespaces{$ns}->{group} = '__TOP__';
  }
  for my $interface ( $asm->{result}->interface ) {
    $namespaces{$ns}->{interfaces}->{$interface} = 1;
    $namespaces{$ns}->{extra} //= {};
    $namespaces{$ns}->{extra} = { %{ $namespaces{$ns}->{extra} }, @{ $shapes->{$interface} } };
  }
  for my $inherit ( $asm->{result}->inherits ) {
    $namespaces{$inherit} = {} unless exists $namespaces{$inherit};
  }
  for my $does ( $asm->{result}->does ) {
    $namespaces{$does} = {} unless exists $namespaces{$does};
  }
}
for my $ns ( sort keys %namespaces ) {
  if ( $ns =~ /^MetaPOD::/ ) {
    $namespaces{$ns}->{group} = 'MetaPOD';
  }
  if ( $ns =~ /^MetaPOD::Format::JSON::/ ) {
    $namespaces{$ns}->{group} = 'MetaPOD::Format::JSON';
  }
}

sub record {
  $_[1] ||= 0;
  my @pp;
  if ( not ref $_[0] ) {
    my $port = ( ++$_[1] );
    return '<port' . $port . '> ' . $_[0];
  }
  if ( @{ $_[0] } < 1 ) {
    return '';
  }
  if ( @{ $_[0] } < 2 ) {
    return record( @{ $_[0] }, $_[1] );
  }
  for my $element ( @{ $_[0] } ) {
    if ( ref $element eq 'ARRAY' ) {
      push @pp, '{' . record( $element, $_[1] ) . '}';
      next;
    }
    if ( not ref $element ) {
      my $port = ( ++$_[1] );
      push @pp, '<port' . $port . '> ' . $element;
    }

  }

  return '{' . ( join q{|}, @pp ) . '}';
}

for my $ns ( sort keys %namespaces ) {
  my $sn   = $ns;
  my $base = $namespaces{$ns}->{group};
  if ( $base ne '__TOP__' ) {

    #   $sn =~ s/^\Q$base\E:://;
  }

  my @rec = ($sn);
  if ( keys %{ $namespaces{$ns}->{interfaces} } ) {
    unshift @rec, [ keys %{ $namespaces{$ns}->{interfaces} } ];
  }
  $namespaces{$ns}->{label} = record( \@rec );
}

my %groups;

my %group_nests = ( 'MetaPOD::Format::JSON' => 'MetaPOD' );

for my $ns ( sort keys %namespaces ) {
  my $group = $namespaces{$ns}->{group};
  if ( not $group or $group eq '__TOP__' ) {
    $g->add_node( name => $ns, label => $namespaces{$ns}->{label}, %{ $namespaces{$ns}->{extra} } );
  }
  else {
    $groups{$group} = 1;
  }
}
my $cluster_id = 1;
for my $group ( sort keys %groups ) {
  $g->push_subgraph(
    name   => 'cluster_' . $cluster_id,
    global => { rank => 'max', recordshape => 'Mrecord' },
    graph  => { label => $group . '::', rankdir => 'TD' }
  );
  $cluster_id++;
  for my $ns ( sort keys %namespaces ) {
    next unless $namespaces{$ns}->{group} eq $group;
    $g->add_node( name => $ns, label => $namespaces{$ns}->{label}, %{ $namespaces{$ns}->{extra} } );
  }
  for my $nest ( sort keys %group_nests ) {
    if ( $group_nests{$nest} eq $group ) {
      $g->push_subgraph(
        name   => 'cluster_' . $cluster_id,
        global => { rank => 'max', recordshape => 'Mrecord' },
        graph  => { label => $nest . '::', rankdir => 'TD' }
      );
      $cluster_id++;
      for my $ns ( sort keys %namespaces ) {
        next unless $namespaces{$ns}->{group} eq $nest;
        $g->add_node( name => $ns, label => $namespaces{$ns}->{label}, %{ $namespaces{$ns}->{extra} } );
      }
      $g->pop_subgraph();
      delete $groups{$nest};
    }
  }
  $g->pop_subgraph();
}
for my $asm (@assemblies) {
  my $ns     = $asm->{result}->namespace;
  my $result = $asm->{result};

  $g->add_edge( to => $ns, from => $_, @{ $edges->{is_inherit} } ) for $result->inherits;
  $g->add_edge( to => $ns, from => $_, @{ $edges->{is_do} } )      for $result->does;
}

$g->run( format => 'canon', output_file => $output->child('self_structure.dot')->stringify );
$g->run( driver => 'dot', format => 'png', output_file => $output->child('self_structure.png')->stringify );

