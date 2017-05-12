#!/usr/bin/env perl

use strict;
use warnings;

# PODNAME: graph-meta.pl

our $VERSION = '1.03';

use Meta::Grapher::Moose::CommandLine;
exit Meta::Grapher::Moose::CommandLine->run;

=pod

=encoding UTF-8

=head1 NAME

graph-meta.pl - graph-meta.pl - create graphs for Moose Objects

=head1 VERSION

version 1.03

=head1 SYNOPSIS

   shell$ graph-meta.pl --package='My::Package::Name' --output='diagram.png'

=head1 DESCRIPTION

This command allows you to create graphs of your Moose classes showing a
directed graph of the parent classes and roles that your class consumes
recursively.  In short, it can visually answer the questions like "Why did I end
up consuming that role" and, with the right renderer backend, "Where did that
method come from?"

This is best shown with a couple of examples

With the GraphViz renderer (no methods/attributes):

=for text http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.00/examples/output/graphviz/example.png
=for html
   <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.00/examples/output/graphviz/example.png">

With the PlantUML renderer:

=for text http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.00/examples/output/plantuml/example.png
=for html
   <img src="http://st.aticpan.org/source/DROLSKY/Meta-Grapher-Moose-1.00/examples/output/plantuml/example.png">

=head2 Command Line Options

=head4 package

Required.  The name of the package that you're going to be generating a
graph for.

=head4 renderer

The renderer you'd like to use.  For example:

   graph-meta.pl --renderer=plantuml --package='My::Package::Name' --output='diagram.png'

This is programmatically transformed into the class name that performs the
renderer (by adding command )

Renderers bundled with this distribution can be accessed with the C<graphviz>
or C<plantuml> options (that load either the
L<Meta::Grapher::Moose::Renderer::Graphviz> or
L<Meta::Grapher::Moose::Renderer::Plantuml> renderers.)  By default C<graphviz>
is used.

=head3 Renderer output options

Both the C<graphviz> and C<plantuml> renderers support the following command
line options (though it's conceivable that other third party renderers do not
support these options)

=head4 output

The name of the file that output should be written to.  For example C<foo.png>.
If no output is specified then output will be sent to STDOUT.

=head4 format

The format of the output, for example C<png> or C<svg>.

If this is not specified then, if possible, it will be extracted from the
extension of the C<output>.  If either the C<output> has not been set or the
output filename has no file extension then the output will default to outputting
the source code for the external tool the renderer uses (i.e. it'll be C<dot>
format for the C<graphviz> renderer and C<plantuml> source for the C<plantuml>
renderer.)

=head3 formatting

This can be used to set extra formatting information for the graph (colors,
etc.) Please see the documentation for the individual classes on how this can be
set.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Meta-Grapher-Moose>
(or L<bug-meta-grapher-moose@rt.cpan.org|mailto:bug-meta-grapher-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: graph-meta.pl - create graphs for Moose Objects

