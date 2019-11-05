#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

#use Test::More;

use LCS::BV;
use LCS;
use Algorithm::Diff;
use Algorithm::Diff::XS;
use String::Similarity;
#use Algorithm::LCS;

use Benchmark qw(:all) ;

#use LCS::Tiny;
#use LCS;
use LCS::BV;

#my $align = Align::Sequence->new;

#my $align_bv = LCS::Tiny->new;
#my $traditional = LCS->new();

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

print "\n",'LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV',"\n","\n";

print 'LCS: [Chrerrplzon] [Choerephon]',"\n","\n";

if (1) {
    cmpthese( -1, {
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
    cmpthese( -1, {
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
    cmpthese( -1, {
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
    cmpthese( -1, {
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


if (0) {
    cmpthese( -1, {
       #'LCS' => sub {
            #$traditional->LCS(@data)
        #},
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
#        'LCSXS' => sub {
#            Algorithm::Diff::XS::LCSidx(@data)
#        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data)
        },
        #'LCStiny' => sub {
            #LCS::Tiny->LCS(@data)
        #},
        'S::Sim' => sub {
            similarity(@strings)
        },
    });
}

if (0) {
    cmpthese( -1, {
       'LCS' => sub {
            #$traditional->LCS(@data2)
        },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data2)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data2)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data2)
        },
        'S::Sim' => sub {
            similarity(@strings2)
        },
    });
}

if (0) {
    cmpthese( -1, {
       'LCS' => sub {
            #$traditional->LCS(@data3)
       },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data3)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data3)
        },
        'LCStiny' => sub {
            LCS::Tiny->LCS(@data3)
        },
    });
}

if (0) {
    timethese( 100_000, {
        'S::Sim' => sub {
            similarity(@strings3)
        },
    });
}

=pod

LCS-BV/xt$ perl 50_diff_bench.t

LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV

LCS: [Chrerrplzon] [Choerephon]

                Rate LCS:LCS_____ AD:LCSidx___ AD:XS:LCSidx LCS:BV:LCS__
LCS:LCS_____  9050/s           --         -72%         -87%         -87%
AD:LCSidx___ 32000/s         254%           --         -53%         -55%
AD:XS:LCSidx 68266/s         654%         113%           --          -5%
LCS:BV:LCS__ 71739/s         693%         124%           5%           --

LCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

               Rate LCS:LCS_____ AD:LCSidx___ LCS:BV:LCS__ AD:XS:LCSidx
LCS:LCS_____ 46.7/s           --         -42%         -96%         -99%
AD:LCSidx___ 79.8/s          71%           --         -93%         -98%
LCS:BV:LCS__ 1163/s        2392%        1357%           --         -70%
AD:XS:LCSidx 3930/s        8321%        4824%         238%           --

LLCS: [Chrerrplzon] [Choerephon]

                     Rate LCS:LLCS________ AD:XS:LCS_length AD:LCS_length___ LCS:BV:LLCS_____
LCS:LLCS________  10860/s               --             -70%             -70%             -92%
AD:XS:LCS_length  36202/s             233%               --              -1%             -74%
AD:LCS_length___  36540/s             236%               1%               --             -73%
LCS:BV:LLCS_____ 137845/s            1169%             281%             277%               --

LLCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

                   Rate LCS:LLCS________ AD:LCS_length___ AD:XS:LCS_length LCS:BV:LLCS_____
LCS:LLCS________ 47.7/s               --             -40%             -40%             -98%
AD:LCS_length___ 79.0/s              66%               --              -1%             -96%
AD:XS:LCS_length 79.8/s              67%               1%               --             -96%
LCS:BV:LLCS_____ 2054/s            4206%            2499%            2474%               --

=cut

