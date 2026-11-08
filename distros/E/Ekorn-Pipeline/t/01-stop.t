use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ekorn::Pipeline::Stop;

package My::Stop {
    our @ISA = 'Ekorn::Pipeline::Stop';
}

subtest 'Stop carries the arguments it was given' => sub {
    is dies { Stop() }, ['Ekorn::Pipeline::Stop'], 'none';
    is dies { Stop(1, undef, 'x') }, ['Ekorn::Pipeline::Stop', 1, undef, 'x'],
        'several, undef among them';
};

subtest 'throw is blessed into the class it was called on' => sub {
    my $stop = dies { Ekorn::Pipeline::Stop->throw(1) };
    is ref($stop), 'Ekorn::Pipeline::Stop',      'the class itself';
    is $stop,      ['Ekorn::Pipeline::Stop', 1], 'carrying its arguments';

    my $sub = dies { My::Stop->throw(2) };
    is ref($sub), 'My::Stop', 'a subclass';
    isa_ok $sub, ['Ekorn::Pipeline::Stop'], 'which is still a Stop';
    is $sub, ['My::Stop', 2], 'carrying its arguments';
};

subtest 'Stop is exported by default' => sub {

    package Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stop;
    }
    ok Importing->can('Stop'), 'by default';

    package Not::Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use Ekorn::Pipeline::Stop ();
    }
    ok !Not::Importing->can('Stop'), 'not when told not to';
};

subtest 'a Stop explains itself as a string' => sub {
    is '' . dies { Stop() }, "Stop used outside a pipeline\n";
    is '' . dies { My::Stop->throw }, "Stop used outside a pipeline\n",
        'a subclass too';
};

done_testing;
