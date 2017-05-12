#!perl
use strict;
use warnings;
use 5.0100;
use Test::More 0.94 tests => 3;
use Test::Builder 0.94 qw();

use Lingua::Boolean;
my $bool = Lingua::Boolean->new();

subtest 'yes' => sub {   #YES
    my @yes = (' y', 'yes ', 'ok', 'on', 'Y', 'YES', 'OK', 'ON', 1, 2);
    plan tests => scalar @yes * 3;
    foreach my $word (@yes) {
        ok($bool->boolean($word), "$word is true");
        is($bool->boolean($word), $bool->boolean($word, 'en'),  q{Default 'en' applied OK});
        is(boolean($word), $bool->boolean($word),               q{OO and functional interfaces match});
    }
};

subtest 'no' => sub {   # NO
    my @no = ('n ', ' no', 'off', 'not ok', 'N', 'NO', 'OFF', 'NOTOK', 0);
    plan tests => scalar @no * 3;
    foreach my $word (@no) {
        ok(! $bool->boolean($word), "$word is false");
        is($bool->boolean($word), $bool->boolean($word, 'en'),  q{Default 'en' applied OK});
        is(boolean($word), $bool->boolean($word),               q{OO and functional interfaces match});
    }
};

subtest 'fail' => sub { # nonsense
    my @nonsense = qw(one two three);
    plan tests => scalar @nonsense * 2;
    foreach my $word (@nonsense) {
        { # OO
            eval {
                $bool->boolean($word);
            };
            like($@, qr{^'$word' isn't recognizable as either true or false}, "$word is nonsense - OO");
        }
        { # Functional
            eval {
                boolean($word);
            };
            like($@, qr{^'$word' isn't recognizable as either true or false}, "$word is nonsense - functional");
        }
    }
};
