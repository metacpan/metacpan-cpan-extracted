# NAME

GraphViz2 - A wrapper for AT&T's Graphviz

# Synopsis

## Sample output

See [https://graphviz-perl.github.io/](https://graphviz-perl.github.io/).

## Perl code

### Typical Usage

        use strict;
        use warnings;
        use File::Spec;
        use GraphViz2;

        use Log::Handler;
        my $logger = Log::Handler->new;
        $logger->add(screen => {
                maxlevel => 'debug', message_layout => '%m', minlevel => 'error'
        });

        my $graph = GraphViz2->new(
                edge   => {color => 'grey'},
                global => {directed => 1},
                graph  => {label => 'Adult', rankdir => 'TB'},
                logger => $logger,
                node   => {shape => 'oval'},
        );

        $graph->add_node(name => 'Carnegie', shape => 'circle');
        $graph->add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
        $graph->add_node(name => 'Oakleigh',    color => 'blue');
        $graph->add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
        $graph->add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

        $graph->push_subgraph(
                name  => 'cluster_1',
                graph => {label => 'Child'},
                node  => {color => 'magenta', shape => 'diamond'},
        );
        $graph->add_node(name => 'Chadstone', shape => 'hexagon');
        $graph->add_node(name => 'Waverley', color => 'orange');
        $graph->add_edge(from => 'Chadstone', to => 'Waverley');
        $graph->pop_subgraph;

        $graph->default_node(color => 'cyan');

        $graph->add_node(name => 'Malvern');
        $graph->add_node(name => 'Prahran', shape => 'trapezium');
        $graph->add_edge(from => 'Malvern', to => 'Prahran');
        $graph->add_edge(from => 'Malvern', to => 'Murrumbeena');

        my $format      = shift || 'svg';
        my $output_file = shift || File::Spec->catfile('html', "sub.graph.$format");
        $graph->run(format => $format, output_file => $output_file);

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

### edge => $hashref

The _edge_ key points to a hashref which is used to set default attributes for edges.

Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

The default is {}.

This key is optional.

### global => $hashref

The _global_ key points to a hashref which is used to set attributes for the output stream.

This key is optional.

Valid keys within this hashref are:

#### combine\_node\_and\_port

New in 2.58. It defaults to true, but in due course (currently planned
May 2021) it will default to false. When true, `add_node` and `add_edge`
will escape only some characters in the label and names, and in particular
the "from" and "to" parameters on edges will combine the node name
and port in one string, with a `:` in the middle (except for special
treatment of double-colons).

When the option is false, any name may be given to nodes, and edges can
be created between them. To specify ports, give the additional parameter
of `tailport` or `headport`. To specify a compass point in addition,
give array-refs with two values for these parameters. Also, `add_node`'s
treatment of labels is more DWIM, with `{` etc being transparently
quoted.

#### directed => $Boolean

This option affects the content of the output stream.

directed => 1 outputs 'digraph name {...}', while directed => 0 outputs 'graph name {...}'.

At the Perl level, directed graphs have edges with arrow heads, such as '->', while undirected graphs have
unadorned edges, such as '--'.

The default is 0.

This key is optional.

#### driver => $program\_name

This option specifies which external program to run to process the output stream.

The default is to use [File::Which](https://metacpan.org/pod/File::Which)'s which() method to find the 'dot' program.

This key is optional.

#### format => $string

This option specifies what type of output file to create.

The default is 'svg'.

Output formats of the form 'png:gd' etc are also supported, but only the component before
the first ':' is validated by [GraphViz2](https://metacpan.org/pod/GraphViz2).

This key is optional.

#### label => $string

This option specifies what an edge looks like: '->' for directed graphs and '--' for undirected graphs.

You wouldn't normally need to use this option.

The default is '->' if directed is 1, and '--' if directed is 0.

This key is optional.

#### name => $string

This option affects the content of the output stream.

name => 'G666' outputs 'digraph G666 {...}'.

The default is 'Perl' :-).

This key is optional.

#### record\_shape => /^(?:M?record)$/

This option affects the shape of records. The value must be 'Mrecord' or 'record'.

Mrecords have nice, rounded corners, whereas plain old records have square corners.

The default is 'Mrecord'.

See [Record shapes](http://www.graphviz.org/doc/info/shapes.html#record) for details.

#### strict => $Boolean

This option affects the content of the output stream.

strict => 1 outputs 'strict digraph name {...}', while strict => 0 outputs 'digraph name {...}'.

The default is 0.

This key is optional.

#### timeout => $integer

This option specifies how long to wait for the external program before exiting with an error.

The default is 10 (seconds).

This key is optional.

### graph => $hashref

The _graph_ key points to a hashref which is used to set default attributes for graphs.

Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

The default is {}.

This key is optional.

### logger => $logger\_object

Provides a logger object so $logger\_object -> $level($message) can be called at certain times. Any object with `debug` and `error` methods
will do, since these are the only levels emitted by this module.
One option is a [Log::Handler](https://metacpan.org/pod/Log::Handler) object.

Retrieve and update the value with the logger() method.

By default (i.e. without a logger object), [GraphViz2](https://metacpan.org/pod/GraphViz2) prints warning and debug messages to STDOUT,
and dies upon errors.

However, by supplying a log object, you can capture these events.

Not only that, you can change the behaviour of your log object at any time, by calling
["logger($logger\_object)"](#logger-logger_object).

See also the verbose option, which can interact with the logger option.

This key is optional.

### node => $hashref

The _node_ key points to a hashref which is used to set default attributes for nodes.

Hence, allowable keys and values within that hashref are anything supported by [Graphviz](http://www.graphviz.org/).

The default is {}.

This key is optional.

### subgraph => $hashref

The _subgraph_ key points to a hashref which is used to set attributes for all subgraphs, unless overridden
for specific subgraphs in a call of the form push\_subgraph(subgraph => {$attribute => $string}).

Valid keys within this hashref are:

- rank => $string

    This option affects the content of all subgraphs, unless overridden later.

    A typical usage would be new(subgraph => {rank => 'same'}) so that all nodes mentioned within each subgraph
    are constrained to be horizontally aligned.

    See scripts/rank.sub.graph.1.pl for sample code.

    Possible values for $string are: max, min, same, sink and source.

    See the [Graphviz 'rank' docs](http://www.graphviz.org/doc/info/attrs.html#d:rank) for details.

The default is {}.

This key is optional.

### verbose => $Boolean

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

## Alternate constructor and object method

### from\_graph

        my $gv = GraphViz2->from_graph($g);

        # alternatively
        my $gv = GraphViz2->new;
        $gv->from_graph($g);

        # for handy debugging of arbitrary graphs:
        GraphViz2->from_graph($g)->run(format => 'svg', output_file => 'output.svg');

Takes a [Graph](https://metacpan.org/pod/Graph) object. This module will figure out various defaults from it,
including whether it is directed or not.

Will also use any node-, edge-, and graph-level attributes named
`graphviz` as a hash-ref for setting attributes on the corresponding
entities in the constructed GraphViz2 object. These will override the
figured-out defaults referred to above.

Will only set the `global` attribute if called as a constructor. This
will be dropped from any passed-in graph-level `graphviz` attribute
when called as an object method.

A special graph-level attribute (under `graphviz`) called `groups` will
be given further special meaning: it is an array-ref of hash-refs. Those
will have keys, used to create subgraphs:

- attributes

    Hash-ref of arguments to supply to `push_subgraph` for this subgraph.

- nodes

    Array-ref of node names to put in this subgraph.

Example:

        $g->set_graph_attribute(graphviz => {
                groups => [
                        {nodes => [1, 2], attributes => {subgraph=>{rank => 'same'}}},
                ],
                # other graph-level attributes...
        });

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

- A global frame

    I can't see how to make the graph as a whole (at level 0 in the scope stack) have a frame.

- Frame color

    When you specify graph => {color => 'red'} at the parent level, the subgraph has a red frame.

    I think a subgraph should control its own frame.

- Parent and child frames

    When you specify graph => {color => 'red'} at the subgraph level, both that subgraph and it children have red frames.

    This contradicts what happens at the global level, in that specifying color there does not given the whole graph a frame.

- Frame visibility

    A subgraph whose name starts with 'cluster' is currently forced to have a frame, unless you rig it by specifying a
    color the same as the background.

    For sample code, see scripts/sub.graph.frames.pl.

Also, check [the pencolor docs](http://www.graphviz.org/doc/info/attrs.html#d:pencolor) for how the color of the frame is
chosen by cascading thru a set of options.

I've posted an email to the [Graphviz](http://www.graphviz.org/) mailing list suggesting a new option, framecolor, so deal with
this issue, including a special color of 'invisible'.

# Image Maps

As of V 2.43, `GraphViz2` supports image maps, both client and server side.
For web use, note that these options also take effect when generating SVGs,
for a much lighter-weight solution to hyperlinking graph nodes and edges.

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

- im\_format => $str

    Expected values: 'imap' (server-side) and 'cmapx' (client-side).

    Default value: 'cmapx'.

- im\_output\_file => $file\_name

    The name of the output map file.

    Default: ''.

    If you do not set it to anything, the new image maps code is ignored.

## Sample Code

Various demos are shipped in the new maps/ directory:

Each demo, when FTPed to your web server displays some text with an image in the middle. In each case
you can click on the upper oval to jump to one page, or click on the lower oval to jump to a different
page, or click anywhere else in the image to jump to a third page.

- demo.1.\*

    This set demonstrates a server-side image map but does not use `GraphViz2`.

    You have to run demo.1.sh which generates demo.1.map, and then you FTP the whole dir maps/ to your web server.

    URL: your.domain.name/maps/demo.1.html.

- demo.2.\*

    This set demonstrates a client-side image map but does not use `GraphViz2`.

    You have to run demo.2.sh which generates demo.2.map, and then you manually copy demo.2.map into demo.2.html,
    replacing any version of the map already present. After that you FTP the whole dir maps/ to your web server.

    URL: your.domain.name/maps/demo.2.html.

- demo.3.\*

    This set demonstrates a server-side image map using `GraphViz2` via demo.3.pl.

    Note line 54 of demo.3.pl which sets the default `im_format` to 'imap'.

    URL: your.domain.name/maps/demo.3.html.

- demo.4.\*

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

%hash is any edge attributes accepted as
[Graphviz attributes](https://www.graphviz.org/doc/info/attrs.html).
These are validated in exactly the same way as the edge parameters in the calls to
default\_edge(%hash), new(edge => {}) and push\_subgraph(edge => {}).

To make the edge start or finish on a port, see ["combine\_node\_and\_port"](#combine_node_and_port).

## add\_node(name => $node\_name, \[%hash\])

        my $graph = GraphViz2->new(global => {combine_node_and_port => 0});
        $graph->add_node(name => 'struct3', shape => 'record', label => [
                { text => "hello\\nworld" },
                [
                        { text => 'b' },
                        [
                                { text => 'c{}' }, # reproduced literally
                                { text => 'd', port => 'here' },
                                { text => 'e' },
                        ]
                        { text => 'f' },
                ],
                { text => 'g' },
                { text => 'h' },
        ]);

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

The string is the label. If the `shape` is a record, you can give any
text and it will be passed for interpretation by Graphviz. This means
you will need to quote < and > (port specifiers), `|` (cell
separator) and `{` `}` (structure depth) with `\` to make them appear
literally.

For records, the cells start horizontal. Each additional layer of
structure will switch the orientation between horizontal and vertical.

### If it is an arrayref of strings...

- The node is forced to be a record

    The actual shape, 'record' or 'Mrecord', is set globally, with:

            my($graph) = GraphViz2 -> new
            (
                    global => {record_shape => 'record'}, # Override default 'Mrecord'.
                    ...
            );

    Or set locally with:

            $graph -> add_node(name => 'Three', label => ['Good', 'Bad'], shape => 'record');

- Each element in the array defines a field in the record

    These fields are combined into a single node

- Each element is treated as a label
- Each label is given a port name (1 .. N) of the form "port$port\_count"
- Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

### If it is an arrayref of hashrefs...

- The node is forced to be a record

    The actual shape, 'record' or 'Mrecord', can be set globally or locally, as explained just above.

- Each element in the array defines a field in the record
- Each element is treated as a hashref with keys 'text' and 'port'

    The 'port' key is optional.

- The value of the 'text' key is the label
- The value of the 'port' key is the port
- Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

See scripts/html.labels.\*.pl and scripts/record.\*.pl for sample code.

See also ["How labels interact with ports"](#how-labels-interact-with-ports).

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

Returns the output stream, formatted nicely, to be passed to the external program (e.g. dot).

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

## valid\_attributes()

Returns a hashref of all attributes known to this module, keyed by type
to hashrefs to true values.

Stored in this module, using [Data::Section::Simple](https://metacpan.org/pod/Data::Section::Simple).

These attributes are used to validate attributes in many situations.

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

- Run the chosen external program on the ["dot\_input"](#dot_input)
- Capture STDOUT and STDERR from that program
- Die if STDERR contains anything
- Copies STDOUT to the buffer controlled by the dot\_output() method
- Write the captured contents of STDOUT to $output\_file, if $output\_file has a value

## stringify\_attributes($context, $option)

Returns a string suitable to writing to the output stream.

$context is one of 'edge', 'graph', 'node', or a special string. See the code for details.

You wouldn't normally need to use this method.

## validate\_params($context, \\%attributes)

Validate the given attributes within the given context.

Also, if $context is 'subgraph', attributes are allowed to be in the 'cluster' context.

Returns $self to allow method chaining.

$context is one of 'edge', 'global', 'graph', or 'node'.

You wouldn't normally need to use this method.

## verbose(\[$integer\])

Gets or sets the verbosity level, for when a logging object is not used.

Here, \[\] indicates an optional parameter.

# MISC

## Graphviz version supported

GraphViz2 targets V 2.34.0 of [Graphviz](http://www.graphviz.org/).

This affects the list of available attributes per graph item (node, edge, cluster, etc) available.

See the second column of the
[Graphviz attribute docs](https://www.graphviz.org/doc/info/attrs.html) for details.

## Supported file formats

Parses the output of `dot -T?`, so depends on local installation.

## Special characters in node names and labels

[GraphViz2](https://metacpan.org/pod/GraphViz2) escapes these 2 characters in those contexts: \[\].

Escaping the 2 chars \[\] started with V 2.10. Previously, all of \[\]{} were escaped, but {} are used in records
to control the orientation of fields, so they should not have been escaped in the first place.

It would be nice to also escape | and <, but these characters are used in specifying fields and ports in records.

See the next couple of points for details.

## Ports

Ports are what [Graphviz](http://www.graphviz.org/) calls those places on the outline of a node where edges
leave and terminate.

The [Graphviz](http://www.graphviz.org/) syntax for ports is a bit unusual:

- This works: "node\_name":port5
- This doesn't: "node\_name:port5"

Let me repeat - that is Graphviz syntax, not GraphViz2 syntax. In Perl, you must do this:

        $graph -> add_edge(from => 'struct1:f1', to => 'struct2:f0', color => 'blue');

You don't have to quote all node names in [Graphviz](http://www.graphviz.org/), but some, such as digits, must be quoted, so I've decided to quote them all.

## How labels interact with ports

You can specify labels with ports in these ways:

- As a string

            $graph -> add_node(name => 'struct3', label => "hello\nworld |{ b |{c|<here> d|e}| f}| g | h");

    Here, the string contains a port (&lt;here>), field markers (|), and orientation markers ({}).

    Clearly, you must specify the field separator character '|' explicitly. In the next 2 cases, it is implicit.

    Then you use $graph -> add\_edge(...) to refer to those ports, if desired:

            $graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

    The same label is specified in the next case.

- As an arrayref of hashrefs

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

            $graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

    The same label is specified in the previous case.

- As an arrayref of strings

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

## Attributes for clusters

Just use subgraph => {...}, because the code (as of V 2.22) accepts attributes belonging to either clusters or subgraphs.

An example attribute is `pencolor`, which is used for clusters but not for subgraphs:

        $graph->push_subgraph(
                graph    => {label => 'Child the Second'},
                name     => 'cluster Second subgraph',
                node     => {color => 'magenta', shape => 'diamond'},
                subgraph => {pencolor => 'white'}, # White hides the cluster's frame.
        );
        # other nodes or edges can be added within it...
        $graph->pop_subgraph;

# TODO

- Handle edges such as 1 -> 2 -> {A B}, as seen in [Graphviz](http://www.graphviz.org/)'s graphs/directed/switch.gv

    But how?

- Validate parameters more carefully, e.g. to reject non-hashref arguments where appropriate

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
