package GraphViz2::Parse::Regexp;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '2.48';

use IPC::Run3; # For run3().
use GraphViz2;
use Moo;
use Graph::Directed;

my %GRAPHVIZ_ARGS = (
    edge   => {color => 'grey'},
    global => {directed => 1},
    graph  => {rankdir => 'TB'},
    node   => {color => 'blue', shape => 'oval'},
);
my %STATE2LABEL = (
    PLUS => '+',
    STAR => '*',
);
my %NODETYPE2ARGS = (
    exact => { shape => 'box', color => 'black' },
    anyof => { shape => 'box', color => 'red' },
    branch => { shape => 'diamond' },
);
my %TYPE2LABEL = (
    anyof => sub { "[$_[0]]" },
    exact => sub { $_[0] },
    open => sub { "START \$$_[0]" },
    close => sub { "END \$$_[0]" },
    repeat => sub { "REPEAT $_[0]" },
    branch => sub { '' },
    nothing => sub { 'Match empty string' },
    minmod => sub { 'Next operator\nnon-greedy' },
    succeed => sub { 'SUCCEED' },
);
my %EDGETYPE2ARGS = (
    of => { style => 'dashed' },
    cond => { style => 'dashed' },
);
sub maybe_subgraph {
    my ($g, $v) = @_;
    return unless my @e = grep $g->get_edge_attribute(@$_, 'type'), $g->edges_from($v);
    {
        attributes => { subgraph => { rank => 'same' } },
        nodes => [ $v, map $_->[1], @e ],
    };
}

has as_graph => (
    is       => 'lazy',
    required => 0,
);
sub _build_as_graph { to_graph($_[0]->regexp) }

sub to_graph {
    my ($regexp) = @_;
    my $g = Graph::Directed->new;
    run3
            [$^X, '-Mre=debug', '-e', q|qr/$ARGV[0]/|, $regexp],
            undef,
            \my $stdout,
            \my $stderr,
            ;
    my (%following, %states, $last_id);
    for my $line ( split /\n/, $stderr ) {
        next unless my ($id, $state) = $line =~ /(\d+):\s+(.+)$/;
        $states{$id}         = $state;
        $following{$last_id} = $id if $last_id;
        $last_id             = $id;
    }
    die 'Error compiling regexp' if !defined $last_id;
    my %done;
    my @todo = (1);
    while (@todo) {
        my $id = pop @todo;
        next if !$id or $done{$id}++;
        my $state     = $states{$id} || '';
        my $following = $following{$id};
        $state =~ s/\s*\((\d+)\)$//;
        my $next = $1;
        push @todo, $following;
        push @todo, $next if $next;
        my $match;
        if ( ($match) = $state =~ /^EXACTF?L? <(.+)>$/ ) {
            $g->set_vertex_attributes($id, { type => 'exact', content => $match });
            $g->add_edge($id, $next) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( ($match) = $state =~ /^ANYOF\[(.+)\]/ ) {
            $g->set_vertex_attributes($id, { type => 'anyof', content => $match });
            $g->add_edge($id, $next) if $next != 0;
            $done{$following}++ unless $next;
        } elsif ( (my $matchtype, $match) = $state =~ /^(OPEN|CLOSE)(\d+)/ ) {
            $g->set_vertex_attributes($id, { type => lc $matchtype, content => $match });
            $g->add_edge($id, $matchtype eq 'OPEN' ? $following : $next);
        } elsif ( $state =~ /^BRANCH/ ) {
            my $branch = $next;
            my @children;
            push @children, $following;
            while ($branch && ($states{$branch}||'') =~ /^BRANCH|TAIL/ ) {
                $done{$branch}++;
                push @children, $following{$branch};
                push @todo, $following{$branch};
                ($branch) = $states{$branch} =~ /(\d+)/;
            }
            $g->set_vertex_attributes($id, { type => lc $state });
            $g->add_edges(map [$id, $_], @children);
        } elsif ( my ($repetition) = $state =~ /^(PLUS|STAR)/ ) {
            $g->set_vertex_attributes($id, { type => 'repeat', content => $STATE2LABEL{$repetition} });
            $g->set_edge_attributes($id, $following, { type => 'of' });
            $g->add_edge($id, $next);
        } elsif ( my ( $type, $min, $max )
            = $state =~ /^CURLY([NMX]?)\[?\d*\]?\s*\{(\d+),(\d+)\}/ )
        {
            $g->set_vertex_attributes($id, { type => 'repeat', content => "{$min,$max}" });
            $g->set_edge_attributes($id, $following, { type => 'of' });
            $g->add_edge($id, $next);
        } elsif ( $state =~ /^SUCCEED/ ) {
            $g->set_vertex_attributes($id, { type => lc $state });
            $done{$following}++;
        } elsif ( $state =~ /^(UNLESSM|IFMATCH|IFTHEN)/ ) {
            $g->set_vertex_attributes($id, { type => lc $state });
            $g->set_edge_attributes($id, $following, { type => 'cond' });
            $g->add_edge($id, $next);
        } else {
            $g->set_vertex_attributes($id, { type => lc $state });
            $g->add_edge($id, $next) if ($next||0) != 0;
        }
    }
    $g;
}

has graph => (
    is       => 'lazy',
    #isa     => 'GraphViz2',
    required => 0,
);
sub _build_graph {
    GraphViz2->new(%GRAPHVIZ_ARGS)->from_graph(graphvizify($_[0]->as_graph));
}

has regexp => (
    is       => 'rw',
    required => 0,
);

sub create {
    my ($self, %arg) = @_;
    $self->regexp($arg{regexp});
    $self->graph->from_graph(graphvizify($self->as_graph));
    return $self;
}

sub graphvizify {
    my ($g) = @_;
    my @groups;
    for my $v (sort $g->vertices) {
        push @groups, maybe_subgraph($g, $v);
        my $attrs = $g->get_vertex_attributes($v);
        my $type = $attrs->{type};
        my $labelmaker = $TYPE2LABEL{$type};
        my $label = $labelmaker ? $labelmaker->(GraphViz2::_dor($attrs->{content}, '')) : uc $type;
        $g->set_vertex_attribute($v, graphviz => { label => $label, %{$NODETYPE2ARGS{$type}||{}} });
        for my $e (sort {$a->[1] cmp $b->[1]} $g->edges_from($v)) {
            my $e_attrs = $g->get_edge_attributes(@$e);
            my $e_type = $e_attrs->{type};
            $g->set_edge_attribute(@$e, graphviz => $EDGETYPE2ARGS{$e_type||''}||{});
        }
    }
    $g->set_graph_attribute(graphviz => { groups => \@groups });
    $g;
}

1;

=pod

=head1 NAME

L<GraphViz2::Parse::Regexp> - Visualize a Perl regular expression as a graph

=head1 SYNOPSIS

    use GraphViz2::Parse::Regexp;
    # no objects - quicker
    my $gd = GraphViz2::Parse::Regexp::to_graph('(([abcd0-9])|(foo))');

    # populate a GraphViz2 object with a Graph::Directed of a regexp
    my $gv = GraphViz2->from_graph(GraphViz2::Parse::Regexp::graphvizify($gd));

    # OO interface, using lazy-built attributes
    my $gvre = GraphViz2::Parse::Regexp->new(regexp => $regexp);
    my $gd = $gvre->as_graph; # Graph::Directed object
    # or supply a suitable Graph::Directed object
    my $gvre = GraphViz2::Parse::Regexp->new(as_graph => $gd);
    # then get the GraphViz2 object
    my $gv = $gvre->graph;

    # DEPRECATED ways to get $gvre with populated $gv
    my $gvre = GraphViz2::Parse::Regexp->new;
    $gvre->create(regexp => '(([abcd0-9])|(foo))');
    my $gv = $gvre->graph;
    # or give it a pre-set-up GraphViz2 object
    my $gv = GraphViz2->new(...);
    my $gvre = GraphViz2::Parse::Regexp->new(graph => $gv);
    # call ->create as above

    # produce a visualisation
    my $format = shift || 'svg';
    my $output_file = shift || "output.$format";
    $gv->run(format => $format, output_file => $output_file);

See F<t/gen.parse.regexp.t>.

=head1 DESCRIPTION

Takes a Perl regular expression and converts it into a L<Graph::Directed>
object, or directly into a L<GraphViz2> object.

=head1 FUNCTIONS

This is the recommended interface.

=head2 to_graph

    my $gd = GraphViz2::Parse::Regexp::to_graph('(([abcd0-9])|(foo))');

Given a Perl regular expression, returns a L<Graph::Directed> object
describing the finite state machine for it.

=head2 graphvizify

    my $gv = GraphViz2->from_graph(GraphViz2::Parse::Regexp::graphvizify($gd));

Mutates the given graph object to add to it the C<graphviz> attributes
visualisation "hints" that will make the L<GraphViz2/from_graph> method
visualise this regular expression in the most meaningful way, including
labels and groupings.

It is idempotent as it simply sets the C<graphviz> attribute of the
relevant graph entities.

Returns the graph object for convenience.

=head1 METHODS

This is a L<Moo> class, but with a recommended functional interface.

=head2 Constructor attributes

=head3 regexp

The regular expression to use.

This key is optional. You need to provide it by the time you access
either the L</as_graph> or L</graph>.

=head3 as_graph

The L<Graph::Directed> object to use. If not given, will be lazily built
on access, from the L</regexp>.

=head3 graph

The L<GraphViz2> object to use. This allows you to configure it as desired.

This key is optional. If provided, the C<create> method will populate it.
If not, it will have these defaults, lazy-built and populated from the
L</as_graph>.

    my $gv = GraphViz2->new(
            edge   => {color => 'grey'},
            global => {directed => 1},
            graph  => {rankdir => 'TB'},
            node   => {color => 'blue', shape => 'oval'},
    );

=head2 create(regexp => $regexp)

DEPRECATED. Mutates the object to set the C<regexp> attribute, then
accesses the C<as_graph> attribute (possibly lazy-building it), then
C<graphvizify>s its C<as_graph> attribute with that information, then
C<from_graph>s its C<graph>.

Returns $self for method chaining.

=head1 THANKS

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 AUTHOR

L<GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 COPYRIGHT

Australian copyright (c) 2011, Ron Savage.

All Programs of mine are 'OSI Certified Open Source Software';
you can redistribute them and/or modify them under the terms of
The Perl License, a copy of which is available at:
http://dev.perl.org/licenses/

=cut
