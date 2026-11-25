use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# A source's original (roadmap 2026-0052): a source may give an original
# part, a code reference returning the original of the value it gave
# last, which result_original calls when asked, and an iterator read as
# a source passes on. A flush's values have none, whatever it says, and
# a run whose source has none is as before.

use Ekorn::Pipeline;
use Ekorn::Pipeline::Context   qw(result_number result_original);
use Ekorn::Pipeline::Factories qw(source);
use Ekorn::Pipeline::Gather;
use Ekorn::Pipeline::Stages::Batch;
use Ekorn::Pipeline::Stages::Taps qw(tee);

my $class = 'Ekorn::Pipeline';
my $here  = __FILE__;

# Return a source of the rows given, giving each row's name, and as its
# original the row it gave last, counting into $$asked how often it's
# asked. As a hash of parts, or a list, as $form says.
sub rows_of ($rows, $asked = undef, $form = 'hash') {
    return source {
        my @left = @$rows;
        my $last;
        my $step = sub () { return unless @left; $last = shift @left; $last->{name} };
        my $original = sub () { $$asked++ if $asked; $last };
        return $form eq 'list'
            ? ($step, undef, undef, $original)
            : {step => $step, original => $original};
    };
}

my @rows = map { {id => $_, name => "n$_"} } 1 .. 3;

# A stage logging "value:original's id" for each value, "-" for none.
sub log_into ($log) {
    return sub ($value) {
        my $original = result_original;
        push @$log,
            "$value:" . (ref $original ? $original->{id} : $original // '-');
        return $value;
    };
}

subtest "a source's original, as its result_original" => sub {
    for my $form (qw(hash list)) {
        my @log;
        my @got = $class->new(sub { uc $_[0] }, log_into(\@log))
            ->iterator(rows_of(\@rows, undef, $form))
            ->all;
        is \@got, [qw(N1 N2 N3)],           "$form: the values";
        is \@log, ['N1:1', 'N2:2', 'N3:3'], "$form: each value's row";
    }
};

subtest "an object's own EKORN_SOURCE" => sub {

    package My::Rows {


        sub new ($class, @rows) { bless {rows => [@rows]}, $class }


        sub EKORN_SOURCE ($self) {
            my @left = @{ $self->{rows} };
            my $last;
            return {
                step     => sub () { return unless @left; $last = shift @left; $last->{name} },
                original => sub () { $last },
            };
        }
    }
    my @log;
    $class->new(log_into(\@log))->iterator(My::Rows->new(@rows))->all;
    is \@log, ['n1:1', 'n2:2', 'n3:3'], 'the same';
};

subtest 'not asked, not called' => sub {
    my $asked = 0;
    $class->new(sub { uc $_[0] })->iterator(rows_of(\@rows, \$asked))->all;
    is $asked, 0, 'a run that never asks never calls it';
    my @log;
    $class->new(log_into(\@log))->iterator(rows_of(\@rows, \$asked))->all;
    is $asked, 3, 'once a call of result_original';
};

subtest 'through iterators read as sources' => sub {
    my @log;
    my $inner = $class->new(sub { uc $_[0] })->iterator(rows_of(\@rows));
    $class->new(log_into(\@log))->iterator($inner)->all;
    is \@log, ['N1:1', 'N2:2', 'N3:3'],
        'one: the row, not the value handed out';

    @log = ();
    my $first  = $class->new(sub { uc $_[0] })->iterator(rows_of(\@rows));
    my $second = $class->new(sub { "<$_[0]>" })->iterator($first);
    $class->new(log_into(\@log))->iterator($second)->all;
    is \@log, ['<N1>:1', '<N2>:2', '<N3>:3'], 'two';

    @log = ();
    my $plain = $class->new(sub { uc $_[0] })
        ->iterator(sub { state $n = 0; $n < 2 ? 'v' . ++$n : () });
    $class->new(log_into(\@log))->iterator($plain)->all;
    is \@log, ['V1:V1', 'V2:V2'],
        'with no part, the value handed out, as before';
};

subtest "a flush's values have none" => sub {
    my @log;
    $class->new(batch(2), sub { join ',', @{ $_[0] } }, log_into(\@log))
        ->iterator(rows_of(\@rows))
        ->all;
    is \@log, ['n1,n2:2', 'n3:-'],
        "a batch filled by a value has its row; the flush's, none";
};

subtest 'feeds and tees, unchanged' => sub {
    my @log;
    my $feed = $class->new(log_into(\@log))->feed;
    $feed->push('a');
    $feed->close;
    is \@log, ['a:a'], "a feed's stages get the value pushed";

    @log = ();
    my @branch;
    $class->new(tee(log_into(\@branch)), log_into(\@log))
        ->iterator(rows_of(\@rows))
        ->all;
    is \@log, ['n1:1', 'n2:2', 'n3:3'], 'the main run, its rows';
    is \@branch, ['n1:n1', 'n2:n2', 'n3:n3'],
        "a tee's branch, the values pushed into it";
};

subtest 'nested in itself' => sub {
    my @log;
    my $p;
    $p = $class->new(
        sub ($value) {
            return $value if $value =~ m( \A < )x;
            my @inner = $p->iterator(
                rows_of([map { {id => "$value.$_", name => "<$_>"} } 1 .. 2]))->all;
            push @log, "outer $value:" . result_original->{id};
            return "$value(@inner)";
        },
        log_into(\@log),
    );
    $p->iterator(rows_of(\@rows))->all;
    is \@log,
        [
            '<1>:n1.1', '<2>:n1.2', 'outer n1:1', 'n1(<1> <2>):1',
            '<1>:n2.1', '<2>:n2.2', 'outer n2:2', 'n2(<1> <2>):2',
            '<1>:n3.1', '<2>:n3.2', 'outer n3:3', 'n3(<1> <2>):3',
        ],
        "each run its own source's rows, and the outer's back after the inner";
};

subtest 'a part that is not a code reference croaks' => sub {
    like dies {
        $class->new->iterator(source { {step => sub () { () }, original => 'row'} })
    },
        qr( \AExpected\ the\ source's\ original\ to\ be\ a\ code\ reference\ at\ \Q$here\E\ line )x,
        'at the caller';
};

done_testing;
