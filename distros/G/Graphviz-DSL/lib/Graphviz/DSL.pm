package Graphviz::DSL;
use strict;
use warnings;
use 5.008_001;

use Carp ();
use Encode ();
use File::Which ();

use Graphviz::DSL::Graph;
use Graphviz::DSL::Edge;
use Graphviz::DSL::Node;

our $VERSION = '0.03';

sub import {
    my $class = shift;
    my $pkg   = caller;

    no strict   'refs';
    no warnings 'redefine';

    *{"$pkg\::graph"}    = _build_graph();
    *{"$pkg\::add"}      = sub { goto &add      };
    *{"$pkg\::route"}    = sub { goto &route    };
    *{"$pkg\::node"}     = sub { goto &node     };
    *{"$pkg\::edge"}     = sub { goto &edge     };
    *{"$pkg\::nodes"}    = sub { goto &nodes    };
    *{"$pkg\::edges"}    = sub { goto &edges    };
    *{"$pkg\::nodeset"}  = sub { goto &nodeset  };
    *{"$pkg\::edgeset"}  = sub { goto &edgeset  };
    *{"$pkg\::global"}   = sub { goto &global   };
    *{"$pkg\::rank"}     = sub { goto &rank     };
    *{"$pkg\::name"}     = sub { goto &name     };
    *{"$pkg\::type"}     = sub { goto &type     };
    *{"$pkg\::subgraph"} = (sub { sub (&) { goto &subgraph } })->();
    *{"$pkg\::multi_route"} = sub { goto &multi_route };
}

sub _new {
    my ($class, %args) = @_;

    my $name = delete $args{name} || 'G';
    my $type = delete $args{type} || 'digraph';

    bless {
        name        => $name,
        type        => $type,
        edges       => [],
        nodes       => [],
        gnode_attrs => [],
        gedge_attrs => [],
        graph_attrs => [],
        subgraphs   => [],
        ranks       => [],
        objects     => [],
    }, $class;
}

sub _build_nodes {
    my $self = shift;

    sub {
        $self->_nodes;
    };
}

sub _build_graph {
    my ($subgraph) = @_;

    sub (&) {
        my $code = shift;

        my $graph = defined $subgraph ? $subgraph : Graphviz::DSL::Graph->new();

        no warnings 'redefine';

        my $add_code = sub { $graph->add(@_) };

        local *add      = \&$add_code;
        local *route    = \&$add_code;
        local *node     = sub { $graph->node(@_) };
        local *edge     = sub { $graph->edge(@_) };
        local *nodes    = sub { $graph->update_attrs('gnode_attrs', @_) };
        local *edges    = sub { $graph->update_attrs('gedge_attrs', @_) };
        local *nodeset  = sub { @{$graph->{nodes}} };
        local *edgeset  = sub { @{$graph->{edges}} };
        local *global   = sub { $graph->update_attrs('graph_attrs', @_) };
        local *rank     = sub { $graph->rank(@_) };
        local *name     = sub { $graph->name(@_) };
        local *type     = sub { $graph->type(@_) };
        local *subgraph = _build_subgraph($graph);
        local *multi_route = sub { $graph->multi_route(@_) };

        local $Carp::CarpLevel = $Carp::CarpLevel + 1;

        $code->();
        $graph;
    }
}

sub _build_subgraph {
    my $parent = shift;

    sub (&) {
        my $code = shift;
        my $num  = scalar @{$parent->{subgraphs}};

        my $self = Graphviz::DSL::Graph->new(
            id       => "cluster${num}",
            type     => $parent->{type},
            subgraph => 1,
        );
        my $graph = _build_graph($self);

        my $subgraph = $graph->($code);
        push @{$parent->{subgraphs}}, $subgraph;
        push @{$parent->{objects}}, $subgraph;
    };
}

sub __stub {
    my $func = shift;
    return sub {
        Carp::croak "Can't call $func() outside graph block";
    };
}

*route    = __stub 'route';
*add      = __stub 'add';
*node     = __stub 'node';
*edge     = __stub 'edge';
*nodes    = __stub 'nodes';
*edges    = __stub 'edges';
*nodeset  = __stub 'nodeset';
*edgeset  = __stub 'edgeset';
*global   = __stub 'global';
*rank     = __stub 'rank';
*subgraph = __stub 'subgraph';
*name     = __stub 'name';
*type     = __stub 'type';
*multi_route = __stub 'multi_route';

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Graphviz::DSL - Graphviz Perl interface with DSL

=head1 SYNOPSIS

  use Graphviz::DSL;

  my $graph = graph {
      name 'Sample';

      route main => [qw/init parse cleanup printf/];
      route init => 'make', parse => 'execute';
      route execute => [qw/make compare printf /];

      nodes colorscheme => 'piyg8', style => 'filled';

      my $index = 1;
      for my $n ( nodeset() ) {
          node($n->id, fillcolor => $index++);
      }

      edges arrowhead => 'onormal', color => 'magenta4';
      edge ['main' => 'printf'], arrowtail => 'diamond', color => '#3355FF';
      global bgcolor => 'white';

      node 'execute', shape => 'Mrecord',
                      label => '{<x>execute | {a | b | c}}';
      node 'printf',  shape => 'Mrecord',
                      label => '{printf |<y> format}';

      edge ['execute:x' => 'printf:y'];
      rank 'same', 'cleanup', 'execute';

      subgraph {
          global label => 'SUB';
          node 'init';
          node 'make';
      };

      subgraph {
          global label => 'SUB2';
          multi_route +{
              'a' => [qw/b c d/],
              'd' => 'e',
              'f' => {
                  'g' => { 'h' => 'i'},
                  'j' => 'k',
              },
          };
     };
  };

  $graph->save(path => 'output', type => 'png', encoding => 'utf-8');

=head1 DESCRIPTION

Graphviz::DSL is Perl version of Ruby gem I<Gviz>. This module provide
DSL for generating DOT file(and image if you install Graphviz dot command).
Outputted DOT file may be similar to your DSL, because Graphviz::DSL try to
keep objects order in DSL(Order of objects in DSL is very important. If you
change some objects order, then output image may be changed).

=head1 INTERFACES

=head2 Method in DSL

=head3 C<< name $name >>

Set C<$name> as graph name. Default is 'G'.

=head3 C<< type $type >>

Set C<$type> as graph type. C<$type> should be digraph(directed graph)
or graph(undirected graph). Default is 'digraph'.

=head3 C<< add, route >>

Add nodes and them edges. C<route> is alias of C<add> function.
You can call these methods like following.

=over

=item C<< add $nodes >>

Add C<$nodes> to this graph. C<$nodes> should be Scalar or ArrayRef.

=item C<< add $node1, \@edges1, $node2, \@edges2 ... >>

Add nodes and edges. C<$noden> should be Scalar or ArrayRef.
For example:

    add [qw/a b/], [qw/c d/]

Add node I<a> and I<b> and add edge a->c, a->d, b->c, b->d.

=back

=head3 C<< multi_route(\%routes]) >>

Add multiple routes at once.

    multi_route +{
        a => [qw/b c/],
        d => 'e',
        f => {
            g => { h => 'i'},
            j => 'k',
        },
    };

equals to following:

    route a => 'b', a => 'c';
    route d => 'e';
    route f => 'g', f => 'j';
    route g => 'h';
    route h => 'i';
    route j => 'k';

=head3 C<< node($node_id, [%attributes]) >>

Add node or update attribute of specified node.

=head3 C<< edge($edge_id, [%attributes]) >>

Add edge or update attribute of specified edge.

=head3 C<< nodes(%attributes) >>

Update attribute of all nodes.

=head3 C<< edges(%attributes) >>

Update attribute of all edges.

=head3 C<< nodeset >>

Return registered nodes.

=head3 C<< edgeset >>

Return registered edges.

=head3 C<< global >>

Update graph attribute.

=head3 C<< rank >>

Set rank.

=head3 C<< subgraph($coderef) >>

Create subgraph.

=head2 Class Method

=head3 C<< $graph->save(%args) >>

Save graph as DOT file.

C<%args> is:

=over

=item path

Basename of output file.

=item type

Output image type, such as I<png>, I<gif>, if you install Graphviz(dot command).
If I<dot> command is not found, it generate only dot file.
C<Graphviz::DSL> don't output image if you omit this attribute.

=item encoding

Encoding of output DOT file. Default is I<utf-8>.

=back

=head3 C<< $graph->as_string >>

Return DOT file as string. This is same as stringify itself.
Graphviz::DSL overload stringify operation.

=head1 SEE ALSO

Gviz L<https://github.com/melborne/Gviz>

Graphviz L<http://www.graphviz.org/>

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
