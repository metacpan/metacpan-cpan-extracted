use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Parts returned by name: a role method, or a set-up made with a word,
# may return a hash reference of step, flush, end and context in place
# of the list (roadmap 2026-0026).

use Ekorn::Pipeline;
use Ekorn::Pipeline::Factories qw(:all);

my $class = 'Ekorn::Pipeline';
my $file  = __FILE__;

# A class whose role method returns the hash it was made with.
package My::Stage {
    use parent 'Ekorn::Pipeline::Element';


    sub new ($class, %parts) {
        bless {call => sub { $_ }, parts => {%parts}}, $class;
    }
    sub EKORN_STAGE ($self) { return {%{ $self->{parts} }} }
}

package My::Source {
    sub new          ($class, %parts) { bless {parts => {%parts}}, $class }
    sub EKORN_SOURCE ($self)          { return {%{ $self->{parts} }} }
}

subtest 'A source: step, end and context' => sub {
    my($how, $seen);
    my @values = (1, 2, 3);
    my $source = source {
        my @left = @values;
        return {
            step    => sub () { @left ? shift @left : () },
            end     => sub ($ended) { $how = $ended },
            context => 'columns',
        };
    };
    my $next = $class->new(sub { $seen = Ekorn::Pipeline::run_context(); $_ })
        ->iterator($source);
    is [$next->all], [1, 2, 3], 'its step read';
    is $how,         'done',    'its end told';
    is $seen,        'columns', 'its context given';

    my $own = My::Source->new(
        step => do {
            my $n = 0;
            sub () { $n++ < 2 ? $n : () }
        },
    );
    is [$class->new->iterator($own)->all], [1, 2],
        'from a role method of a class of its own';
};

subtest 'A stage: step, flush and end' => sub {
    my $how;
    my $stage = My::Stage->new(
        step  => sub ($x) { $x * 10 },
        flush => sub () { 'last' },
        end   => sub ($ended) { $how = $ended },
    );
    is [$class->new($stage)->(1, 2)], [10, 20, 'last'], 'step and flush';

    is $how, 'done', 'and end';
    is [$class->new(My::Stage->new(step => sub ($x) { $x + 1 }))->(1)], [2],
        'with only a step';
};

subtest 'A gather: step, flush and end' => sub {
    my $how;
    my $batches = gather {
        my @batch;
        return {
            step => sub ($x) {
                push @batch, $x;
                return @batch == 2 ? [splice @batch] : ();
            },
            flush => sub () { @batch ? [@batch] : () },
            end   => sub ($ended) { $how = $ended },
        };
    };
    is [$class->new($batches)->(1, 2, 3)], [[1, 2], [3]];
    is $how, 'done', 'its end told';

    my $ended;
    my $end_only = gather {
        {step => sub ($x) { $x }, end => sub ($e) { $ended = $e }}
    };
    is [$class->new($end_only)->(1)], [1],
        'an end with no flush, and no undef for it';
    is $ended, 'done';

    my $piped = gather {
        {step => pipeline(sub { $_ * 2 }), flush => sub () { 'last' }}
    };
    is [$class->new($piped)->(1, 2)], [2, 4, 'last'], 'a pipeline as its step';
};

subtest 'A sink: step, flush and end' => sub {
    my $how;
    my $count = sink_one {
        my $n = 0;
        return {
            step  => sub ($x) { $n++ },
            flush => sub () { $n },
            end   => sub ($ended) { $how = $ended },
        };
    };
    is scalar $class->new($count)->(7, 8, 9), 3, 'of one';

    is $how, 'done', 'its end told';

    my $all = sink_many {
        my @kept;
        return {step => sub ($x) { push @kept, $x }, flush => sub () { @kept }};
    };
    is [$class->new($all)->(1, 2)], [1, 2], 'of many';
};

subtest 'Keys Ekorn does not read are ignored' => sub {
    my $stage
        = My::Stage->new(step => sub ($x) { $x }, flsuh => sub () { 'never' });
    is [$class->new($stage)->(1)], [1],
        'so a stage with a misspelt flush has none';
    my $source = source {
        my $done = 0;
        {step => sub () { $done++ ? () : 'a' }, columns => ['x']}
    };
    is [$class->new->iterator($source)->all], ['a'],
        'and a source with a key of its own';
};

subtest 'A hash without what its role needs croaks, as a list would' => sub {
    my $stepless = My::Stage->new(flush => sub () { 1 });
    my $line     = __LINE__ + 1;
    is dies { $class->new($stepless)->(1) },
        "Expected stage #1 to return a code reference, and optionally a flush and an end at $file line $line.\n",
        'a stage without a step';
    like dies {
        $class->new(sink_one { {step => sub ($x) { }, flsuh => sub () { 1 }} })->(1)
    },
        qr( \A Expected\ sink\ \#1\ to\ return\ a\ code\ reference,\ a\ flush )x,
        'a sink without a flush, misspelt';
    like dies {
        $class->new(gather { {} })->(1)
    },
        qr( \A Expected\ stage\ \#1,\ made\ with\ gather,\ to\ return )x,
        'a gather, empty';
    like dies {
        $class->new(My::Stage->new(step => sub ($x) { $x }, end => 'not code'))->(1)
    },
        qr( \A Expected\ stage\ \#1\ to\ return )x,
        'or with a part that isn\'t code';
    like dies {
        $class->new->iterator(My::Source->new(end => sub ($e) { }))
    },
        qr( \A Expected\ the\ source\ to\ return\ a\ code\ reference )x,
        'a source without a step';
};

subtest 'Only a plain hash reference, returned alone, is named parts' => sub {
    like dies {
        $class->new(gather { ({step => sub ($x) { $x }}, sub () { }) })->(1)
    },
        qr( \A Expected\ stage\ \#1,\ made\ with\ gather )x,
        'not one among others';
    my $object = bless {step => sub ($x) { $x }}, 'My::Hashy';
    like dies {
        $class->new(gather { $object })->(1)
    },
        qr( \A Expected\ stage\ \#1,\ made\ with\ gather )x,
        'nor an object';
};

done_testing;
