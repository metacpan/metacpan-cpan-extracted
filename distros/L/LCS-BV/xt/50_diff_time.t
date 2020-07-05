#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

use Benchmark qw(:all) ;

use LCS::BV;
use LCS;
use Algorithm::Diff;
use Algorithm::Diff::XS;

my @data = (
  [split(//,'Chrerrplzon')],
  [split(//,'Choerephon')]
);

my @strings = qw(Chrerrplzon Choerephon);

my @data2 = (
  [split(//,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY')],
  [split(//, 'bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')]
);

my @strings2 = qw(
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY
bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
);

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);

my @strings3 = map { join('',@$_) } @data3;


print "\n",'LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV',"\n","\n";

print 'LCS: [Chrerrplzon] [Choerephon]',"\n","\n";

if (1) {
    timethese( 50_000, {
        'AD:LCSidx___' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
        'AD:XS:LCSidx' => sub {
            Algorithm::Diff::XS::LCSidx(@data)
        },
        'LCS:BV:LCS__' => sub {
            LCS::BV->LCS(@data)
        },
        'LCS:LCS_____' => sub {
            LCS::->LCS(@data)
        },
    });
}

print "\n",'LCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]',"\n","\n";

if (1) {
    timethese( 3_000, {
        'AD:LCSidx___' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'AD:XS:LCSidx' => sub {
            Algorithm::Diff::XS::LCSidx(@data3)
        },
        'LCS:BV:LCS__' => sub {
            LCS::BV->LCS(@data3)
        },
        'LCS:LCS_____' => sub {
            LCS::->LCS(@data3)
        },
    });
}

print "\n",'LLCS: [Chrerrplzon] [Choerephon]',"\n","\n";

if (1) {
    timethese( 30_000, {
        'AD:LCS_length___' => sub {
            Algorithm::Diff::LCS_length(@data)
        },
        'AD:XS:LCS_length' => sub {
            Algorithm::Diff::XS::LCS_length(@data)
        },
        'LCS:BV:LLCS_____' => sub {
            LCS::BV->LLCS(@data)
        },
        'LCS:LLCS________' => sub {
            LCS->LLCS(@data)
        },
    });
}

print "\n",'LLCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]',"\n","\n";

if (1) {
    timethese( 2_000, {
        'AD:LCS_length___' => sub {
            Algorithm::Diff::LCS_length(@data3)
        },
        'AD:XS:LCS_length' => sub {
            Algorithm::Diff::XS::LCS_length(@data3)
        },
        'LCS:BV:LLCS_____' => sub {
            LCS::BV->LLCS(@data3)
        },
        'LCS:LLCS________' => sub {
            LCS->LLCS(@data3)
        },
    });
}



