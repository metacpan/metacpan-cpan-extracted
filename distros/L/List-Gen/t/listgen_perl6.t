#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    eval q{
        use 5.010;
    1} or eval q{
        use Test::More skip_all => 'List::Gen::Perl6 requires Perl 5.10+';
        exit;
    }
}

use Test::More tests => 30;
use lib qw(../lib lib t/lib);
use List::Gen 0;
use List::Gen::Perl6;
use List::Gen::Testing;

t 'hyper +',
	is => (<0...> <<+>> [1,2,3])->take(10)->str, '1 2 3 1 2 3 1 2 3 1';

t 'hyper R,',
	is => (<1..> >>R,>> 10)->take(10)->str, '10 1 10 2 10 3 10 4 10 5 10 6 10 7 10 8 10 9 10 10';

t 'hyper r,',
	is => (<1..> >>r,>> 10)->take(10)->str, '10 1 10 2 10 3 10 4 10 5 10 6 10 7 10 8 10 9 10 10';

t 'hyper ~,',
	is => (<1..> >>~,>> 10)->take(10)->str, '10 1 10 2 10 3 10 4 10 5 10 6 10 7 10 8 10 9 10 10';


t 'triangle reduction as code',
	is => [..*]->(<2...>)->take(10)->str, '2 4 8 16 32 64 128 256 512 1024';

t 'triangle reduction as op',
	is => ([..*] <2...>)->take(10)->str, '2 4 8 16 32 64 128 256 512 1024';

t 'triangle reduction as code 2',
	is => [\*]->(<2...>)->take(10)->str, '2 4 8 16 32 64 128 256 512 1024';

t 'triangle reduction as op 2',
	is => ([\*] <2...>)->take(10)->str, '2 4 8 16 32 64 128 256 512 1024';

t 'reduction as code',
	is => [+]->(1..10), 55;

t 'reduction as op list',
	is => ([+] 1..10), 55;

t 'reduction as op gen',
	is => ([+] <1..10>), 55;

t 'hyper inf R** one',
	is => (<1..> >>R**>> 2)->take(10)->str, '2 4 8 16 32 64 128 256 512 1024';


my $sum = [\+];
t 'reduction code ref',
	is => $sum->(1..10)->str, '1 3 6 10 15 21 28 36 45 55';

t 'Z',  is => (<1..3> Z <4..6>)->str, '1 4 2 5 3 6';

t 'Z.', is => (<1..3> Z. <4..6>)->str, '14 25 36';

t 'gen Z array',
	is => (<1..3> Z [4..6])->str, '1 4 2 5 3 6';

t 'X',  is => (<1..3> X <4..6>)->str, '1 4 1 5 1 6 2 4 2 5 2 6 3 4 3 5 3 6';

t 'X+', is => (<1..3> X+ <4..6>)->str, '5 6 7 6 7 8 7 8 9';

my @a = (1..10);
t 'reduce array',
	is => ([+] @a), 55;

t 'reduce R',
    is => ([.]  1..4), 1234,
    is => ([R.] 1..4), 4321,
    is => ([r.] 1..4), 4321,
    is => ([\r.] 1..4 )->str, '1 21 321 4321',
    is => ([\R.]1..4)->str, '1 21 321 4321';


t 'Z~', is => (<1..> Z~. <a..>)->str(4), 'a1 b2 c3 d4';
t 'ZR', is => (<1..> ZR. <a..>)->str(4), 'a1 b2 c3 d4';
t 'Zr', is => (<1..> Zr. <a..>)->str(4), 'a1 b2 c3 d4';

t 'X~', is => (<1..2> X~. <a..b>)->str, 'a1 b1 a2 b2';
t 'XR', is => (<1..2> XR. <a..b>)->str, 'a1 b1 a2 b2';
t 'Xr', is => (<1..2> Xr. <a..b>)->str, 'a1 b1 a2 b2';
