# NAME

[GraphViz2::Parse::ISA](https://metacpan.org/pod/GraphViz2::Parse::ISA) - Visualize N Perl class hierarchies as a graph

# SYNOPSIS

        use strict;
        use warnings;
        use File::Spec;
        use GraphViz2::Parse::ISA;

        my $parser = GraphViz2::Parse::ISA->new;
        unshift @INC, 't/lib';
        $parser->add(class => 'Adult::Child::Grandchild', ignore => []);
        $parser->add(class => 'HybridVariety', ignore => []);
        $parser->generate_graph;

        my $format      = shift || 'svg';
        my $output_file = shift || "parse.code.$format";

        $parser->graph->run(format => $format, output_file => $output_file);

See scripts/parse.isa.pl.

# DESCRIPTION

Takes a class name and converts its class hierarchy into a graph. This can be done for N different classes before the graph is generated.

You can write the result in any format supported by [Graphviz](http://www.graphviz.org/).

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2::Parse::ISA->new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2::Parse::ISA`.

Key-value pairs accepted in the parameter list:

- o graph => $graphviz\_object

    This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

    The default is GraphViz2->new. The default attributes are the same as
    in the synopsis, above.
    The default for [GraphViz2::Parse::ISA](https://metacpan.org/pod/GraphViz2::Parse::ISA) is to plot from the bottom to
    the top (Grandchild to Parent).  This is the opposite of [GraphViz2](https://metacpan.org/pod/GraphViz2).

    This key is optional.

# METHODS

## add(class => $class\[, ignore => $ignore\])

Adds the class hierarchy of $class to an internal structure.

$class is the name of the class whose parents are to be found.

$ignore is an optional arrayref of class names to ignore. The value of $ignore is _not_ preserved between calls to add().

After all desired calls to add(), you _must_ call ["generate\_graph()"](#generate_graph) to actually trigger the call to the [GraphViz2](https://metacpan.org/pod/GraphViz2) methods add\_node() and add\_edge().

Returns $self for method chaining.

See scripts/parse.isa.pl.

## generate\_graph()

Processes the internal structure mentioned under add() to add all the nodes and edges to the graph.

After that you call [GraphViz2](https://metacpan.org/pod/GraphViz2)'s run() method on the graph object. See ["graph()"](#graph).

Returns $self for method chaining.

See scripts/parse.isa.pl.

## graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

# Scripts Shipped with this Module

## scripts/parse.isa.pl

Demonstrates combining 2 Perl class hierarchies on the same graph.

Outputs to ./html/parse.isa.svg by default. Change this by providing a
format argument (e.g. `svg`) and a filename argument.

# THANKS

Many thanks are due to the people who chose to make [Graphviz](http://www.graphviz.org/) Open Source.

And thanks to [Leon Brocard](http://search.cpan.org/~lbrocard/), who wrote [GraphViz](https://metacpan.org/pod/GraphViz), and kindly gave me co-maint of the module.

The code in add() was adapted from [GraphViz::ISA::Multi](https://metacpan.org/pod/GraphViz::ISA::Multi) by Marcus Thiesen, but that code gobbled up package declarations
in comments and POD, so I used [Pod::Simple](https://metacpan.org/pod/Pod::Simple) to give me just the source code.

# AUTHOR

[GraphViz2](https://metacpan.org/pod/GraphViz2) was written by Ron Savage _<ron@savage.net.au>_ in 2011.

Home page: [http://savage.net.au/index.html](http://savage.net.au/index.html).

# COPYRIGHT

Australian copyright (c) 2011, Ron Savage.

        All Programs of mine are 'OSI Certified Open Source Software';
        you can redistribute them and/or modify them under the terms of
        The Perl License, a copy of which is available at:
        http://dev.perl.org/licenses/
