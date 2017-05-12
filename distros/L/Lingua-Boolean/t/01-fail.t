#!perl
use strict;
use warnings;
use Test::More 0.94 tests => 3;
use Test::Builder 0.94;

use Lingua::Boolean;
use experimental qw/smartmatch/;

my $lang = 'nonexistent';
my $bool = Lingua::Boolean->new();

my @languages = $bool->languages();
ok(!($lang ~~ @languages), "$lang isn't available");

subtest 'yes' => sub {   #YES
    my @yes = ('y', 'yes', 'ok', 'on', 'Y', 'YES', 'OK', 'ON', 1, 2);
    plan tests => scalar @yes * 2;

    foreach my $word (@yes) {
        { # OO
            eval {
                $bool->boolean($word, $lang);
            };
            like($@, qr{^I don't know anything about the language '$lang'}o, 'failed OK');
        }
        { # Functional
            eval {
                boolean($word, $lang);
            };
            like($@, qr{^I don't know anything about the language '$lang'}o, 'failed OK');
        }
    }
};

subtest 'no' => sub {   # NO
    my @no = ('n', 'no', 'off', 'not ok', 'N', 'NO', 'OFF', 'NOTOK', 0);
    plan tests => scalar @no * 2;

    foreach my $word (@no) {
        { # OO
            eval {
                $bool->boolean($word, $lang);
            };
            like($@, qr{^I don't know anything about the language '$lang'}o, 'failed OK');
        }
        { # Functional
            eval {
                boolean($word, $lang);
            };
            like($@, qr{^I don't know anything about the language '$lang'}o, 'failed OK');
        }
    }
};
