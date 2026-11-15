use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Factories: each word makes its type, as one line over
# a class method (roadmap 2026-0021). What the types do is tested with
# them; generator and yield are in t/15-proofs.t.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Factories qw(:all);
use Ekorn::Pipeline::Gather    qw();

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;

subtest 'Nothing is exported by default' => sub {

    package My::Plain {
        use Ekorn::Pipeline::Factories;
    }
    ok !My::Plain->can($_), "not $_"
        for qw(pipeline stage gather source generator yield sink_one sink_many);
};

subtest 'Each word makes its type' => sub {
    isa_ok pipeline(), [$class], 'pipeline';
    isa_ok(stage { $_ }, ['Ekorn::Pipeline::Stage'], 'stage');
    isa_ok(
        gather {
            sub { $_ }
        },
        ['Ekorn::Pipeline::Gather'],
        'gather',
    );
    isa_ok(
        source {
            sub { () }
        },
        ['Ekorn::Pipeline::Source'],
        'source',
    );
    isa_ok(generator { return }, ['Ekorn::Pipeline::Source'], 'generator');
    isa_ok(
        sink_one { (sub { }, sub { 1 }) }, ['Ekorn::Pipeline::Sink::One'],
        'sink_one',
    );
    isa_ok(
        sink_many { (sub { }, sub { 1 }) }, ['Ekorn::Pipeline::Sink::Many'],
        'sink_many',
    );
    ref_is \&gather, \&Ekorn::Pipeline::Gather::gather,
        "gather is Gather's own";
};

subtest 'pipeline looks names up in the package that calls it' => sub {

    package My::Words {
        use Ekorn::Pipeline::Factories qw(pipeline);
        Ekorn::Pipeline->named(shout => sub { uc });
        sub make (@stages) { pipeline(@stages) }
    }
    is [My::Words::make('shout')->('a')], ['A'];
    like dies { pipeline('shout') },
        qr( \A No\ pipeline\ named\ main::shout\  )x,
        'not in the package that defined the word';
};

subtest 'A word given what is not code croaks, at the caller\'s line' => sub {
    for my $word (qw(stage gather source generator sink_one sink_many)) {
        my $code = \&{ "Ekorn::Pipeline::Factories::$word" };
        my $line = __LINE__ + 1;
        is dies { $code->('x') },
            "Expected a code reference at $file line $line.\n",
            $word;
    }
};

done_testing;
