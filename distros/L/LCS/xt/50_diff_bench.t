#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

#use Test::More;

use Algorithm::Diff;
use Algorithm::Diff::XS;
use String::Similarity;
use String::LCSS_XS qw(lcss lcss_all);
#use Algorithm::LCS;

use Benchmark qw(:all) ;
use Data::Dumper;

#use Align::Sequence;
use LCS::Tiny;
use LCS;

#my $align = Align::Sequence->new;

my $align_bv = LCS::Tiny->new;
my $traditional = LCS->new();

#my $A_LCS = Algorithm::LCS->new();

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

print STDERR 'S::Similarity: ',similarity(@strings),"\n";
print STDERR 'S::LCSS_XS: ',Dumper([ lcss_all('Chrerrplzon','Choerephon') ]),"\n";


if (0) {
    cmpthese( 50_000, {
       'LCS' => sub {
            $traditional->LCS(@data)
        },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data)
        },
        'LCSnew' => sub {
            $align_bv->LCS(@data)
        },
        'S::Sim' => sub {
            similarity(@strings)
        },
        'S::LCSS_XS' => sub {
            [ lcss('Chrerrplzon','Choerephon') ]
        },
    });
}

if (0) {
    cmpthese( 10_000, {
       'LCS' => sub {
            $traditional->LCS(@data2)
        },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data2)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data2)
        },
        'LCSnew' => sub {
            $align_bv->LCS(@data2)
        },
        'S::Sim' => sub {
            similarity(@strings2)
        },
    });
}

if (1) {
    cmpthese( 1, {
       #'LCS' => sub {
       #     $traditional->LCS(@data3)
       #},
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        #'LCSXS' => sub {
        #    Algorithm::Diff::XS::LCSidx(@data3)
        #},
        'LCSnew' => sub {
            $align_bv->LCS(@data3)
        },
        #'S::Sim' => sub {
        #    similarity(@strings2)
        #},
    });
}

if (0) {
    timethese( 10_000, {
        'S::Sim' => sub {
            similarity(@strings3)
        },
    });
}


