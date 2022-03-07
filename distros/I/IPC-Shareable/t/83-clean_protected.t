use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

my $protect_lock = 292;

# Exception testing
{
    my $no_key_ok = eval {
        IPC::Shareable::clean_up_protected;
        1;
    };

    is $no_key_ok, undef, "clean_up_protected() croaks if no key sent in";
    like $@, qr/requires/, "...and error msg is sane";

    my $key_not_int_ok = eval {
        IPC::Shareable::clean_up_protected('asf');
        1;
    };

    is $no_key_ok, undef, "clean_up_protected() croaks if key isn't an int";
    like $@, qr/integer/, "...and error msg is sane";

    tie my %test, 'IPC::Shareable', {
        key     => 100,
        create  => 1,
        exclusive => 1,
        destroy => 1,
        protected => 500,
    };

    $test{a}{b} = 2;

    my $segs = keys %{ IPC::Shareable::global_register() };
    is $segs, 2, "Before clean_up_protected(), global register has 2 segments ok";

    tied(%test)->clean_up_protected(500);

    $segs = keys %{ IPC::Shareable::global_register() };
    is $segs, 0, "After clean_up_protected() (method call), global register has 0 segments ok";

    is
        eval { IPC::Shareable::clean_up_protected(999999); 1; },
        1,
        "A call to clean_up_protected() succeeds even if protect key no exist";
}

tie my %p, 'IPC::Shareable', {
    key     => 10,
    create  => 1,
    exclusive => 1,
    destroy => 1,
    protected => $protect_lock,
};

tie my %u, 'IPC::Shareable', {
    key     => 20,
    create  => 1,
    exclusive => 1,
    destroy => 1,
};

$p{one}{two} = 1;
$u{one}{two} = 1;

my $segs = keys %{ IPC::Shareable::global_register() };
is $segs, 4, "Before clean_up_all(), global register has 4 segments ok";

IPC::Shareable::clean_up_all;

$segs = keys %{ IPC::Shareable::global_register() };
is $segs, 2, "After clean_up_all(), global register has 2 segments ok";

IPC::Shareable::clean_up_protected($protect_lock);

$segs = keys %{ IPC::Shareable::global_register() };
is $segs, 0, "After clean_up_protected(), global register has 0 segments ok";

done_testing();
