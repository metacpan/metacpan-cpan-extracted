# NAME

[GraphViz2::Parse::XML](https://metacpan.org/pod/GraphViz2::Parse::XML) - Visualize XML as a graph

# Synopsis

        #!/usr/bin/env perl

        use strict;
        use warnings;

        use File::Spec;

        use GraphViz2;
        use GraphViz2::Parse::XML;

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

        my($graph) = GraphViz2 -> new
                (
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {rankdir => 'TB'},
                 logger => $logger,
                 node   => {color => 'blue', shape => 'oval'},
                );
        my($g) = GraphViz2::Parse::XML -> new(graph => $graph);

        $g -> create(file_name => File::Spec -> catfile('t', 'sample.xml') );

        my($format)      = shift || 'svg';
        my($output_file) = shift || File::Spec -> catfile('html', "parse.xml.pp.$format");

        $graph -> run(format => $format, output_file => $output_file);

See scripts/parse.xml.pp.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)).

# Description

Takes an XML file and converts it into a graph, using the pure-Perl XML::Tiny.

You can write the result in any format supported by [Graphviz](http://www.graphviz.org/).

Here is the list of [output formats](http://www.graphviz.org/content/output-formats).

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2::Parse::XML -> new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2::Parse::XML`.

Key-value pairs accepted in the parameter list:

- o graph => $graphviz\_object

    This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

    The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
    except for the logger of course, which defaults to ''.

    This key is optional.

# Methods

## create(file\_name => $file\_name)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to new().

Returns $self for method chaining.

$file\_name is the name of an XML file.

## graph()

Returns the graph object, either the one supplied to new() or the one created during the call to new().

# FAQ

See ["FAQ" in GraphViz2](https://metacpan.org/pod/GraphViz2#FAQ) and ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module).

# Scripts Shipped with this Module

## scripts/parse.xml.pp.pl

Demonstrates using [XML::Tiny](https://metacpan.org/pod/XML::Tiny) to parse XML.

Inputs from ./t/sample.xml, and outputs to ./html/parse.xml.pp.svg by default.

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
