#===============================================================================
#  DESCRIPTION:  test for Logwatch::RecordTree
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  03/12/2015 07:15:05 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

# uncomment these to make debugging easier:
#use Logwatch::RecordTree;
#use Logwatch::RecordTree::IPv4 ( identify => 1 );

use Test::More;

# VERSION

my $lr  = 'Logwatch::RecordTree';
my $ips = 'Logwatch::RecordTree::IPv4';

use_ok $lr;   # the module under test
my $top = $lr->new(
    name   => 'Top:',
    indent => '',
);
isa_ok($top, $lr);

isa_ok($top->log('2:',  '2_2',                                  ), $lr );
isa_ok($top->log('2:',  '2_3',        '2_3_1',                  ), $lr );
isa_ok($top->log('1:', ['1_1', $ips, {neat_names => -1, identify=>1}],            ), $ips);
isa_ok($top->log('1:',  '1_1',        '1_1_1',                  ), $lr );
isa_ok($top->log(['0_last:', undef, {sort_key => 'ZZ'}], 'last' ), $lr );
isa_ok($top->log('1:',  '1_1',        '10.0.21.8', '10.0.21.8-1'), $lr );
isa_ok($top->log('1:',  '1_1',        '8.8.8.1',   '8.8.8.1-1'  ), $lr );
for my $ii (41 .. 57) {
    $top->log(['3:', $lr, {columnize=>1}], "3_$ii");
}
for my $ii (61 .. 79) {
    $top->log(['5:', $ips, {neat_names => -1, columnize=>1,snowshoe=>1,identify=>1}], "10.1.1.$ii");
}
isa_ok($top->log('1:',  '1_1',        '10.0.3.1',               ), $lr );
isa_ok($top->log('2:',  '2_3',        '2_3_3',                  ), $lr );
       $top->log('5:',  "8.8.8.77");
       $top->log('5:',  "8.8.8.87");
       $top->log('5:',  "8.8.8.97");
isa_ok($top->log('2:',  '2_4',        '2_4_1',                  ), $lr );
isa_ok($top->log('2:',  '2_3',        '2_3_2',                  ), $lr );
for my $ii (1 .. 3) {
    $top->log(['4:', undef, {limit=>3}], "3_$ii");
}
isa_ok($top->log('1:',  '1_1',        '1_1_2'                   ), $lr );
isa_ok($top->log('1:',  '1_1',        '10.0.21.6', '10.0.21.6-1'), $lr );
for my $ii (4 .. 10) {
    $top->log('4:', "3_$ii");
}
isa_ok($top->log('2:',  '2_1',        '2_1_1',     '2_1_1_1'    ), $lr );
for (0 .. 5) {
    $top->log('3:', "3_45");
    $top->log('3:', "3_abcdef");
    $top->log('3:', "3_ZZ");
}
isa_ok($top->log('1:',  '1_1',        '10.0.21.6', '10.0.21.6-2'), $lr );
isa_ok($top->log(['6:', $ips, {neat_names => -1, snowshoe=>1}], '10.6.21.6', 'AAA', 'AAAa'), $lr );
$top->log('6:', '10.6.21.7', 'BBB', 'AAAa');
$top->log('6:', '10.6.21.9', 'AAA', 'AAAa');
$top->log('6:', '10.6.21.6', 'BBB', 'AAAb');

my $got = "\n" . $top->sprint(
    sub {
        my ($self, $path) = @_;

        if (@{$path} == 1) {
            push @{$self->lines}, '';  # add blank line after each top-level entry
        }
    }
);

my $expect = q{
86 Top:
 8 1: 1_1
   1 1_1_1             
   1 1_1_2             
   1 Google-8.8.8.1     8.8.8.1-1
   1 internal-10.0.3.1 
   2 internal-10.0.21.6
      1 10.0.21.6-1
      1 10.0.21.6-2
   1 internal-10.0.21.8 10.0.21.8-1

 6 2:
   1 2_1 2_1_1 2_1_1_1
   1 2_2
   3 2_3
      1 2_3_1
      1 2_3_2
      1 2_3_3
   1 2_4 2_4_1

35 3:
   1 3_41     1 3_44     1 3_47     1 3_50     1 3_53     1 3_56     6 3_ZZ    
   1 3_42     7 3_45     1 3_48     1 3_51     1 3_54     1 3_57    
   1 3_43     1 3_46     1 3_49     1 3_52     1 3_55     6 3_abcdef

10 4:
   1 3_1
   1 3_2
   1 3_3
   ... and 7 more

22 5:
    3/ 3 Google-8.8.8.64/26   19/19 internal-10.1.1.0/25

 4 6: 4/3 10.6.21.0/28
   2 AAA AAAa
   2 BBB
      1 AAAa
      1 AAAb

 1 0_last: last
};


is ($got, $expect, 'sprint is correct');

my @expect = split "\n", $expect;
my @got    = split "\n", $got;

is (scalar @got, scalar @expect, 'right number of lines');
for my $ii (0 .. $#got) {
    if (defined $got[$ii] and defined $expect[$ii] and $got[$ii] ne $expect[$ii]) {
        is ($got[$ii], $expect[$ii], "line $ii");
    }
}

done_testing;

