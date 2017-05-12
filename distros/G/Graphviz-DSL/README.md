# NAME

Graphviz::DSL - Graphviz Perl interface with DSL

# SYNOPSIS

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

# DESCRIPTION

Graphviz::DSL is Perl version of Ruby gem _Gviz_. This module provide
DSL for generating DOT file(and image if you install Graphviz dot command).
Outputted DOT file may be similar to your DSL, because Graphviz::DSL try to
keep objects order in DSL(Order of objects in DSL is very important. If you
change some objects order, then output image may be changed).

# INTERFACES

## Method in DSL

### `name $name`

Set `$name` as graph name. Default is 'G'.

### `type $type`

Set `$type` as graph type. `$type` should be digraph(directed graph)
or graph(undirected graph). Default is 'digraph'.

### `add, route`

Add nodes and them edges. `route` is alias of `add` function.
You can call these methods like following.

- `add $nodes`

    Add `$nodes` to this graph. `$nodes` should be Scalar or ArrayRef.

- `add $node1, \@edges1, $node2, \@edges2 ...`

    Add nodes and edges. `$noden` should be Scalar or ArrayRef.
    For example:

        add [qw/a b/], [qw/c d/]

    Add node _a_ and _b_ and add edge a->c, a->d, b->c, b->d.

### `multi_route(\%routes])`

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

### `node($node_id, [%attributes])`

Add node or update attribute of specified node.

### `edge($edge_id, [%attributes])`

Add edge or update attribute of specified edge.

### `nodes(%attributes)`

Update attribute of all nodes.

### `edges(%attributes)`

Update attribute of all edges.

### `nodeset`

Return registered nodes.

### `edgeset`

Return registered edges.

### `global`

Update graph attribute.

### `rank`

Set rank.

### `subgraph($coderef)`

Create subgraph.

## Class Method

### `$graph->save(%args)`

Save graph as DOT file.

`%args` is:

- path

    Basename of output file.

- type

    Output image type, such as _png_, _gif_, if you install Graphviz(dot command).
    If _dot_ command is not found, it generate only dot file.
    `Graphviz::DSL` don't output image if you omit this attribute.

- encoding

    Encoding of output DOT file. Default is _utf-8_.

### `$graph->as_string`

Return DOT file as string. This is same as stringify itself.
Graphviz::DSL overload stringify operation.

# SEE ALSO

Gviz [https://github.com/melborne/Gviz](https://github.com/melborne/Gviz)

Graphviz [http://www.graphviz.org/](http://www.graphviz.org/)

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2013- Syohei YOSHIDA

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
