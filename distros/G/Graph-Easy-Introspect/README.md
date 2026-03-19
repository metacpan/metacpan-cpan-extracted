# Graph::Easy::Introspect

Introspection and AST extraction for [Graph::Easy](https://metacpan.org/pod/Graph::Easy) layouts.

[Graph::Easy manual](http://bloodgate.com/perl/graph/manual/index.html)

## Overview

This module adds a single method, `ast`, to `Graph::Easy`. It returns a complete,
self-contained data structure describing every node, routed edge, group, and a rendered grid.

The AST is suitable for direct use, JSON serialization, or consumption by a renderer such as
[Asciio](https://github.com/nkh/P5-App-Asciio).

## Synopsis

```perl
use Graph::Easy;
use Graph::Easy::Parser::Graphviz;
use Graph::Easy::Introspect;

my $parser = Graph::Easy::Parser::Graphviz->new;
my $g      = $parser->from_text('digraph { A -> B -> C }');

my $ast = $g->ast;

for my $node (@{ $ast->{nodes} }) {
    printf "%s at (%d, %d) size %dx%d\n",
        $node->{id}, $node->{x}, $node->{y},
        $node->{width}, $node->{height};
}

for my $edge (@{ $ast->{edges} }) {
    printf "%s -> %s  arrow=%s\n",
        $edge->{from}, $edge->{to}, $edge->{arrow_dir} // 'none';
}

```

## AST top-level keys

- version — module version string
- meta    — generation metadata: versions, timestamp, layout algorithm
- graph   — graph-level info: directedness, dimensions, attributes
- nodes   — arrayref of node entries, sorted by id
- edges   — arrayref of edge entries, sorted by from/to
- groups  — arrayref of group entries, sorted by id
- grid    — 2D arrayref of characters from the ASCII rendering

See *doc/ARCHITECTURE.md* for the full schema and *doc/TRAVERSAL.md* for traversal patterns.

See *graph_easy_renderer* and */lib/Graph/Easy/Introspect/Renderer.pm* to get started with your own renderer.

## Scripts

### graph_easy_introspect

Prints a human-readable orJSON AST

```text
Usage: graph_easy_introspect [options] file.dot

Output format:
  --compact     suppress port and path detail; show only edge endpoints
  --dtd         emit the AST in a format easier to read, via Data::TreeDumper
  --json        emit the AST as JSON

Supplementary data (text mode: printed as sections; json/dtd: included in dump):
  --grid        include the rendered character grid
  --cell-grid   include the cell-grid lookup table

  --help        show this message
```

### graph_easy_render_ascii

Prints the ASCII grid from the AST

## Installation

```
perl Build.PL
./Build
./Build test
./Build install
```

## Repository

https://github.com/nkh/P5-Graph-Easy-Introspect

## Author

    Khemir Nadim ibn Hamouda
    https://github.com/nkh
    CPAN ID: NKH

## License

Same terms as Perl itself.
