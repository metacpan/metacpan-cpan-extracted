#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep qw(cmp_deeply);
use Getopt::Modular -namespace => 'GM';
use List::MoreUtils qw(all);
my $e;

# Exception types.

#### unknown-option

# I actually can't find a way to trigger this to test it.



#### getopt-long-failure

# tested in parse_param.t


#### valid-values-error
TODO: {
    local $TODO = 'Need to validate this earlier, too';
    dies_ok {
        GM->acceptParam(
                        invalid => {
                            default => 0,
                            spec => '=s',
                            valid_values => {}
                        }
                       )
    };
    is(eval {$@->type()}, 'valid-values-error');
};

throws_ok {
    GM->setOpt('invalid',3);
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'valid-values-error');

#### no-such-option
GM->setMode('strict');
throws_ok {
    GM->getOpt('no-such-param');
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'no-such-option');

#### set-int-failure
GM->acceptParam(
                int => {
                    spec => '=i',
                }
               );
throws_ok {
    GM->setOpt(int => 0.1);
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'set-int-failure');
is(eval {$e->option()}, 'int');
is(eval {$e->value()}, 0.1);

throws_ok {
    GM->setOpt(int => 'int');
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'set-int-failure');
is(eval {$e->option()}, 'int');
is(eval {$e->value()}, 'int');

lives_ok {
    GM->setOpt(int => -1);
    is(GM->getOpt('int'), -1);

    GM->setOpt(int => 0);
    is(GM->getOpt('int'), 0);

    GM->setOpt(int => 1);
    is(GM->getOpt('int'), 1);

    GM->setOpt(int => 85916);
    is(GM->getOpt('int'), 85916);
};

#### set-real-failure
GM->acceptParam(
                real => {
                    spec => '=f',
                }
               );
throws_ok {
    GM->setOpt(real => 'really');
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'set-real-failure');
is(eval {$e->option()}, 'real');
is(eval {$e->value()}, 'really');

lives_and {
    GM->setOpt(real => -1);
    is(GM->getOpt('real'), -1);

    GM->setOpt(real => 0);
    is(GM->getOpt('real'), 0);

    GM->setOpt(real => 1);
    is(GM->getOpt('real'), 1);

    GM->setOpt(real => 85916);
    is(GM->getOpt('real'), 85916);

    GM->setOpt(real => 85.916);
    is(GM->getOpt('real'), 85.916);
};


#### validate-failure
GM->acceptParam(
                'needs-val-scalar' => {
                    spec => '=s',
                    validate => sub {
                        /^abc/i
                    },
                },
                'needs-val-array' => {
                    spec => '=s@',
                    validate => sub {
                        all { /^abc/i } @$_
                    },
                },
                'needs-val-hash' => {
                    spec => '=s%',
                    validate => sub {
                        all { /^a/i } keys %$_ and
                        all { /z$/i } values %$_
                    },
                },
               );

throws_ok {
    GM->setOpt('needs-val-scalar' => 1);
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'validate-failure');
is(eval {$e->option()}, 'needs-val-scalar');
is(eval {$e->value()}, 1);

throws_ok {
    GM->setOpt('needs-val-array' => 'xyz');
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'validate-failure');
is(eval {$e->option()}, 'needs-val-array');
is(eval {$e->value()}, 'xyz');

throws_ok {
    GM->setOpt('needs-val-hash' => xyz => 'abc');
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'validate-failure');
is(eval {$e->option()}, 'needs-val-hash');
is(eval {$e->value()}, 'xyz=abc');

lives_and {
    GM->setOpt('needs-val-scalar' => 'abcdef');
    is(GM->getOpt('needs-val-scalar'), 'abcdef');

    GM->setOpt('needs-val-scalar' => 'ABCdef');
    is(GM->getOpt('needs-val-scalar'), 'ABCdef');

    GM->setOpt('needs-val-array' => [ 'abcdef', 'ABCdef' ]);
    is(join(':',GM->getOpt('needs-val-array')), 'abcdef:ABCdef');

    GM->setOpt('needs-val-array' => 'abcdef', 'ABCdefg' );
    is(join(':',GM->getOpt('needs-val-array')), 'abcdef:ABCdefg');

    my %h = (a => z => ab => yz =>);
    GM->setOpt('needs-val-hash' => { %h });
    cmp_deeply(scalar GM->getOpt('needs-val-hash'), \%h);

    $h{ac} = 'wz';
    GM->setOpt('needs-val-hash' => %h );
    cmp_deeply(scalar GM->getOpt('needs-val-hash'), \%h);
};

#### wrong-type
throws_ok {
    GM->setOpt('needs-val-hash' => [ qw{a b c} ]);
} 'Getopt::Modular::Exception';
$e = $@;
is(eval {$e->type()}, 'wrong-type');
is(eval {$e->option()}, 'needs-val-hash');
cmp_deeply(eval {$e->value()}, [ qw{a b c} ]);


done_testing();
