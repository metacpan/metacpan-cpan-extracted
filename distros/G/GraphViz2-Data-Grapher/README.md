# NAME

[GraphViz2::Data::Grapher](https://metacpan.org/pod/GraphViz2::Data::Grapher) - Visualize a data structure as a graph

# Synopsis

        #!/usr/bin/env perl

        use strict;
        use warnings;

        use File::Spec;

        use GraphViz2;
        use GraphViz2::Data::Grapher;

        use Log::Handler;

        # ------------------------------------------------

        my($logger) = Log::Handler -> new;

        $logger -> add
                (
                 screen =>
                 {
                         maxlevel       => 'debug',
                         message_layout => '%m',
                         minlevel       => 'error',
                 }
                );

        my($sub) = sub{};
        my($s)   =
        {
                A =>
                {
                        a =>
                        {
                        },
                        bbbbbb => $sub,
                        c123   => $sub,
                        d      => \$sub,
                },
                C =>
                {
                        b =>
                        {
                                a =>
                                {
                                        a =>
                                        {
                                        },
                                        b => sub{},
                                        c => 42,
                                },
                        },
                },
                els => [qw(element_1 element_2 element_3)],
        };

        my($graph) = GraphViz2 -> new
                (
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {rankdir => 'TB'},
                 logger => $logger,
                 node   => {color => 'blue', shape => 'oval'},
                );

        my($g)           = GraphViz2::Data::Grapher -> new(graph => $graph, logger => $logger);
        my($format)      = shift || 'svg';
        my($output_file) = shift || File::Spec -> catfile('html', "parse.data.$format");

        $g -> create(name => 's', thing => $s);
        $graph -> run(format => $format, output_file => $output_file);

        # If you did not provide a GraphViz2 object, do this
        # to get access to the auto-created GraphViz2 object.

        #$g -> create(name => 's', thing => $s);
        #$g -> graph -> run(format => $format, output_file => $output_file);

        # Or even

        #$g -> create(name => 's', thing => $s)
        #-> graph
        #-> run(format => $format, output_file => $output_file);

See scripts/parse.data.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)).

# Description

Takes a Perl data structure and recursively converts it into [Tree::DAG\_Node](https://metacpan.org/pod/Tree::DAG_Node) object, and then graphs it.

You can write the result in any format supported by [Graphviz](http://www.graphviz.org/).

Here is the list of [output formats](http://www.graphviz.org/content/output-formats).

Within the graph:

- o Array names are preceeded by '@'
- o Code references are preceeded by '&'
- o Hash names are preceeded by '%'
- o Scalar names are preceeded by '$'

Hence, a hash ref will look like '%$h'.

Further, objects of different type have different shapes.

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2::Data::Grapher -> new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2::Data::Grapher`.

Key-value pairs accepted in the parameter list:

- o graph => $graphviz\_object

    This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

    The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
    except for the graph label of course.

    This key is optional.

- o logger => $logger\_object

    Provides a logger object so $logger\_object -> $level($message) can be called at certain times.

    Retrieve and update the value with the logger() method.

    The default is ''.

    At the moment, the logger object is not used. This feature is mainly used for testing.

# Methods

## create(name => $name, thing => $thing)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self to allow method chaining.

$name is the string which will be placed in the root node of the tree.

If $s = {...}, say, use 's', not '$s', because '%$' will be prefixed automatically to the name,
because $s is a hashref.

$thing is the data stucture to graph.

## graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

## tree()

Returns the tree object (of type [Tree::DAG\_Node](https://metacpan.org/pod/Tree::DAG_Node)) built before it is traversed to generate the nodes and edges.

Traversal does change the attributes of nodes, by storing {record => $string} there, so that
edges can be plotted from a parent to its daughters.

Warning: As the [GraphViz2::Data::Grapher](https://metacpan.org/pod/GraphViz2::Data::Grapher) object exits its scope, $self -> tree -> delete\_tree is called.

# Scripts Shipped with this Module

## scripts/parse.data.pl

Demonstrates graphing a Perl data structure.

Outputs to ./html/parse.data.svg by default.

## scripts/parse.html.pl

Demonstrates using [XML::Bare](https://metacpan.org/pod/XML::Bare) to parse HTML.

Inputs from ./t/sample.html, and outputs to ./html/parse.html.svg by default.

## scripts/parse.xml.bare.pl

Demonstrates using [XML::Bare](https://metacpan.org/pod/XML::Bare) to parse XML.

Inputs from ./t/sample.xml, and outputs to ./html/parse.xml.bare.svg by default.

# Thanks

Many thanks are due to the people who chose to make [Graphviz](http://www.graphviz.org/) Open Source.

And thanks to [Leon Brocard](http://search.cpan.org/~lbrocard/), who wrote [GraphViz](https://metacpan.org/pod/GraphViz), and kindly gave me co-maint of the module.

# Author

[GraphViz2](https://metacpan.org/pod/GraphViz2) was written by Ron Savage _<ron@savage.net.au>_ in 2011.

Home page: [http://savage.net.au/index.html](http://savage.net.au/index.html).

# Copyright

Australian copyright (c) 2011, Ron Savage.

        All Programs of mine are 'OSI Certified Open Source Software';
        you can redistribute them and/or modify them under the terms of
        The Perl License, a copy of which is available at:
        http://dev.perl.org/licenses/
