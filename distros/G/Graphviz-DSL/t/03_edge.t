use strict;
use warnings;
use Test::More;

use Graphviz::DSL::Node;
use Graphviz::DSL::Edge;

subtest 'constructor' => sub {
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );
    ok $edge, 'constructor';
    isa_ok $edge, 'Graphviz::DSL::Edge';
};

subtest 'accessor' => sub {
    my $start = Graphviz::DSL::Node->new(id => 'foo');
    my $end   = Graphviz::DSL::Node->new(id => 'bar');
    my $attrs = { a => 100, b => 200 };

    my $edge = Graphviz::DSL::Edge->new(
        start => $start,
        end   => $end,
        attributes => $attrs
    );

    ok $edge->start == $start, "'start' accessor";
    ok $edge->end   == $end, "'end' accessor";
    is_deeply $edge->attributes, $attrs, "'attributes' accessor";
};

subtest 'output to string' => sub {
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo', port => 'a'),
        end   => Graphviz::DSL::Node->new(id => 'bar', port => 'b'),
    );
    my $str = $edge->as_string(1);
    is $str, '"foo":"a" -> "bar":"b"', 'as String with port';

    my $edge_noport = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
    );
    is $edge_noport->as_string(1), '"foo" -> "bar"', 'as String without port';
    is $edge_noport->as_string(0), '"foo" -- "bar"', 'as String without port(undirect)';
};

subtest 'update attributes' => sub {
    my $attrs = [[a => 100], [b => 200]];
    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo'),
        end   => Graphviz::DSL::Node->new(id => 'bar'),
        attributes => $attrs
    );

    $edge->update_attributes([[a => 300], [c => 400]]);
    my $expected = [[a => 300], [b => 200], [c => 400]];
    is_deeply $edge->attributes, $expected, 'update attributes';
};

subtest 'equal to the edge' => sub {
    Graphviz::DSL::Node->new(id => 'foo', port => 'a', compass => 's');
    Graphviz::DSL::Node->new(id => 'bar', port => 'b', compass => 'w');

    my $edge = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo', port => 'a', compass => 's'),
        end   => Graphviz::DSL::Node->new(id => 'bar', port => 'b', compass => 'w'),
    );

    ok $edge->equal_to($edge), 'equal to ID, port, compass';

    my $edge2 = Graphviz::DSL::Edge->new(
        start => Graphviz::DSL::Node->new(id => 'foo', port => 'a', compass => 'w'),
        end   => Graphviz::DSL::Node->new(id => 'bar', port => 'b', compass => 'w'),
    );
    ok !$edge->equal_to($edge2), 'equal to ID, port, but not equal to port';
};

subtest 'invalid constructor' => sub {
    eval {
        Graphviz::DSL::Edge->new;
    };
    like $@, qr/missing mandatory parameter 'start'/, "missing 'start' parameter";

    eval {
        Graphviz::DSL::Edge->new(start => 'foo');
    };
    like $@, qr/should isa/, "invalid start parameter class";

    eval {
        Graphviz::DSL::Edge->new(
            start => Graphviz::DSL::Node->new(id => 'foo'),
        );
    };
    like $@, qr/missing mandatory parameter 'end'/, "missing 'end' parameter";

    eval {
        Graphviz::DSL::Edge->new(
            start => Graphviz::DSL::Node->new(id => 'foo'),
            end   => 'foo',
        );
    };
    like $@, qr/should isa/, "invalid end parameter class";
};

done_testing;
