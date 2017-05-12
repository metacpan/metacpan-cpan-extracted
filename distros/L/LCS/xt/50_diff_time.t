#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use lib qw(../lib/);

use Benchmark qw(:all) ;

#use Align::Sequence;
use LCS::Tiny;
use LCS;

#my $align = Align::Sequence->new;

my $align = LCS::Tiny->new;
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


if (1) {
    timethese( 50_000, {
       'LCS' => sub {
            $traditional->LCS(@data)
        },
        'LCStiny' => sub {
            $align->LCS(@data)
        },
    });
}

if (0) {
    cmpthese( 10_000, {
       'LCS' => sub {
            $traditional->LCS(@data2)
        },
    });
}
