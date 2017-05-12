use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;

use List::Gather;

my ($taker) = gather {
    take sub { take 42 };
};

like exception { $taker->() },
    qr/^attempting to take after gathering already completed/;

eval 'sub { take 42 }';
like $@, qr/^illegal use of take outside of gather/;

eval 'sub { gathered }';
like $@, qr/^illegal use of gathered outside of gather/;

{
    my $gathered;
    () = gather {
        $gathered = sub { \gathered };
    };

    like exception {
        push @{ $gathered->() }, 42;
    }, qr/Modification of a read-only value attempted/;
}

eval { &gather(sub{}) };
like $@, qr/^gather called as a function/;
eval { &take(24) };
like $@, qr/^take called as a function/;
eval { &gathered(24) };
like $@, qr/^gathered called as a function/;

eval 'gather(while (0) {});';
like $@, qr/syntax error/;

if ("$]" < 5.013008) {
    eval 'gather while (0) { };';
    like $@, qr/syntax error/;
}
else {
    eval 'gather FOO: while (0) { };';
    like $@, qr/syntax error/;
}


done_testing;
