use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Operators: what the proofs in t/15-proofs.t don't
# reach (roadmap 2026-0018).

use Ekorn::Pipeline;
use Ekorn::Pipeline::Factories qw(stage);
use Ekorn::Pipeline::Sinks     qw(keep_all count_items);
use Ekorn::Pipeline::Sources   qw(from_array);
use Ekorn::Pipeline::Operators;

my $file = __FILE__;

subtest 'chain and drain, called as functions' => sub {
    my $chain
        = Ekorn::Pipeline::Operators::chain(from_array(1, 2), stage { $_ * 10 });
    is Ekorn::Pipeline::Operators::drain($chain), [10, 20],
        'as a package\'s own overloads call them';
};

subtest '|= makes a new chain, in the variable' => sub {
    my $source = from_array(1, 2, 3);
    my $chain  = $source;
    $chain |= stage { $_ + 1 };
    is $chain | keep_all, [2, 3, 4];
    is $source | keep_all, [1, 2, 3], 'leaving what it was made from as it was';
};

subtest 'What the left of | can be' => sub {
    my $object = bless {}, 'My::Neither';
    like dies {
        my $x = $object | stage { $_ }
    },
        qr( \A Expected\ a\ source,\ or\ a\ stage\ made\ with\ a\ word,\ on\ the\ left\ of\ \|\  )x,
        'an object that is neither a source nor a stage croaks';
};

subtest 'Out of scope, | croaks' => sub {
    my($source, $stage) = (from_array(1), stage { $_ });
    {
        no Ekorn::Pipeline::Operators;
        my $line = __LINE__ + 1;
        is dies { my $x = $source | $stage },
            "Expected use Ekorn::Pipeline::Operators in scope, for | at $file line $line.\n",
            'where no Ekorn::Pipeline::Operators took it out';
        like dies { my @all = @{ $source } },
            qr( \A Expected\ use\ Ekorn::Pipeline::Operators\ in\ scope,\ for\ \@\{\}\  )x,
            'and @{}';
    }
    my $died;
    {
        # Code compiled with no hints at all, as with no pragma in force.
        BEGIN { %^H = () }
        $died = eval { my $x = $source | $stage; 1 } ? '' : $@;
    }
    like $died, qr( \A Expected\ use\ Ekorn::Pipeline::Operators\ in\ scope )x,
        'and where nothing is in force';
};

done_testing;
