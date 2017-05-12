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
#use Algorithm::LCS;

use Benchmark qw(:all) ;
use Data::Dumper;

use LCS::Tiny;
use LCS;
use LCS::BV;
use LCS::XS;

my $lcsxs = LCS::XS->new;

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

#print STDERR 'S::Similarity: ',similarity(@strings),"\n";



if (1) {
    print "case:\n",join("\n",@strings),"\n";
    cmpthese( -1, {
       'LCS' => sub {
            $traditional->LCS(@data)
        },
       'A::Diff' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
        'A::D::XS' => sub {
            Algorithm::Diff::XS::LCSidx(@data)
        },
        'L::BV' => sub {
            LCS::BV->LCS(@data)
        },
        'L::Tiny' => sub {
            LCS::Tiny->LCS(@data)
        },
        'S::Sim' => sub {
            similarity(@strings)
        },
        'LCS::XSa' => sub {
            $lcsxs->LCS(@data)
        },
        'LCS::XSs' => sub {
            $lcsxs->LCSs(@strings)
        },
        'cLCS::XSs' => sub {
            $lcsxs->cLCSs(@strings)
        },
    });
}

if (1) {
    print "case:\n",join("\n",@strings2),"\n";
    cmpthese( -1, {
       'LCS' => sub {
            $traditional->LCS(@data2)
        },
       'A::Diff' => sub {
            Algorithm::Diff::LCSidx(@data2)
        },
        'A::D::XS' => sub {
            Algorithm::Diff::XS::LCSidx(@data2)
        },
        'L::Tiny' => sub {
            LCS::Tiny->LCS(@data2)
        },
        'L::BV' => sub {
            LCS::BV->LCS(@data2)
        },
        'LCS::XSa' => sub {
            $lcsxs->LCS(@data2)
        },
        'LCS::XSs' => sub {
            $lcsxs->LCSs(@strings2)
        },
        'cLCS::XSs' => sub {
            $lcsxs->cLCSs(@strings2)
        },
        'S::Sim' => sub {
            similarity(@strings2)
        },
    });
}

if (1) {
    print "case:\n",join("\n",('[qw/a b d/ x 50]', '[qw/b a d c/ x 50]')),"\n";
    cmpthese( -1, {
       'LCS' => sub {
            $traditional->LCS(@data3)
       },
       'A::Diff' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'A::D::XS' => sub {
            Algorithm::Diff::XS::LCSidx(@data3)
        },
        'L::BV' => sub {
            LCS::BV->LCS(@data3)
        },
        'L::Tiny' => sub {
            LCS::Tiny->LCS(@data3)
        },
        'S::Sim' => sub {
            similarity(@strings3)
        },
        'LCS::XSa' => sub {
            $lcsxs->LCS(@data3)
        },
        'LCS::XSs' => sub {
            $lcsxs->LCSs(@strings3)
        },
        'cLCS::XSs' => sub {
            $lcsxs->cLCSs(@strings3)
        },
    });
}


