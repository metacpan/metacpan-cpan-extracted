use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline;
use Ekorn::Pipeline::Stages::Flow;
use Ekorn::Pipeline::Stages::Taps qw(:all);

my $class = 'Ekorn::Pipeline';

subtest 'what is exported' => sub {

    package Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stages::Taps;
        ::ok __PACKAGE__->can($_),  "$_ by default" for qw(peek count_into);
        ::ok !__PACKAGE__->can($_), "not $_"        for qw(dump_to);
    }

    package None {        ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stages::Taps ();
        ::ok !__PACKAGE__->can($_), "not $_ with ()"
            for qw(peek count_into dump_to);
    }
};

subtest 'peek' => sub {
    my @seen;
    my $p = $class->new(peek { push @seen, $_; () }, sub { uc });
    local $_ = 'mine';
    is [$p->(qw(a b))], [qw(A B)],
        'passes each value on, whatever the block returns';
    is \@seen, [qw(a b)], 'having given it to the block, in $_';
    is $_,     'mine',    'leaving $_ as it was';

    my @args;
    $class->new(peek sub ($x) { push @args, $x; return (1, 2) })->(qw(c));
    is \@args, ['c'], 'and as its argument';
};

subtest 'count_into' => sub {
    my $n = 99;
    my $p = $class->new(count_into(\$n), take(2));
    is [$p->(qw(a b c))], [qw(a b)], 'passes each value on';
    is $n,                2,         'counting those it saw';
    $p->(qw(d));
    is $n, 1, 'from 0 on each run';
    $p->();
    is $n, 0, 'which, without values, is 0';
};

subtest 'dump_to' => sub {
    open my $fh, '>', \my $out or die "Can't open a string: $!";
    is [$class->new(dump_to($fh))->({b => 2, a => [1]}, 'x')],
        [{b => 2, a => [1]}, 'x'], 'passes each value on';
    close $fh;
    is $out, "{\n  'a' => [\n    1\n  ],\n  'b' => 2\n}\n'x'\n",
        'having written each, keys in order';

    open local *STDERR, '>', \my $err    ## no critic (InputOutput::ProhibitBarewordFileHandles)
        or die "Can't open a string: $!";
    $class->new(dump_to)->(1);
    is $err, "1\n", 'to STDERR by default';
};

subtest 'mistakes' => sub {
    my $peek_line = __LINE__ + 1;
    is dies { &Ekorn::Pipeline::Stages::Taps::peek('x') },    # past the prototype
        "Expected a code reference at ${\ __FILE__ } line $peek_line.\n",
        'peek, given something else';
    for my $bad (undef, 'x', [], \my @array) {
        my $line = __LINE__ + 1;
        is dies { count_into($bad) },
            "Expected a reference to a scalar at ${\ __FILE__ } line $line.\n",
            'count_into, given ' . ($bad // 'undef');
    }
    for my $bad (undef, 'x', []) {
        my $line = __LINE__ + 1;
        is dies { dump_to($bad) },
            "Expected an open filehandle at ${\ __FILE__ } line $line.\n",
            'dump_to, given ' . ($bad // 'undef');
    }
};

done_testing;
