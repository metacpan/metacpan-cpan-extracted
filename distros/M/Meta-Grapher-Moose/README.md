# NAME

Meta::Grapher::Moose - Produce graphs showing meta-information about classes and roles

# VERSION

version 1.03

# SYNOPSIS

From the shell:

    foo@bar:~/package$ graph-meta.pl --package='My::Package::Name' --output='diagram.png'

Or from code:

    my $grapher = Meta::Grapher::Moose->new(
        package  => 'My::Package::Name',
        renderer => Meta::Grapher::Moose::Renderer::Plantuml->new(
            output => 'diagram.png',
        ),
    );
    $grapher->run;

# DESCRIPTION

STOP: The most common usage for this module is to use the command line
`graph-meta.pl` program. You should read the documentation for
`graph-meta.pl` to see how that works.

This module allows you to create graphs of your Moose classes showing a
directed graph of the parent classes and roles that your class consumes
recursively. In short, it can visually answer the questions like "Why did I
end up consuming that role" and, with the right renderer backend, "Where did
that method come from?"

## Example Output

With the GraphViz renderer (no methods/attributes):
[http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/graphviz/example.png](http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/graphviz/example.png)

<div>
    <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/graphviz/example.png" width="100%">
</div>

And with the PlantUML renderer:
[http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/plantuml/example.png](http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/plantuml/example.png)

<div>
    <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.03/examples/output/plantuml/example.png" width="100%">
</div>

# ATTRIBUTES

This class accepts the following attributes:

## package

The name of package that we should render a graph for.

String. Required.

## show\_meta

Since every Moose class and role normally has a `meta()` method it is
omitted from every class for brevity;  Enabling this option causes it to be
rendered.

## show\_new

The standard `new()` constructor is omitted from every class for brevity;
Enabling this option causes it to be rendered.

## show\_destroy

The `DESTROY()` method that Moose installs is omitted from every class for
brevity; Enabling this option causes it to be rendered.

## show\_moose\_object

The [Moose::Object](https://metacpan.org/pod/Moose::Object) base class is normally omitted from the diagram for
brevity. Enabling this option causes it be rendered.

## \_renderer

The renderer instance you want to use to create the graph.

Something that consumes [Meta::Grapher::Moose::Role::Renderer](https://metacpan.org/pod/Meta::Grapher::Moose::Role::Renderer). Required,
should be passed as the `renderer` argument (without the leading underscore.)

# METHODS

This class provides the following methods:

## run

Builds the graph from the source code and tells the renderer to render it.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose)
(or [bug-meta-grapher-moose@rt.cpan.org](mailto:bug-meta-grapher-moose@rt.cpan.org)).

I am also usually active on IRC as 'drolsky' on `irc://irc.perl.org`.

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Mark Fowler <mark@twoshortplanks.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
