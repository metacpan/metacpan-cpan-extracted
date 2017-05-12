#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    eval "use GraphViz; use Text::Wrap";
    plan $@
        ? (skip_all => "GraphViz or Text::Wrap cannot be loaded.")
        #: ('no_plan');
        : (tests => 12);
    use_ok 'FSA::Rules' or die;
}

ok my $fsa = FSA::Rules->new(
    ping => {
        do => sub { state->machine->{count}++ },
        rules     => [
            end  => sub { shift->machine->{count} >= 20 },
            pong => sub { 1 },
        ],
    },
    pong => {
        do => sub { shift->machine->{count}++ },
        rules     => [
            end  => sub { shift->machine->{count} >= 20 },
            ping => sub { 1 },
        ],
    },
    end => {}
), "Create the ping pong FSA machine";

can_ok $fsa, 'graph';
ok my $graph = $fsa->graph, 'Get a GraphViz object';
isa_ok $graph, 'GraphViz', 'it';
if ($ENV{DEVTEST}) {
    open FOO, '>', 'pingpong.png' or die $!;
    print FOO $fsa->graph->as_png;
    close FOO;
}

my $expected = <<'END_TEXT';
digraph test {
        ratio="fill";
        ping [label="ping"];
        end [label="end"];
        pong [label="pong"];
        ping -> end;
        ping -> pong;
        pong -> end;
        pong -> ping;
}
END_TEXT

my $graph_text = $fsa->graph->as_debug;
$graph_text    =~ s/\t/        /g;
$graph_text    =~ s/\015?\012/\n/g;
is $graph_text, $expected,
  '... and it should return a text version of the graph.';
$graph_text = $fsa->graph->as_debug;
$graph_text    =~ s/\t/        /g;
$graph_text    =~ s/\015?\012/\n/g;
is $graph_text, $expected,
  '... and I should be able to call it multiple times and get the same results.';

ok $fsa = FSA::Rules->new(
    ping => {
        label => 'Can we ping it, can we, huh?',
        do => sub { state->machine->{count}++ },
        rules     => [
            end  => {
                rule => sub { shift->machine->{count} >= 20 },
                message => 'Enough Iterations (ping)'
            },
            pong => sub { 1 },
        ],
    },
    pong => {
        do => sub { shift->machine->{count}++ },
        rules     => [
            end  => {
                rule => sub { shift->machine->{count} >= 20 },
                message => 'Enough Iterations'
            },
            ping => sub { 1 },
        ],
    },
    end => {}
), "We can use rule labels in creating the state machine.";

can_ok $fsa, 'graph';
isa_ok $fsa->graph, 'GraphViz';
$expected = <<'END_TEXT';
digraph test {
        ratio="fill";
        bgcolor="magenta";
        node [shape="circle"];
        ping [label="ping\n\nCan we ping\nit, can we,\nhuh?"];
        end [label="end"];
        pong [label="pong"];
        ping -> end [decorate="1", label="Enough\nIterations\n(ping)"];
        ping -> pong [decorate="1"];
        pong -> end [decorate="1", label="Enough\nIterations"];
        pong -> ping [decorate="1"];
}
END_TEXT

$graph = $fsa->graph(
    {
        wrap_length      => 15,
        wrap_node_labels => 1,
        wrap_edge_labels => 1,
        with_state_name  => 1,
        edge_params      => { decorate => 1 },
    },
    bgcolor => 'magenta',
    node    => { shape => 'circle' },
);

$graph_text = $graph->as_debug;
$graph_text    =~ s/\t/        /g;
$graph_text    =~ s/\015?\012/\n/g;
is $graph_text, $expected,
  '... and it should properly handle wrapping parameters';

$graph = $fsa->graph(
    {
        with_state_name => 1,
        text_wrap       => 15,
        wrap_labels     => 1,
        wrap_nodes      => 1,
        edge_params     => { decorate => 1 },
    },
    bgcolor => 'magenta',
    node    => { shape => 'circle' },
);

$graph_text = $graph->as_debug;
$graph_text    =~ s/\t/        /g;
$graph_text    =~ s/\015?\012/\n/g;
is $graph_text, $expected,
    '... And it should handle deprecated wrapping parameters';
