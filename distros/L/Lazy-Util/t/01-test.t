#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Lazy::Util qw/ :all /;

sub l_nuniq {
  my %uniq;
  return l_map { $uniq{0+$_}++ ? () : $_ } @_;
}

sub l_uniq {
  my %uniq;
  return l_map { $uniq{$_}++ ? () : $_ } @_;
}

my $l_c = l_concat 1, 2;
isa_ok($l_c, 'Lazy::Iterator');
is($l_c->get(), 1,     'First value from l_concat was 1');
is($l_c->get(), 2,     'Second value from l_concat was 2');
is($l_c->get(), undef, 'Only two values from l_concat');
is($l_c->exhausted(), 1, '$l_c is exhausted');

my $l_find = l_until { $_ eq 'baa' }
  qw/ aaa aab aba baa aac aca caa abc acb bac bca cab cba /;
isa_ok($l_find, 'Lazy::Iterator');
is($l_find->get(), 'aaa', 'First value from l_until was aaa');
is($l_find->get(), 'aab', 'Second value from l_until was aab');
is($l_find->get(), 'aba', 'Third value from l_until was aba');
is($l_find->get(), 'baa', 'Fourth value from l_until was baa');
is($l_find->get(), undef, 'Only four values from l_until');
is($l_find->exhausted(), 1, '$l_find is exhausted');

my $l_f = l_first 3, 1, 2, 3, 4;
isa_ok($l_f, 'Lazy::Iterator');
is($l_f->get(), 1,     'First value from l_first was 1');
is($l_f->get(), 2,     'Second value from l_first was 2');
is($l_f->get(), 3,     'Third value in from l_first was 3');
is($l_f->get(), undef, 'Only three values from l_first');
is($l_f->exhausted(), 1, '$l_f is exhausted');

my $l_g = l_grep { $_ > 3 } 1, 2, 3, 4, 5;
isa_ok($l_g, 'Lazy::Iterator');
is($l_g->get(), 4,     'First value from l_grep was 4');
is($l_g->get(), 5,     'Second value from l_grep was 5');
is($l_g->get(), undef, 'Only two values from l_grep');
is($l_g->exhausted(), 1, '$l_g is exhausted');

my $l_m = l_map { $_ * 5 } 1, 2, 3;
isa_ok($l_m, 'Lazy::Iterator');
is($l_m->get(), 5,     'First value from l_map was 5');
is($l_m->get(), 10,    'Second value from l_map was 10');
is($l_m->get(), 15,    'Third value from l_map was 15');
is($l_m->get(), undef, 'Only three values from l_map');
is($l_m->exhausted(), 1, '$l_m is exhausted');

my $l_m2 = l_map { $_ == 1 ? () : $_ == 2 ? (2,2) : $_ } 1, 2, 1, 1, 3;
isa_ok($l_m2, 'Lazy::Iterator');
is($l_m2->get(), 2, 'First value from l_map was 2');
is($l_m2->get(), 2, 'Second value from l_map was 2');
is($l_m2->get(), 3, 'Third value from l_map was 3');
is($l_m2->get(), undef, 'Only three values from l_map');
is($l_m2->exhausted(), 1, '$l_m2 is exhausted');

my $l_nf = l_until { $_ == 3 } 1, 2, 3, 4, 5;
isa_ok($l_nf, 'Lazy::Iterator');
is($l_nf->get(), 1,     'First value from l_until was 1');
is($l_nf->get(), 2,     'Second value from l_until was 2');
is($l_nf->get(), 3,     'Third value from l_until was 3');
is($l_nf->get(), undef, 'Only three values from l_until');
is($l_nf->exhausted(), 1, '$l_nf is exhausted');

my $l_nu = l_nuniq 1, 2, 1, 2, 3, 1, 2, 3, 4;
isa_ok($l_nu, 'Lazy::Iterator');
is($l_nu->get(), 1,     'First value from l_nuniq was 1');
is($l_nu->get(), 2,     'Second value from l_nuniq was 2');
is($l_nu->get(), 3,     'Third value from l_nuniq was 3');
is($l_nu->get(), 4,     'Fourth value from l_nuniq was 4');
is($l_nu->get(), undef, 'Only four values from l_nuniq');
is($l_nu->exhausted(), 1, '$l_nu is exhausted');

my $l_u = l_uniq qw/ a b a b c a b c d /;
isa_ok($l_u, 'Lazy::Iterator');
is($l_u->get(), 'a',   'First value from l_uniq was a');
is($l_u->get(), 'b',   'Second value from l_uniq was b');
is($l_u->get(), 'c',   'Third value from l_uniq was c');
is($l_u->get(), 'd',   'Fourth value from l_uniq was d');
is($l_u->get(), undef, 'Only four values from l_uniq');
is($l_u->exhausted(), 1, '$l_u is exhausted');

is(g_count(qw/ a b c d/), 4, 'g_count returned 4');
is(g_count(),             0, 'g_count returned 0');
is(g_first(1, 2), 1, 'g_first returned 1');
is(g_first(), undef, 'g_first returned undef');
is(g_join("\n", 1, 2, 3), "1\n2\n3", 'g_join returned 1\n2\n3');
is(g_join("\n", 1), '1', 'g_join returned 1');
is(g_join("\n"), undef, 'g_join returned undef');
is(g_last(3, 4, 5), 5, 'g_last returned 5');
is(g_last(), undef, 'g_last returned undef');
is(g_max(1, 2, 3, 9, 8, 7, 6), 9, 'g_max returned 9');
is(g_max(), undef, 'g_max returned undef');
is(g_min(1, 2, 3, -4, -3, -2, -1, 0), -4, 'g_min returned -4');
is(g_min(), undef, 'g_min returned undef');
is(g_prod(1, 2, 3), 6, 'g_prod returned 6');
my $switch = 0;
is(g_prod(1, 2, 3, 0, sub { $switch = 1; undef; }), 0, 'g_prod returned 0');
is($switch,  0, 'g_prod stopped in time');
is(g_prod(), 1, 'g_prod returned 1');
is(g_sum(1, 2, 3), 6, 'g_sum returned 6');
is(g_sum(), 0, 'g_sum returned 0');

my @values = ('a', 'b', 'c');
my $l_v = l_concat sub { shift @values };
isa_ok($l_v, 'Lazy::Iterator');
is($l_v->get(),    'a',   'First value from code ref was a');
is($l_v->get(),    'b',   'Second value from code ref was b');
is($l_v->get(),    'c',   'Third value from code ref was c');
is($l_v->get(),    undef, 'Only three values from code ref');
is($l_v->exhausted(), 1, '$l_v is exhausted');
is(scalar @values, 0,     '@values emptied');

@values = 'd';
is($l_v->get(),    undef, 'code ref is still exhausted');
is(scalar @values, 1,     '@values not emptied');
is($values[0],     'd',   'Value left in @values is d');

@values = ('b', 'c', 'd');
$l_v = l_concat sub { shift @values };
is($l_v->exhausted(), 0, '$l_v is not exhausted');
$l_v->unget('a');
is($l_v->get(), 'a', '$l_v returned a which was unget()ed');
is($l_v->get(), 'b', '$l_v returned b which was used to check for exhaustion');
is($l_v->get(), 'c', 'Second value from code ref was c');
is($l_v->get(), 'd', 'Third value from code ref was d');
is($l_v->exhausted(), 1, '$l_v is exhausted');
is(scalar @values, 0, '@values emptied');

done_testing;
