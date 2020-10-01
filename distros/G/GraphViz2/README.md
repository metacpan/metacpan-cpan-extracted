# NAME

GraphViz2 - A wrapper for AT&T's Graphviz

# Synopsis

## Sample output

Unpack the distro and copy html/\*.html and html/\*.svg to your web server's doc root directory.

Then, point your browser at 127.0.0.1/index.html.

Or, hit [the demo page](http://savage.net.au/Perl-modules/html/graphviz2/index.html).

## Perl code

### Typical Usage

        #!/usr/bin/env perl

        use strict;
        use warnings;

        use File::Spec;

        use GraphViz2;

        use Log::Handler;

        # ---------------

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
                 graph  => {label => 'Adult', rankdir => 'TB'},
                 logger => $logger,
                 node   => {shape => 'oval'},
                );

        $graph -> add_node(name => 'Carnegie', shape => 'circle');
        $graph -> add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
        $graph -> add_node(name => 'Oakleigh',    color => 'blue');

        $graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
        $graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

        $graph -> push_subgraph
        (
         name  => 'cluster_1',
         graph => {label => 'Child'},
         node  => {color => 'magenta', shape => 'diamond'},
        );

        $graph -> add_node(name => 'Chadstone', shape => 'hexagon');
        $graph -> add_node(name => 'Waverley', color => 'orange');

        $graph -> add_edge(from => 'Chadstone', to => 'Waverley');

        $graph -> pop_subgraph;

        $graph -> default_node(color => 'cyan');

        $graph -> add_node(name => 'Malvern');
        $graph -> add_node(name => 'Prahran', shape => 'trapezium');

        $graph -> add_edge(from => 'Malvern', to => 'Prahran');
        $graph -> add_edge(from => 'Malvern', to => 'Murrumbeena');

        my($format)      = shift || 'svg';
        my($output_file) = shift || File::Spec -> catfile('html', "sub.graph.$format");

        $graph -> run(format => $format, output_file => $output_file);

This program ships as scripts/sub.graph.pl. See ["Scripts Shipped with this Module"](#scripts-shipped-with-this-module).

### Image Maps Usage

As of V 2.43, `GraphViz2` supports image maps, both client and server side.

See ["Image Maps"](#image-maps) below.

# Description

## Overview

This module provides a Perl interface to the amazing [Graphviz](http://www.graphviz.org/), an open source graph visualization tool from AT&T.

It is called GraphViz2 so that pre-existing code using (the Perl module) GraphViz continues to work.

To avoid confusion, when I use [GraphViz2](https://metacpan.org/pod/GraphViz2) (note the capital V), I'm referring to this Perl module, and
when I use [Graphviz](http://www.graphviz.org/) (lower-case v) I'm referring to the underlying tool (which is in fact a set of programs).

Version 1.00 of [GraphViz2](https://metacpan.org/pod/GraphViz2) is a complete re-write, by Ron Savage, of GraphViz V 2, which was written by Leon Brocard. The point of the re-write
is to provide access to all the latest options available to users of [Graphviz](http://www.graphviz.org/).

GraphViz2 V 1 is not backwards compatible with GraphViz V 2, despite the considerable similarity. It was not possible to maintain compatibility
while extending support to all the latest features of [Graphviz](http://www.graphviz.org/).

To ensure [GraphViz2](https://metacpan.org/pod/GraphViz2) is a light-weight module, [Moo](https://metacpan.org/pod/Moo) has been used to provide getters and setters,
rather than [Moose](https://metacpan.org/pod/Moose).

As of V 2.43, `GraphViz2` supports image maps, both client and server side.

See ["Image Maps"](#image-maps) below.

## What is a Graph?

An undirected graph is a collection of nodes optionally linked together with edges.

A directed graph is the same, except that the edges have a direction, normally indicated by an arrow head.

A quick inspection of [Graphviz](http://www.graphviz.org/)'s [gallery](http://www.graphviz.org/gallery/) will show better than words
just how good [Graphviz](http://www.graphviz.org/) is, and will reinforce the point that humans are very visual creatures.

# Installation

Of course you need to install AT&T's Graphviz before using this module.
See [http://www.graphviz.org/download/](http://www.graphviz.org/download/).

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2 -> new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2`.

Key-value pairs accepted in the parameter list:

- o edge => $hashref

    The _edge_ key points to a hashref which is used to set default attributes for edges.

    Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

    The default is {}.

    This key is optional.

- o global => $hashref

    The _global_ key points to a hashref which is used to set attributes for the output stream.

    Valid keys within this hashref are:

    - o directed => $Boolean

        This option affects the content of the output stream.

        directed => 1 outputs 'digraph name {...}', while directed => 0 outputs 'graph name {...}'.

        At the Perl level, directed graphs have edges with arrow heads, such as '->', while undirected graphs have
        unadorned edges, such as '--'.

        The default is 0.

        This key is optional.

    - o driver => $program\_name

        This option specifies which external program to run to process the output stream.

        The default is to use [File::Which](https://metacpan.org/pod/File::Which)'s which() method to find the 'dot' program.

        This key is optional.

    - o format => $string

        This option specifies what type of output file to create.

        The default is 'svg'.

        Output formats of the form 'png:gd' etc are also supported, but only the component before
        the first ':' is validated by [GraphViz2](https://metacpan.org/pod/GraphViz2).

        This key is optional.

    - o label => $string

        This option specifies what an edge looks like: '->' for directed graphs and '--' for undirected graphs.

        You wouldn't normally need to use this option.

        The default is '->' if directed is 1, and '--' if directed is 0.

        This key is optional.

    - o name => $string

        This option affects the content of the output stream.

        name => 'G666' outputs 'digraph G666 {...}'.

        The default is 'Perl' :-).

        This key is optional.

    - o record\_shape => /^(?:M?record)$/

        This option affects the shape of records. The value must be 'Mrecord' or 'record'.

        Mrecords have nice, rounded corners, whereas plain old records have square corners.

        The default is 'Mrecord'.

        See [Record shapes](http://www.graphviz.org/doc/info/shapes.html#record) for details.

    - o strict => $Boolean

        This option affects the content of the output stream.

        strict => 1 outputs 'strict digraph name {...}', while strict => 0 outputs 'digraph name {...}'.

        The default is 0.

        This key is optional.

    - o subgraph => $hashref

        The _subgraph_ key points to a hashref which is used to set attributes for all subgraphs, unless overridden
        for specific subgraphs in a call of the form push\_subgraph(subgraph => {$attribute => $string}).

        Valid keys within this hashref are:

        - o rank => $string

            This option affects the content of all subgraphs, unless overridden later.

            A typical usage would be new(subgraph => {rank => 'same'}) so that all nodes mentioned within each subgraph
            are constrained to be horizontally aligned.

            See scripts/rank.sub.graph.\[12\].pl for sample code.

            Possible values for $string are: max, min, same, sink and source.

            See the [Graphviz 'rank' docs](http://www.graphviz.org/doc/info/attrs.html#d:rank) for details.

        The default is {}.

        This key is optional.

    - o timeout => $integer

        This option specifies how long to wait for the external program before exiting with an error.

        The default is 10 (seconds).

        This key is optional.

    This key (global) is optional.

- o graph => $hashref

    The _graph_ key points to a hashref which is used to set default attributes for graphs.

    Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

    The default is {}.

    This key is optional.

- o logger => $logger\_object

    Provides a logger object so $logger\_object -> $level($message) can be called at certain times.

    See "Why such a different approach to logging?" in the &lt;/FAQ> for details.

    Retrieve and update the value with the logger() method.

    The default is ''.

    See also the verbose option, which can interact with the logger option.

    This key is optional.

- o node => $hashref

    The _node_ key points to a hashref which is used to set default attributes for nodes.

    Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

    The default is {}.

    This key is optional.

- o verbose => $Boolean

    Provides a way to control the amount of output when a logger is not specified.

    Setting verbose to 0 means print nothing.

    Setting verbose to 1 means print the log level and the message to STDOUT, when a logger is not specified.

    Retrieve and update the value with the verbose() method.

    The default is 0.

    See also the logger option, which can interact with the verbose option.

    This key is optional.

## Validating Parameters

The secondary keys (under the primary keys 'edge|graph|node') are checked against lists of valid attributes (stored at the end of this
module, after the \_\_DATA\_\_ token, and made available using [Data::Section::Simple](https://metacpan.org/pod/Data::Section::Simple)).

This mechanism has the effect of hard-coding [Graphviz](http://www.graphviz.org/) options in the source code of [GraphViz2](https://metacpan.org/pod/GraphViz2).

Nevertheless, the implementation of these lists is handled differently from the way it was done in V 2.

V 2 ships with a set of scripts, scripts/extract.\*.pl, which retrieve pages from the
[Graphviz](http://www.graphviz.org/) web site and extract the current lists of valid attributes.

These are then copied manually into the source code of [GraphViz2](https://metacpan.org/pod/GraphViz2), meaning any time those lists change on the
[Graphviz](http://www.graphviz.org/) web site, it's a trivial matter to update the lists stored within this module.

See ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module).

# Attribute Scope

## Graph Scope

The graphical elements graph, node and edge, have attributes. Attributes can be set when calling new().

Within new(), the defaults are graph => {}, node => {}, and edge => {}.

You override these with code such as new(edge => {color => 'red'}).

These attributes are pushed onto a scope stack during new()'s processing of its parameters, and they apply thereafter until changed.
They are the 'current' attributes. They live at scope level 0 (zero).

You change the 'current' attributes by calling any of the methods default\_edge(%hash), default\_graph(%hash) and default\_node(%hash).

See scripts/trivial.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)) for an example.

## Subgraph Scope

When you wish to create a subgraph, you call push\_subgraph(%hash). The word push emphasises that you are moving into a new scope,
and that the default attributes for the new scope are pushed onto the scope stack.

This module, as with [Graphviz](http://www.graphviz.org/), defaults to using inheritance of attributes.

That means the parent's 'current' attributes are combined with the parameters to push\_subgraph(%hash) to generate a new set of 'current'
attributes for each of the graphical elements, graph, node and edge.

After a single call to push\_subgraph(%hash), these 'current' attributes will live a level 1 in the scope stack.

See scripts/sub.graph.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)) for an example.

Another call to push\_subgraph(%hash), _without_ an intervening call to pop\_subgraph(), will repeat the process, leaving you with
a set of attributes at level 2 in the scope stack.

Both [GraphViz2](https://metacpan.org/pod/GraphViz2) and [Graphviz](http://www.graphviz.org/) handle this situation properly.

See scripts/sub.sub.graph.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)) for an example.

At the moment, due to design defects (IMHO) in the underlying [Graphviz](http://www.graphviz.org/) logic, there are some tiny problems with this:

- o A global frame

    I can't see how to make the graph as a whole (at level 0 in the scope stack) have a frame.

- o Frame color

    When you specify graph => {color => 'red'} at the parent level, the subgraph has a red frame.

    I think a subgraph should control its own frame.

- o Parent and child frames

    When you specify graph => {color => 'red'} at the subgraph level, both that subgraph and it children have red frames.

    This contradicts what happens at the global level, in that specifying color there does not given the whole graph a frame.

- o Frame visibility

    A subgraph whose name starts with 'cluster' is currently forced to have a frame, unless you rig it by specifying a
    color the same as the background.

    For sample code, see scripts/sub.graph.frames.pl.

Also, check [the pencolor docs](http://www.graphviz.org/doc/info/attrs.html#d:pencolor) for how the color of the frame is
chosen by cascading thru a set of options.

I've posted an email to the [Graphviz](http://www.graphviz.org/) mailing list suggesting a new option, framecolor, so deal with
this issue, including a special color of 'invisible'.

# Image Maps

As of V 2.43, `GraphViz2` supports image maps, both client and server side.

## The Default URL

See the [Graphviz docs for 'cmapx'](http://www.graphviz.org/doc/info/output.html#d:cmapx).

Their sample code has a dot file - x.gv - containing this line:

        URL="http://www.research.att.com/base.html";

The way you set such a url in `GraphViz2` is via a new parameter to `new()`. This parameter is called `im_meta`
and it takes a hashref as a value. Currently the only key used within that hashref is the case-sensitive `URL`.

Thus you must do this to set a URL:

        my($graph) = GraphViz2 -> new
                     (
                        ...
                        im_meta =>
                        {
                            URL => 'http://savage.net.au/maps/demo.3.1.html', # Note: URL must be in caps.
                        },
                     );

See maps/demo.3.pl and maps/demo.4.pl for sample code.

## Typical Code

Normally you would call `run()` as:

        $graph -> run
        (
            format      => $format,
            output_file => $output_file
        );

That line was copied from scripts/cluster.pl.

To trigger image map processing, you must include 2 new parameters:

        $graph -> run
        (
            format         => $format,
            output_file    => $output_file,
            im_format      => $im_format,
            im_output_file => $im_output_file
        );

That line was copied from maps/demo.3.pl, and there is an identical line in maps/demo.4.pl.

## The New Parameters to run()

- o im\_format => $str

    Expected values: 'imap' (server-side) and 'cmapx' (client-side).

    Default value: 'cmapx'.

- o im\_output\_file => $file\_name

    The name of the output map file.

    Default: ''.

## Sample Code

Various demos are shipped in the new maps/ directory:

Each demo, when FTPed to your web server displays some text with an image in the middle. In each case
you can click on the upper oval to jump to one page, or click on the lower oval to jump to a different
page, or click anywhere else in the image to jump to a third page.

- o demo.1.\*

    This set demonstrates a server-side image map but does not use `GraphViz2`.

    You have to run demo.1.sh which generates demo.1.map, and then you FTP the whole dir maps/ to your web server.

    URL: your.domain.name/maps/demo.1.html.

- o demo.2.\*

    This set demonstrates a client-side image map but does not use `GraphViz2`.

    You have to run demo.2.sh which generates demo.2.map, and then you manually copy demo.2.map into demo.2.html,
    replacing any version of the map already present. After that you FTP the whole dir maps/ to your web server.

    URL: your.domain.name/maps/demo.2.html.

- o demo.3.\*

    This set demonstrates a server-side image map using `GraphViz2` via demo.3.pl.

    Note line 54 of demo.3.pl which sets the default `im_format` to 'imap'.

    URL: your.domain.name/maps/demo.3.html.

- o demo.4.\*

    This set demonstrates a client-side image map using `GraphViz2` via demo.4.pl.

    As with demo.2.\* there is some manually editing to be done.

    Note line 54 of demo.4.pl which sets the default `im_format` to 'cmapx'. This is the only important
    difference between this demo and the previous one.

    There are other minor differences, in that one uses 'svg' and the other 'png'. And of course the urls
    of the web pages embedded in the code and in those web pages differs, just to demonstate that the maps
    do indeed lead to different pages.

    URL: your.domain.name/maps/demo.4.html.

# Methods

## add\_edge(from => $from\_node\_name, to => $to\_node\_name, \[label => $label, %hash\])

Adds an edge to the graph.

Returns $self to allow method chaining.

Here, \[\] indicate optional parameters.

Add a edge from 1 node to another.

$from\_node\_name and $to\_node\_name default to ''.

If either of these node names is unknown, add\_node(name => $node\_name) is called automatically. The lack of
attributes in this call means such nodes are created with the default set of attributes, and that may not
be what you want. To avoid this, you have to call add\_node(...) yourself, with the appropriate attributes,
before calling add\_edge(...).

%hash is any edge attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the edge parameters in the calls to
default\_edge(%hash), new(edge => {}) and push\_subgraph(edge => {}).

## add\_node(name => $node\_name, \[%hash\])

Adds a node to the graph.

Returns $self to allow method chaining.

If you want to embed newlines or double-quotes in node names or labels, see scripts/quote.pl in ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module).

If you want anonymous nodes, see scripts/anonymous.pl in ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module).

Here, \[\] indicates an optional parameter.

%hash is any node attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the node parameters in the calls to
default\_node(%hash), new(node => {}) and push\_subgraph(node => {}).

The attribute name 'label' may point to a string or an arrayref.

### If it is a string...

The string is the label.

The string may contain ports and orientation markers ({}).

### If it is an arrayref of strings...

- o The node is forced to be a record

    The actual shape, 'record' or 'Mrecord', is set globally, with:

            my($graph) = GraphViz2 -> new
            (
                    global => {record_shape => 'record'}, # Override default 'Mrecord'.
                    ...
            );

    Or set locally with:

            $graph -> add_node(name => 'Three', label => ['Good', 'Bad'], shape => 'record');

- o Each element in the array defines a field in the record

    These fields are combined into a single node

- o Each element is treated as a label
- o Each label is given a port name (1 .. N) of the form "port&lt;$port\_count>"
- o Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

### If it is an arrayref of hashrefs...

- o The node is forced to be a record

    The actual shape, 'record' or 'Mrecord', can be set globally or locally, as explained just above.

- o Each element in the array defines a field in the record
- o Each element is treated as a hashref with keys 'text' and 'port'

    The 'port' key is optional.

- o The value of the 'text' key is the label
- o The value of the 'port' key is the port

    The format is "&lt;$port\_name>".

- o Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

See scripts/html.labels.\*.pl and scripts/record.\*.pl for sample code.

See also the FAQ topic ["How labels interact with ports"](#how-labels-interact-with-ports).

For more details on this complex topic, see [Records](http://www.graphviz.org/doc/info/shapes.html#record) and [Ports](http://www.graphviz.org/doc/info/attrs.html#k:portPos).

## default\_edge(%hash)

Sets defaults attributes for edges added subsequently.

Returns $self to allow method chaining.

%hash is any edge attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the edge parameters in the calls to new(edge => {})
and push\_subgraph(edge => {}).

## default\_graph(%hash)

Sets defaults attributes for the graph.

Returns $self to allow method chaining.

%hash is any graph attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the graph parameter in the calls to new(graph => {})
and push\_subgraph(graph => {}).

## default\_node(%hash)

Sets defaults attributes for nodes added subsequently.

Returns $self to allow method chaining.

%hash is any node attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the node parameters in the calls to new(node => {})
and push\_subgraph(node => {}).

## default\_subgraph(%hash)

Sets defaults attributes for clusters and subgraphs.

Returns $self to allow method chaining.

%hash is any cluster or subgraph attribute accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the subgraph parameter in the calls to
new(subgraph => {}) and push\_subgraph(subgraph => {}).

## dot\_input()

Returns the output stream, formatted nicely, which was passed to the external program (e.g. dot).

You _must_ call run() before calling dot\_input(), since it is only during the call to run() that the output stream is
stored in the buffer controlled by dot\_input().

## dot\_output()

Returns the output from calling the external program (e.g. dot).

You _must_ call run() before calling dot\_output(), since it is only during the call to run() that the output of the
external program is stored in the buffer controlled by dot\_output().

This output is available even if run() does not write the output to a file.

## edge\_hash()

Returns, at the end of the run, a hashref keyed by node name, specifically the node at the arrow_tail_ end of
the hash, i.e. where the edge starts from.

Use this to get a list of all nodes and the edges which leave those nodes, the corresponding destination
nodes, and the attributes of each edge.

        my($node_hash) = $graph -> node_hash;
        my($edge_hash) = $graph -> edge_hash;

        for my $from (sort keys %$node_hash)
        {
                my($attr) = $$node_hash{$from}{attributes};
                my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

                print "Node: $from\n";
                print "\tAttributes: $s\n";

                for my $to (sort keys %{$$edge_hash{$from} })
                {
                        for my $edge (@{$$edge_hash{$from}{$to} })
                        {
                                $attr = $$edge{attributes};
                                $s    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

                                print "\tEdge: $from$$edge{from_port} -> $to$$edge{to_port}\n";
                                print "\t\tAttributes: $s\n";
                        }
                }
        }

If the caller adds the same edge two (or more) times, the attributes from each call are
_not_ coalesced (unlike ["node\_hash()"](#node_hash)), but rather the attributes from each call are stored separately
in an arrayref.

A bit more formally then, $$edge\_hash{$from\_node}{$to\_node} is an arrayref where each element describes
one edge, and which defaults to:

        {
                attributes => {},
                from_port  => $from_port,
                to_port    => $to_port,
        }

If _from\_port_ is not provided by the caller, it defaults to '' (the empty string). If it is provided,
it contains a leading ':'. Likewise for _to\_port_.

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example.

## escape\_some\_chars($s)

Escapes various chars in various circumstances, because some chars are treated specially by Graphviz.

See the ["FAQ"](#faq) for a discussion of this tricky topic.

## load\_valid\_attributes()

Load various sets of valid attributes from within the source code of this module, using [Data::Section::Simple](https://metacpan.org/pod/Data::Section::Simple).

Returns $self to allow method chaining.

These attributes are used to validate attributes in many situations.

You wouldn't normally need to use this method.

## log(\[$level, $message\])

Logs the message at the given log level.

Returns $self to allow method chaining.

Here, \[\] indicate optional parameters.

$level defaults to 'debug', and $message defaults to ''.

If called with $level eq 'error', it dies with $message.

## logger($logger\_object)

Gets or sets the log object.

Here, \[\] indicates an optional parameter.

## node\_hash()

Returns, at the end of the run, a hashref keyed by node name. Use this to get a list of all nodes
and their attributes.

        my($node_hash) = $graph -> node_hash;

        for my $name (sort keys %$node_hash)
        {
                my($attr) = $$node_hash{$name}{attributes};
                my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

                print "Node: $name\n";
                print "\tAttributes: $s\n";
        }

If the caller adds the same node two (or more) times, the attributes from each call are
_coalesced_ (unlike ["edge\_hash()"](#edge_hash)), meaning all attributes from all calls are combined under the
_attributes_ sub-key.

A bit more formally then, $$node\_hash{$node\_name} is a hashref where each element describes one node, and
which defaults to:

        {
                attributes => {},
        }

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example,
including usage of the corresponding ["edge\_hash()"](#edge_hash) method.

## pop\_subgraph()

Pop off and discard the top element of the scope stack.

Returns $self to allow method chaining.

## push\_subgraph(\[name => $name, edge => {...}, graph => {...}, node => {...}, subgraph => {...}\])

Sets up a new subgraph environment.

Returns $self to allow method chaining.

Here, \[\] indicate optional parameters.

name => $name is the name to assign to the subgraph. Name defaults to ''.

So, without $name, 'subgraph {' is written to the output stream.

With $name, 'subgraph "$name" {' is written to the output stream.

Note that subgraph names beginning with 'cluster' [are special to Graphviz](http://www.graphviz.org/doc/info/attrs.html#d:clusterrank).

See scripts/rank.sub.graph.\[1234\].pl for the effect of various values for $name.

edge => {...} is any edge attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the edge parameters in the calls to
default\_edge(%hash), new(edge => {}) and push\_subgraph(edge => {}).

graph => {...} is any graph attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the graph parameters in the calls to
default\_graph(%hash), new(graph => {}) and push\_subgraph(graph => {}).

node => {...} is any node attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the node parameters in the calls to
default\_node(%hash), new(node => {}) and push\_subgraph(node => {}).

subgraph => {..} is for setting attributes applicable to clusters and subgraphs.

Currently the only subgraph attribute is `rank`, but clusters have many attributes available.

See the second column of the
[Graphviz attribute docs](https://www.graphviz.org/doc/info/attrs.html) for details.

A typical usage would be push\_subgraph(subgraph => {rank => 'same'}) so that all nodes mentioned within the subgraph
are constrained to be horizontally aligned.

See scripts/rank.sub.graph.\[12\].pl and scripts/sub.graph.frames.pl for sample code.

## report\_valid\_attributes()

Prints all attributes known to this module.

Returns nothing.

You wouldn't normally need to use this method.

See scripts/report.valid.attributes.pl. See ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module).

## run(\[driver => $exe, format => $string, timeout => $integer, output\_file => $output\_file\])

Runs the given program to process the output stream.

Returns $self to allow method chaining.

Here, \[\] indicate optional parameters.

$driver is the name of the external program to run.

It defaults to the value supplied in the call to new(global => {driver => '...'}), which in turn defaults
to [File::Which](https://metacpan.org/pod/File::Which)'s which('dot') return value.

$format is the type of output file to write.

It defaults to the value supplied in the call to new(global => {format => '...'}), which in turn defaults
to 'svg'.

$timeout is the time in seconds to wait while the external program runs, before dieing with an error.

It defaults to the value supplied in the call to new(global => {timeout => '...'}), which in turn defaults
to 10.

$output\_file is the name of the file into which the output from the external program is written.

There is no default value for $output\_file. If a value is not supplied for $output\_file, the only way
to recover the output of the external program is to call dot\_output().

This method performs a series of tasks:

- o Formats the output stream
- o Stores the formatted output in a buffer controlled by the dot\_input() method
- o Output the output stream to a file
- o Run the chosen external program on that file
- o Capture STDOUT and STDERR from that program
- o Die if STDERR contains anything
- o Copies STDOUT to the buffer controlled by the dot\_output() method
- o Write the captured contents of STDOUT to $output\_file, if $output\_file has a value

## stringify\_attributes($context, $option)

Returns a string suitable to writing to the output stream.

$context is one of 'edge', 'graph', 'node', or a special string. See the code for details.

You wouldn't normally need to use this method.

## validate\_params($context, %attributes)

Validate the given attributes within the given context.

Also, if $context is 'subgraph', attributes are allowed to be in the 'cluster' context.

Returns $self to allow method chaining.

$context is one of 'edge', 'global', 'graph', 'node' or 'output\_format'.

You wouldn't normally need to use this method.

## verbose(\[$integer\])

Gets or sets the verbosity level, for when a logging object is not used.

Here, \[\] indicates an optional parameter.

# FAQ

## Which version of Graphviz do you use?

GraphViz2 targets V 2.34.0 of [Graphviz](http://www.graphviz.org/).

This affects the list of available attributes per graph item (node, edge, cluster, etc) available.

See the second column of the
[Graphviz attribute docs](https://www.graphviz.org/doc/info/attrs.html) for details.

See the next item for a discussion of the list of output formats.

## Where does the list of valid output formats come from?

Up to V 2.23, it came from downloading and parsing https://www.graphviz.org/doc/info/output.html. This was done
by scripts/extract.output.formats.pl.

Starting with V 2.24 it comes from parsing the output of 'dot -T?'. The problems avoided, and advantages, of this are:

- o I might forget to run the script after Graphviz is updated
- o The on-line docs might be out-of-date
- o dot output includes the formats supported by locally-installed plugins

## Why do I get error messages like the following?

        Error: <stdin>:1: syntax error near line 1
        context: digraph >>>  Graph <<<  {

Graphviz reserves some words as keywords, meaning they can't be used as an ID, e.g. for the name of the graph.
So, don't do this:

        strict graph graph{...}
        strict graph Graph{...}
        strict graph strict{...}
        etc...

Likewise for non-strict graphs, and digraphs. You can however add double-quotes around such reserved words:

        strict graph "graph"{...}

Even better, use a more meaningful name for your graph...

The keywords are: node, edge, graph, digraph, subgraph and strict. Compass points are not keywords.

See [keywords](https://www.graphviz.org/doc/info/lang.html) in the discussion of the syntax of DOT
for details.

## How do I include utf8 characters in labels?

Since V 2.00, [GraphViz2](https://metacpan.org/pod/GraphViz2) incorporates a sample which produce graphs such as [this](http://savage.net.au/Perl-modules/html/graphviz2/utf8.1.svg).

scripts/utf8.1.pl contains 'use utf8;' because of the utf8 characters embedded in the source code. You will need to do this.

## Why did you remove 'use utf8' from this file (in V 2.26)?

Because it is global, i.e. it applies to all code in your program, not just within this module.
Some modules you are using may not expect that. If you need it, just use it in your \*.pl script.

## Why do I get 'Wide character in print...' when outputting to PNG but not SVG?

As of V 2.02, you should not get this from GraphViz2. So, I suggest you study your own code very, very carefully :-(.

Examine the output from scripts/utf8.2.pl, i.e. html/utf8.2.svg and you'll see it's correct. Then run:

        perl scripts/utf8.2.pl png

and examine html/utf8.2.png and you'll see it matches html/utf8.2.svg in showing 5 deltas. So, I _think_ it's all working.

## How do I print output files?

Under Unix, output as PDF, and then try: lp -o fitplot html/parse.stt.pdf (or whatever).

## Can I include spaces and newlines in HTML labels?

Yes. The code removes leading and trailing whitespace on HTML labels before calling 'dot'.

Also, the code, and 'dot', both accept newlines embedded within such labels.

Together, these allow HTML labels to be formatted nicely in the calling code.

See [the Graphviz docs](https://www.graphviz.org/doc/info/shapes.html#record) for their discussion on whitespace.

## I'm having trouble with special characters in node names and labels

[GraphViz2](https://metacpan.org/pod/GraphViz2) escapes these 2 characters in those contexts: \[\].

Escaping the 2 chars \[\] started with V 2.10. Previously, all of \[\]{} were escaped, but {} are used in records
to control the orientation of fields, so they should not have been escaped in the first place.
See scripts/record.1.pl.

Double-quotes are escaped when the label is _not_ an HTML label. See scripts/html.labels.\*.pl for sample code.

It would be nice to also escape | and <, but these characters are used in specifying fields and ports in records.

See the next couple of points for details.

## A warning about [Graphviz](http://www.graphviz.org/) and ports

Ports are what [Graphviz](http://www.graphviz.org/) calls those places on the outline of a node where edges
leave and terminate.

The [Graphviz](http://www.graphviz.org/) syntax for ports is a bit unusual:

- o This works: "node\_name":port5
- o This doesn't: "node\_name:port5"

Let me repeat - that is Graphviz syntax, not GraphViz2 syntax. In Perl, you must do this:

        $graph -> add_edge(from => 'struct1:f1', to => 'struct2:f0', color => 'blue');

You don't have to quote all node names in [Graphviz](http://www.graphviz.org/), but some, such as digits, must be quoted, so I've decided to quote them all.

## How labels interact with ports

You can specify labels with ports in these ways:

- o As a string

    From scripts/record.1.pl:

            $graph -> add_node(name => 'struct3', label => "hello\nworld |{ b |{c|<here> d|e}| f}| g | h");

    Here, the string contains a port (&lt;here>), field markers (|), and orientation markers ({}).

    Clearly, you must specify the field separator character '|' explicitly. In the next 2 cases, it is implicit.

    Then you use $graph -> add\_edge(...) to refer to those ports, if desired. Again, from scripts/record.1.pl:

    $graph -> add\_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

    The same label is specified in the next case.

- o As an arrayref of hashrefs

    From scripts/record.2.pl:

            $graph -> add_node(name => 'struct3', label =>
            [
                    {
                            text => "hello\nworld",
                    },
                    {
                            text => '{b',
                    },
                    {
                            text => '{c',
                    },
                    {
                            port => '<here>',
                            text => 'd',
                    },
                    {
                            text => 'e}',
                    },
                    {
                            text => 'f}',
                    },
                    {
                            text => 'g',
                    },
                    {
                            text => 'h',
                    },
            ]);

    Each hashref is a field, and hence you do not specify the field separator character '|'.

    Then you use $graph -> add\_edge(...) to refer to those ports, if desired. Again, from scripts/record.2.pl:

    $graph -> add\_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

    The same label is specified in the previous case.

- o As an arrayref of strings

    From scripts/html.labels.1.pl:

            $graph -> add_node(name => 'Oakleigh', shape => 'record', color => 'blue',
                    label => ['West Oakleigh', 'East Oakleigh']);

    Here, again, you do not specify the field separator character '|'.

    What happens is that each string is taken to be the label of a field, and each field is given
    an auto-generated port name of the form "&lt;port$n>", where $n starts from 1.

    Here's how you refer to those ports, again from scripts/html.labels.1.pl:

            $graph -> add_edge(from => 'Murrumbeena', to => 'Oakleigh:port2',
                    color => 'green', label => '<Drive<br/>Run<br/>Sprint>');

See also the docs for the `add_node(name => $node_name, [%hash])` method.

## How do I specify attributes for clusters?

Just use subgraph => {...}, because the code (as of V 2.22) accepts attributes belonging to either clusters or subgraphs.

An example attribute is `pencolor`, which is used for clusters but not for subgraphs:

        $graph -> push_subgraph
        (
                graph    => {label => 'Child the Second'},
                name     => 'cluster Second subgraph',
                node     => {color => 'magenta', shape => 'diamond'},
                subgraph => {pencolor => 'white'}, # White hides the cluster's frame.
        );

See scripts/sub.graph.frames.pl.

## Why does [GraphViz](https://metacpan.org/pod/GraphViz) plot top-to-bottom but [GraphViz2::Parse::ISA](https://metacpan.org/pod/GraphViz2::Parse::ISA) plot bottom-to-top?

Because the latter knows the data is a class structure. The former makes no assumptions about the nature of the data.

## What happened to GraphViz::No?

The default\_node(%hash) method in [GraphViz2](https://metacpan.org/pod/GraphViz2) allows you to make nodes vanish.

Try: $graph -> default\_node(label => '', height => 0, width => 0, style => 'invis');

Because that line is so simple, I feel it's unnecessary to make a subclass of GraphViz2.

## What happened to GraphViz::Regex?

See [GraphViz2::Parse::Regexp](https://metacpan.org/pod/GraphViz2::Parse::Regexp).

## What happened to GraphViz::Small?

The default\_node(%hash) method in [GraphViz2](https://metacpan.org/pod/GraphViz2) allows you to make nodes which are small.

Try: $graph -> default\_node(label => '', height => 0.2, width => 0.2, style => 'filled');

Because that line is so simple, I feel it's unnecessary to make a subclass of GraphViz2.

## What happened to GraphViz::XML?

Use [GraphViz2::Parse::XML](https://metacpan.org/pod/GraphViz2::Parse::XML) instead, which uses the pure-Perl XML::Tiny.

Alternately, see ["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module) for how to use [XML::Bare](https://metacpan.org/pod/XML::Bare), [GraphViz2](https://metacpan.org/pod/GraphViz2)
and [GraphViz2::Data::Grapher](https://metacpan.org/pod/GraphViz2::Data::Grapher) instead.

## GraphViz returned a node name from add\_node() when given an anonymous node. What does GraphViz2 do?

You can give the node a name, and an empty string for a label, to suppress plotting the name.

See ["scripts/anonymous.pl"](#scripts-anonymous-pl) for demo code.

If there is some specific requirement which this does not cater for, let me know and I can change the code.

## How do I use image maps?

See ["Image Maps"](#image-maps) above.

## I'm trying to use image maps but the non-image map code runs instead!

The default value of `im_output_file` is '', so if you do not set it to anything, the new image maps code
is ignored.

## Why such a different approach to logging?

As you can see from scripts/\*.pl, I always use [Log::Handler](https://metacpan.org/pod/Log::Handler).

By default (i.e. without a logger object), [GraphViz2](https://metacpan.org/pod/GraphViz2) prints warning and debug messages to STDOUT,
and dies upon errors.

However, by supplying a log object, you can capture these events.

Not only that, you can change the behaviour of your log object at any time, by calling
["logger($logger\_object)"](#logger-logger_object).

## A Note about XML Containers

The 2 demo programs ["scripts/parse.html.pl"](#scripts-parse-html-pl) and ["scripts/parse.xml.bare.pl"](#scripts-parse-xml-bare-pl), which both use [XML::Bare](https://metacpan.org/pod/XML::Bare), assume your XML has a single
parent container for all other containers. The programs use this container to provide a name for the root node of the graph.

## Why did you choose [Moo](https://metacpan.org/pod/Moo) over [Moose](https://metacpan.org/pod/Moose)?

[Moo](https://metacpan.org/pod/Moo) is light-weight.

# Scripts Shipped with this Module

See [the demo page](http://savage.net.au/Perl-modules/html/graphviz2/index.html), which displays the output
of each program listed below.

## scripts/anonymous.pl

Demonstrates empty strings for node names and labels.

Outputs to ./html/anonymous.svg by default.

## scripts/cluster.pl

Demonstrates building a cluster as a subgraph.

Outputs to ./html/cluster.svg by default.

See also scripts/macro.\*.pl below.

## copy.config.pl

End users have no need to run this script.

## scripts/extract.arrow.shapes.pl

Downloads the arrow shapes from [Graphviz's Arrow Shapes](https://www.graphviz.org/doc/info/arrows.html) and outputs them to ./data/arrow.shapes.html.
Then it extracts the reserved words into ./data/arrow.shapes.dat.

## scripts/extract.attributes.pl

Downloads the attributes from [Graphviz's Attributes](http://www.graphviz.org/doc/info/attrs.html) and outputs them to ./data/attributes.html.
Then it extracts the reserved words into ./data/attributes.dat.

## scripts/extract.node.shapes.pl

Downloads the node shapes from [Graphviz's Node Shapes](http://www.graphviz.org/doc/info/shapes.html) and outputs them to ./data/node.shapes.html.
Then it extracts the reserved words into ./data/node.shapes.dat.

## find.config.pl

End users have no need to run this script.

## scripts/generate.demo.pl

Run by scripts/generate.svg.sh. See next point.

## scripts/generate.png.sh

See scripts/generate.svg.sh for details.

Outputs to /tmp by default.

This script is generated by generate.sh.pl.

## generate.sh.pl

Generates scripts/generate.png.sh and scripts/generate.svg.sh.

## scripts/generate.svg.sh

A bash script to run all the scripts and generate the \*.svg and \*.log files, in ./html.

You can them copy html/\*.html and html/\*.svg to your web server's doc root, for viewing.

Outputs to /tmp by default.

This script is generated by generate.sh.pl.

## scripts/Heawood.pl

Demonstrates the transitive 6-net, also known as Heawood's graph.

Outputs to ./html/Heawood.svg by default.

This program was reverse-engineered from graphs/undirected/Heawood.gv in the distro for [Graphviz](http://www.graphviz.org/) V 2.26.3.

## scripts/html.labels.1.pl

Demonstrates a HTML label without a table.

Also demonstrates an arrayref of strings as a label.

See also scripts/record.\*.pl for other label techniques.

Outputs to ./html/html.labels.1.svg by default.

## scripts/html.labels.2.pl

Demonstrates a HTML label with a table.

Outputs to ./html/html.labels.2.svg by default.

## scripts/macro.1.pl

Demonstrates non-cluster subgraphs via a macro.

Outputs to ./html/macro.1.svg by default.

## scripts/macro.2.pl

Demonstrates linked non-cluster subgraphs via a macro.

Outputs to ./html/macro.2.svg by default.

## scripts/macro.3.pl

Demonstrates cluster subgraphs via a macro.

Outputs to ./html/macro.3.svg by default.

## scripts/macro.4.pl

Demonstrates linked cluster subgraphs via a macro.

Outputs to ./html/macro.4.svg by default.

## scripts/macro.5.pl

Demonstrates compound cluster subgraphs via a macro.

Outputs to ./html/macro.5.svg by default.

## scripts/parse.regexp.pl

Demonstrates graphing a Perl regular expression.

Outputs to ./html/parse.regexp.svg by default.

## scripts/parse.stt.pl

Demonstrates graphing a [Set::FA::Element](https://metacpan.org/pod/Set::FA::Element)-style state transition table.

Inputs from t/sample.stt.1.dat and outputs to ./html/parse.stt.svg by default.

The input grammar was extracted from [Set::FA::Element](https://metacpan.org/pod/Set::FA::Element).

You can patch the scripts/parse.stt.pl to read from t/sample.stt.2.dat instead of t/sample.stt.1.dat.
t/sample.stt.2.dat was extracted from a obsolete version of [Graph::Easy::Marpa](https://metacpan.org/pod/Graph::Easy::Marpa), i.e. V 1.\*. The Marpa-based
parts of the latter module were completely rewritten for V 2.\*.

## scripts/parse.yacc.pl

Demonstrates graphing a [byacc](http://invisible-island.net/byacc/byacc.html)-style grammar.

Inputs from t/calc3.output, and outputs to ./html/parse.yacc.svg by default.

The input was copied from test/calc3.y in byacc V 20101229 and process as below.

Note: The version downloadable via HTTP is 20101127.

I installed byacc like this:

        sudo apt-get byacc

Now get a sample file to work with:

        cd ~/Downloads
        curl ftp://invisible-island.net/byacc/byacc.tar.gz > byacc.tar.gz
        tar xvzf byacc.tar.gz
        cd ~/perl.modules/GraphViz2
        cp ~/Downloads/byacc-20101229/test/calc3.y t
        byacc -v t/calc3.y
        mv y.output t/calc3.output
        diff ~/Downloads/byacc-20101229/test/calc3.output t/calc3.output
        rm y.tab.c

It's the file calc3.output which ships in the t/ directory.

## scripts/parse.yapp.pl

Demonstrates graphing a [Parse::Yapp](https://metacpan.org/pod/Parse::Yapp)-style grammar.

Inputs from t/calc.output, and outputs to ./html/parse.yapp.svg by default.

The input was copied from t/calc.t in [Parse::Yapp](https://metacpan.org/pod/Parse::Yapp)'s and processed as below.

I installed [Parse::Yapp](https://metacpan.org/pod/Parse::Yapp) (and yapp) like this:

        cpanm Parse::Yapp

Now get a sample file to work with:

        cd ~/perl.modules/GraphViz2
        cp ~/.cpanm/latest-build/Parse-Yapp-1.05/t/calc.t t/calc.input

Edit t/calc.input to delete the code, leaving the grammar after the \_\_DATA\_\_token.

        yapp -v t/calc.input > t/calc.output
        rm t/calc.pm

It's the file calc.output which ships in the t/ directory.

## scripts/quote.pl

Demonstrates embedded newlines and double-quotes in node names and labels.

It also demonstrates that the justification escapes, \\l and \\r, work too, sometimes.

Outputs to ./html/quote.svg by default.

Tests which run dot directly show this is a bug in [Graphviz](http://www.graphviz.org/) itself.

For example, in this graph, it looks like \\r only works after \\l (node d), but not always (nodes b, c).

Call this x.gv:

        digraph G {
                rankdir=LR;
                node [shape=oval];
                a [ label ="a: Far, far, Left\rRight"];
                b [ label ="\lb: Far, far, Left\rRight"];
                c [ label ="XXX\lc: Far, far, Left\rRight"];
                d [ label ="d: Far, far, Left\lRight\rRight"];
        }

and use the command:

        dot -Tsvg x.gv > x.svg

See [the Graphviz docs](http://www.graphviz.org/doc/info/attrs.html#k:escString) for escString, where they write 'l to mean \\l, for some reason.

## scripts/rank.sub.graph.1.pl

Demonstrates a very neat way of controlling the _rank_ attribute of nodes within subgraphs.

Outputs to ./html/rank.sub.graph.1.svg by default.

## scripts/rank.sub.graph.2.pl

Demonstrates a long-winded way of controlling the _rank_ attribute of nodes within subgraphs.

Outputs to ./html/rank.sub.graph.2.svg by default.

## scripts/rank.sub.graph.3.pl

Demonstrates the effect of the name of a subgraph, when that name does not start with 'cluster'.

Outputs to ./html/rank.sub.graph.3.svg by default.

## scripts/record.1.pl

Demonstrates a string as a label, containing both ports and orientation markers ({}).

Outputs to ./html/record.1.svg by default.

See also scripts/html.labels.2.pl and scripts/record.\*.pl for other label techniques.

## scripts/record.2.pl

Demonstrates an arrayref of hashrefs as a label, containing both ports and orientation markers ({}).

Outputs to ./html/record.2.svg by default.

See also scripts/html.labels.1.pl the other type of HTML labels.

## scripts/record.3.pl

Demonstrates a string as a label, containing ports and deeply nested orientation markers ({}).

Outputs to ./html/record.3.svg by default.

See also scripts/html.labels.\*.pl and scripts/record.\*.pl for other label techniques.

## scripts/record.4.pl

Demonstrates setting node shapes by default and explicitly.

Outputs to ./html/record.4.svg by default.

## scripts/rank.sub.graph.4.pl

Demonstrates the effect of the name of a subgraph, when that name starts with 'cluster'.

Outputs to ./html/rank.sub.graph.4.svg by default.

## scripts/report.nodes.and.edges.pl

Demonstates how to access the data returned by ["edge\_hash()"](#edge_hash) and ["node\_hash()"](#node_hash).

Prints node and edge attributes.

Outputs to STDOUT.

## scripts/report.valid.attributes.pl

Prints all current [Graphviz](http://www.graphviz.org/) attributes, along with a few global ones I've invented for the purpose of writing this module.

Outputs to STDOUT.

## scripts/sub.graph.frames.pl

Demonstrates clusters with and without frames.

Outputs to ./html/sub.graph.frames.svg by default.

## scripts/sub.graph.pl

Demonstrates a graph combined with a subgraph.

Outputs to ./html/sub.graph.svg by default.

## scripts/sub.sub.graph.pl

Demonstrates a graph combined with a subgraph combined with a subsubgraph.

Outputs to ./html/sub.sub.graph.svg by default.

## scripts/trivial.pl

Demonstrates a trivial 3-node graph, with colors, just to get you started.

Outputs to ./html/trivial.svg by default.

## scripts/utf8.1.pl

Demonstrates using utf8 characters in labels.

Outputs to ./html/utf8.1.svg by default.

## scripts/utf8.2.pl

Demonstrates using utf8 characters in labels.

Outputs to ./html/utf8.2.svg by default.

# TODO

- o Does GraphViz2 need to emulate the sort option in GraphViz?

    That depends on what that option really does.

- o Handle edges such as 1 -> 2 -> {A B}, as seen in [Graphviz](http://www.graphviz.org/)'s graphs/directed/switch.gv

    But how?

- o Validate parameters more carefully, e.g. to reject non-hashref arguments where appropriate

    Some method parameter lists take keys whose value must be a hashref.

# A Extremely Short List of Other Graphing Software

[Axis Maps](http://www.axismaps.com/).

[Polygon Map Generation](http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/).
Read more on that [here](http://blogs.perl.org/users/max_maischein/2011/06/display-your-data---randompoissondisc.html).

[Voronoi Applications](http://www.voronoi.com/wiki/index.php?title=Voronoi_Applications).

# Thanks

Many thanks are due to the people who chose to make [Graphviz](http://www.graphviz.org/) Open Source.

And thanks to [Leon Brocard](http://search.cpan.org/~lbrocard/), who wrote [GraphViz](https://metacpan.org/pod/GraphViz), and kindly gave me co-maint of the module.

# Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

# Repository

[https://github.com/ronsavage/GraphViz2.git](https://github.com/ronsavage/GraphViz2.git)

# Author

[GraphViz2](https://metacpan.org/pod/GraphViz2) was written by Ron Savage _<ron@savage.net.au>_ in 2011.

Home page: [http://savage.net.au/index.html](http://savage.net.au/index.html).

# Copyright

Australian copyright (c) 2011, Ron Savage.

        All Programs of mine are 'OSI Certified Open Source Software';
        you can redistribute them and/or modify them under the terms of
        The Perl License, a copy of which is available at:
        http://dev.perl.org/licenses/
