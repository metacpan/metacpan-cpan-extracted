package Makefile::GraphViz;

use strict;
use warnings;
use vars qw($VERSION);

use GraphViz;
use base 'Makefile::Parser';

$VERSION = '0.21';

$Makefile::Parser::Strict = 0;

our $IDCounter = 0;

# ================================
# == Default values & functions ==
# ================================

my %NormalNodeStyle = (
    shape     => 'box',
    style     => 'filled',
    fillcolor => '#ffff99',
    fontname  => 'Arial',
    fontsize  => 10,
);

my %VirNodeStyle = (
    shape     => 'plaintext'
);

my %NormalEndNodeStyle = (
    fillcolor => '#ccff99'
);

my %VirEndNodeStyle = (
    shape     => 'plaintext',
    fillcolor => '#ccff99'
);

my %CmdStyle = (
    shape     => 'note',
    style     => 'filled',
    fillcolor => '#dddddd',
    fontname  => 'Monospace',
    fontsize  => 8,
);

my %EdgeStyle = ( color => 'red' );

my %InitArgs = (
    layout    => 'dot',
    ratio     => 'auto',
    rankdir   => 'BT',
    node      => \%NormalNodeStyle,
    edge      => \%EdgeStyle,
);

our %Nodes;

sub _gen_id () {
    return ++$IDCounter;
}

sub _trim_path ($) {
    my $path = shift;
    $path =~ s/.+(.{5}[\\\/].*)$/...$1/o;
    $path =~ s/\\/\\\\/g;
    return $path;
}

sub _trim_cmd ($) {
    my $cmd = shift;
    $cmd =~ s/((?:\S+\s+){2})\S.*/$1.../o;
    $cmd =~ s/\\/\\\\/g;
    return $cmd;
}

sub _url ($) {
    my $url = shift;
    $url =~ s/[\/\\:. \t]+/_/g;
    return $url;
}

sub _find ($@) {
    my $elem = shift;
    foreach (@_) {
        if (ref $_) {
            return 1 if $elem =~ $_;
        }
        return 1 if $elem eq $_;
    }
    return undef;
}

# Plot graph with single root target
sub plot ($$@) {

    # ==================================
    # == Unnamed command line options ==
    # ==================================

    # Self
    my $self = shift;

    # Main/root target
    my $root_name = shift;

    # ================================
    # == Named command line options ==
    # ================================

    my %opts = @_;
    my $gv = $opts{gv};

    # Helper function for initialising undefined user options with defaults
    my $init_opts = sub {
        my $key = shift;
        $opts{$key} = +shift unless $opts{$key} and ref $opts{$key};
    };

    $init_opts->('init_args',             \%InitArgs);
    $init_opts->('normal_node_style',     \%NormalNodeStyle);
    $init_opts->('vir_node_style',        \%VirNodeStyle);
    $init_opts->('normal_end_node_style', \%NormalEndNodeStyle);
    $init_opts->('vir_end_node_style',    \%VirEndNodeStyle);
    $init_opts->('cmd_style',             \%CmdStyle);
    $init_opts->('edge_style',            \%EdgeStyle);
    $init_opts->('node_trim_fct',         \&_trim_path);
    $init_opts->('cmd_trim_fct',          \&_trim_cmd);
    $init_opts->('url_fct',               \&_url);

    $opts{init_args}{name} = qq("$root_name");
    $opts{init_args}{node} = $opts{normal_node_style};
    $opts{init_args}{edge} = \%{$opts{edge_style}};

    # =========================
    # == Initialise GraphViz ==
    # =========================

    # Do nothing if root node is in exclude list
    return $gv if _find($root_name, @{$opts{exclude}}) and !_find($root_name, @{$opts{no_exclude}});

    # Create new graph object if necessary
    if (!$gv) {
        $gv = GraphViz->new(%{$opts{init_args}});
        %Nodes = ();
    }

    # ===========================================
    # == Create graph, starting from root node ==
    # ===========================================

    # Assume we have a normal node
    my $is_virtual = 0;
    # Do nothing if node has already been processed
    if ($Nodes{$root_name}) {
        return $gv;
    }
    # Add node to processed node list
    $Nodes{$root_name} = 1;

    # Initialise root node list
    my @roots = ($root_name and ref $root_name)
        ? $root_name
        : ($self->target($root_name));

    # INFO: Why a list? Because multiple definitions of the same target with
    # different prerequisites and recipes (commands) can occur. In this case
    # $self->target returns multiple target objects with the same name, but
    # different properties. Run the test suite and uncomment the code below
    # to see this happen.
    #if (scalar(@roots) > 1) {
    #    warn "\n\@roots contains multiple entries\n" ;
    #    if ($root_name and ref $root_name) {
    #        warn "  \$root_name is a reference\n" ;
    #    }
    #    else {
    #        warn "  \$self->target(\$root_name) delivers >1 targets\n" ;
    #        for my $root (@roots) {
    #            my @p = $root->prereqs();
    #            my @c = $root->commands();
    #            warn "    root = $root  ->  prereqs = @p  /  commands = @c\n";
    #        }
    #    }
    #}

    # Trim node name
    my $short_name = $opts{node_trim_fct}->($root_name);

    # Determine node type (normal or virtual)
    if (_find($root_name, @{$opts{normal_nodes}})) {
        # Node is member of normal nodes list -> normal
        $is_virtual = 0;
    } elsif (_find($root_name, @{$opts{vir_nodes}}) or @roots and !$roots[0]->commands) {
        # Node is member of virtual nodes list or has no commands -> virtual
        $is_virtual = 1;
    }

    # Is there a make target for this node?
    if (!@roots) {
        # No -> node is a "tree leave" -> add node, then stop processing
        $gv->add_node(
            $root_name,
            label       => $short_name,
            $is_virtual ? %{$opts{vir_node_style}} : ()
        );
        return $gv;
    }

    # Loop through node list for current target
    for my $root (@roots) {
        # Get prerequisites
        my @prereqs = $root->prereqs;
        # Is target flagged to be an end node?
        my $is_end_node = (_find($root_name, @{$opts{end_with}}) and !_find($root_name, @{$opts{no_end_with}})) ? 1 : 0;

        # Expandable end node (i.e. with prerequisites)?
        if ($is_end_node and @prereqs) {
            # Yes -> add end node with URL
            $gv->add_node(
                $root_name,
                label       => $short_name,
                # Add URL because the user might want to create a set of interlinked
                # graphs with each end node pointing to its sub-graph
                URL         => $opts{url_fct}->($root_name),
                $is_virtual ? %{$opts{vir_end_node_style}} : %{$opts{normal_end_node_style}}
            );
            # Call user-defined hook in case she wants to do something with end nodes,
            # such as collect their names and then recursively plot sub-graphs.
            $opts{end_with_callback}->($root_name) if $opts{end_with_callback};
            # Stop processing here (thus the name "end node")
            #return $gv;
        }
        else {
            # No-> ordinary node or end node without prerequisites -> add normal node
            $gv->add_node(
                $root_name,
                label       => $short_name,
                $is_virtual ? %{$opts{vir_node_style}} : ()
            );
        }

        # Add command node displaying target's recipe if trim_mode is false
        # and recipe exists. BTW, '\l' left-justifies each single line.
        my $lower_node;
        my @cmds = $root->commands;
        if (!$opts{trim_mode} and @cmds) {
            # Command node gets an auto-created ID as its name
            $lower_node = _gen_id();
            my $cmds = join("\\l", map { $opts{cmd_trim_fct}->($_); } @cmds);
            $gv->add_node(
                $lower_node,
                label       => $cmds . "\\l",
                %{$opts{cmd_style}}
            );
            # The recipe points to its target (dashed line if virtual target)
            $gv->add_edge(
                $lower_node => $root_name,
                $is_virtual ? (style => 'dashed') : ()
            );
        } else {
            $lower_node = $root_name;
        }

        # No further processing for end nodes
        next if $is_end_node;

        # Check prerequisites
        foreach (@prereqs) {
            # Ignore prerequisites on exclude list or named "|"
            next if $_ eq "|" or (_find($_, @{$opts{exclude}}) and !_find($_, @{$opts{no_exclude}}));
            # The prerequisite points to its dependent target (dashed line if virtual target)
            $gv->add_edge(
                $_          => $lower_node,
                $is_virtual ? (style => 'dashed') : ());
            # Recurse into 'plot' for prerequisite
            $self->plot($_, gv => $gv, @_);
        }
    }
    return $gv;
}

# Plot graph with multiple (all) root targets
sub plot_all ($) {
    my $self = shift;
    # TODO: Should we not also apply $opts{init_args} here?
    my $gv = GraphViz->new(%InitArgs);
    %Nodes = ();
    for my $target ($self->roots) {
        $self->plot($target, gv => $gv);
    }
    $gv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Makefile::GraphViz - Draw building flowcharts from Makefiles using GraphViz

=head1 VERSION

This document describes Makefile::GraphViz 0.21 released on 7 December 2014.

=head1 SYNOPSIS

  use Makefile::GraphViz;

  $parser = Makefile::GraphViz->new;
  $parser->parse('Makefile');

  # plot the tree rooted at the 'install' goal in Makefile:
  $gv = $parser->plot('install');  # A GraphViz object returned.
  $gv->as_png('install.png');

  # plot the tree rooted at the 'default' goal in Makefile:
  $gv = $parser->plot;
  $gv->as_png('default.png');

  # plot the forest consists of all the goals in Makefile:
  $gv = $parser->plot_all;
  $gv->as_png('default.png');

  # you can also invoke all the methods
  # inherited from the Makefile::Parser class:
  @targets = $parser->targets;

=head1 DESCRIPTION

This module uses L<Makefile::Parser> to render user's Makefiles via the amazing
L<GraphViz> module. Before I decided to write this thing, there had been already a
CPAN module named L<GraphViz::Makefile> which did the same thing. However, the
pictures generated by L<GraphViz::Makefile> is oversimplified in my opinion, so
a much complex one is still needed.

For everyday use, the L<gvmake> utility is much more convenient than using this
module directly. :)

B<WARNING> This module is highly experimental and is currently at
B<alpha> stage, so production use is strongly discouraged right now.
Anyway, I have the plan to improve this stuff unfailingly.

For instance, the following makefile

    all: foo
    all: bar
            echo hallo

    any: foo hiya
            echo larry
            echo howdy
    any: blah blow

    foo:: blah boo
            echo Hi
    foo:: howdy buz
            echo Hey

produces the following image via the C<plot_all> method:

=begin html

<!-- this h1 part is for search.cpan.org -->
<h1>
<a class = 'u' 
   href  = '#___top'
   title ='click to go to top of document'
   name  = "PNG IMAGE"
>PNG IMAGE</a>
</h1>

<p><img src="http://agentzh.org/misc/multi.png" border=0 alt="image hosted by agentzh.org"/></p>
<p>Image hosted by <a href="http://agentzh.org">agentzh.org</a></p>

=end html

=head1 SAMPLE PICTURES

Browse L<http://search.cpan.org/src/AGENT/Makefile-GraphViz-0.16/samples.html>
for some sample output graphs.

=head1 INSTALLATION

Prerequisites L<GraphViz> and L<Makefile::Parser> should be installed to your
Perl distribution first. Among other things, the L<GraphViz> module needs tools
"dot", "neato", "twopi", "circo" and "fdp" from the Graphviz project
(L<http://www.graphviz.org/> or L<http://www.research.att.com/sw/tools/graphviz/>).
Hence you have to download an executable package of AT&T's Graphviz for your platform
or build it from source code yourself.

=head1 The Makefile::GraphViz Class

This class is a subclass inherited from L<Makefile::Parser>. So all the methods (and
hence all the functionalities) provided by L<Makefile::Parser> are accessible here.
Additionally this class also provides some more methods on its own right.

=head1 METHODS

=over

=item C<< $graphviz = plot($target, ...) >>

This method is essential to the class. Users invoke this method to plot the specified
Makefile target. If the argument is absent, the default target in the Makefile will
be used. It will return a L<GraphViz> object, on which you can later call the
C<as_png> or C<as_text> method to obtain the final graphical output.

The argument can both be the target's name and a Makefile::Target object. If the
given target can't be found in Makefile, the target will be plotted separately.

This method also accepts several options.

    $gv = $parser->plot(undef, normal_nodes => ['mytar']);
    $gv = $parser->plot(
        'cmintester',
        exclude  => [qw(
            all hex2bin.exe exe2hex.pl bin2asm.pl
            asm2ast.pl ast2hex.pl cod2ast.pl
        )],
        end_with => [qw(pat_cover.ast pat_cover)],
        normal_nodes => ['pat_cover.ast'],
        vir_nodes => ['pat_cover'],
        trim_mode => 0,
    );

=over

=item cmd_style

This option controls the style of the shell command box. The default
appearance for these nodes are gray ellipses.

=item edge_style

This option's value will be passed directly to GraphViz's add_edge
method. It controls the appearance of the edges in the output graph,
which is default to red directed arrows.

    $gv = $parser->plot(
        'install',
        edge_style => {
            style => 'dotted',
            color => 'seagreen',
        },
    );

=item end_with

This option takes a list ref as its value. The plot method
won't continue to iterate the subtree rooted at entries in the
list. It is worth noting that the entries themselves will be
displayed as usual. This is the only difference compared to
the B<exclude> option.

Here is an example:

    $gv = $parser->plot(
        'cmintester',
        end_with => [qw(pat_cover.ast pat_cover)],
    );

=item exclude

This option takes a list ref as its value. All the entries
in the list won't be displayed and the subtrees rooted at 
these entries won't be displayed either.

    $parser->plot(
        'clean',
        exclude=>[qw(foo.exe foo.pl)]
    )->as_png('clean.png');

=item gv

This option accepts user's GraphViz object to render the graph.

    $gv = GraphViz->new(width => 30, height => 20,
                        pagewidth => 8.5, pageheight => 11);
    $parser->plot('install', gv => $gv);
    print $gv->as_text;

=item init_args

This option takes a hash ref whose value will be passed to the
constructor of the GraphViz class if the option B<gv> is not
specified:

    $parser->plot(
        'install',
        init_args => {
            width => 30, height => 20,
            pagewidth => 8.5, pageheight => 11,
        },
    )->as_png('a.png');

=item normal_nodes

The entries in this option's list are forced to be the
normal nodes. Normal nodes are defined to be the Makefile
targets corresponding to disk files. In contrast, virtual
nodes are those Makefile targets with no real files
corresponding to them.

=item normal_node_style

Override the default style for the normal nodes. By default,
normal nodes are yellow rectangles with black border.

    $gv = $parser->plot(
        'install',
        normal_node_style => {
           shape => 'circle',
           style => 'filled',
           fillcolor => 'red',
        },
    );

=item trim_mode

When this option is set to a true value, no shell command
nodes will be plotted.

=item vir_nodes

The entries in this option's list are forced to be the
virtual nodes. Virtual nodes are those Makefile targets
with no real files corresponding to them, which are generally
called "phony targets" in the GNU make Manual and "pseudo targets"
in MS NMAKE's docs.

=item vir_node_style

Override the default style for the virtual nodes.

    $gv = $parser->plot(
        'install',
        virtual_node_style => {
           shape => 'box',
           style => 'filled',
           fillcolor => 'blue',
        },
    );

By default, virtual nodes are yellow rectangles with no
border.

=back

=item C<< $graphviz = $object->plot_all() >>

Plot all the (root) goals appeared in the Makefile.

=back

=head2 INTERNAL FUNCTIONS

Internal functions should not be used directly.

=over

=item _gen_id

Generate a unique id for command node.

=item _trim_path

Trim the path to a more readable form.

=item _trim_cmd

Trim the shell command to a more friendly size.

=item _find

If the given element is found in the given list, this
function will return 1; otherwise, a false value is
returned.

=back

=head1 TODO

=over

=item *

Add support for the various options provided by the
C<plot> method to the C<plot_all> method.

=item *

Use L<Params::Util> to check the validity of the
method arguments.

=item *

Use the next generation of L<Makefile::Parser> to do
the underlying parsing job.

=back

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of my tests,
below is the L<Devel::Cover> report on this module test suite.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  .../lib/Makefile/GraphViz.pm  100.0   93.2   71.4  100.0  100.0   61.5   92.1
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SOURCE CONTROL

For the very latest version of this module, check out the source from
the Git repository below:

L<https://github.com/agentzh/makefile-graphviz-pm>

There is anonymous access to all. If you'd like a commit bit, please let
me know. :)

=head1 BUGS

Please report bugs or send wish-list to
L<https://github.com/agentzh/makefile-graphviz-pm/issues>.

=head1 SEE ALSO

L<gvmake>, L<GraphViz>, L<Makefile::Parser>.

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) C<< <agentzh@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2014 by Yichun "agentzh" Zhang (章亦春).

This module is licensed under the terms of the BSD license.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over

=item *

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item *

Neither the name of the authors nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

