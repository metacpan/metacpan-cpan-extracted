# NAME

[GraphViz2::Parse::RecDescent](https://metacpan.org/pod/GraphViz2::Parse::RecDescent) - Visualize a Parse::RecDescent grammar as a graph

# Synopsis

        #!/usr/bin/env perl

        use strict;
        use warnings;

        use File::Spec;

        use GraphViz2;
        use GraphViz2::Parse::RecDescent;

        use Parse::RecDescent;

        use File::Slurp; # For read_file().

        my($graph) = GraphViz2 -> new
                (
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {rankdir => 'TB'},
                 node   => {color => 'blue', shape => 'oval'},
                );
        my($g)      = GraphViz2::Parse::RecDescent -> new(graph => $graph);
        my $grammar = read_file(File::Spec -> catfile('t', 'sample.recdescent.1.dat') );
        my($parser) = Parse::RecDescent -> new($grammar);

        $g -> create(name => 'Grammar', grammar => $parser);

        my($format)      = shift || 'svg';
        my($output_file) = shift || File::Spec -> catfile('html', "parse.recdescent.$format");

        $graph -> run(format => $format, output_file => $output_file);

See scripts/parse.recdescent.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)).

# Description

Takes a [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent) grammar and converts it into a graph.

You can write the result in any format supported by [Graphviz](http://www.graphviz.org/).

Here is the list of [output formats](http://www.graphviz.org/content/output-formats).

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2::Parse::RecDescent -> new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2::Parse::RecDescent`.

Key-value pairs accepted in the parameter list:

- o graph => $graphviz\_object

    This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

    The default is GraphViz2->new. The default attributes are the same as in the synopsis, above.

    This key is optional.

# Methods

## create(name => $name, grammar => $grammar)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self for method chaining.

$name is the string which will be placed in the root node of the tree.

$grammar is either a [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent) object or a grammar. If it's a grammar, the code will
fabricate an object of type [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent).

## graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

# Scripts Shipped with this Module

## scripts/parse.recdescent.pl

Demonstrates graphing a [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent)-style grammar.

Inputs from t/sample.recdescent.1.dat and outputs to ./html/parse.recdescent.svg by default.

The input grammar was extracted from t/basics.t in [Parse::RecDescent](https://metacpan.org/pod/Parse::RecDescent) V 1.965001.

You can patch the \*.pl to read from t/sample.recdescent.2.dat, which was copied from [a V 2 bug report](https://rt.cpan.org/Ticket/Display.html?id=36057).

# Thanks

Many thanks are due to the people who chose to make [Graphviz](http://www.graphviz.org/) Open Source.

And thanks to [Leon Brocard](http://search.cpan.org/~lbrocard/), who wrote [GraphViz](https://metacpan.org/pod/GraphViz), and kindly gave me co-maint of the module.

# Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

# Machine-Readable Change Log

The file Changes was converted into Changelog.ini by [Module::Metadata::Changes](https://metacpan.org/pod/Module::Metadata::Changes).

# Support

Email the author, or log a bug on RT:

[https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2](https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2).

# Author

[GraphViz2](https://metacpan.org/pod/GraphViz2) was written by Ron Savage _<ron@savage.net.au>_ in 2011.

Home page: [http://savage.net.au/index.html](http://savage.net.au/index.html).

# Copyright

Australian copyright (c) 2011, Ron Savage.

        All Programs of mine are 'OSI Certified Open Source Software';
        you can redistribute them and/or modify them under the terms of
        The Perl License, a copy of which is available at:
        http://dev.perl.org/licenses/
