#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 26;

{
  package t;
  
  our ($foo, $bar);
  our (%foo, %bar);
  our (@foo, @bar);
  sub foo {
    return $_[0] + 5;
  }
}

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    $t::foo = 42;
    @t::foo = (55, 66);
    $eval->share_from('t', '$foo', '@foo');
    is($eval->eval('$foo'), 42, 'read shared'.$s);
    is_deeply([$eval->eval('@foo')], [55, 66], 'read shared'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    %t::foo = (a => 5, b => 7);
    $eval->share_from('t', '%foo');
    is($eval->eval('$foo{b}'), 7, 'share hash'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->share_from('t', '&foo');
    is($eval->eval('foo(5)'), 10, 'share sub'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->share_from('t', '$foo');
    $eval->eval('$foo = 21; @foo = ();');
    is($t::foo, 21, 'set shared');
    is_deeply(\@t::foo, [55, 66], 'does not set non-shared'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $t::foo = 42;
    our $foo = 33;
    $eval->share('$foo');
    is($eval->eval('$foo'), 33, 'read shared local'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    our $ping = 25;
    $eval->share_from('main', '$ping');
    is($eval->eval('$ping'), 25, 'read shared from main'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    our $baz = 15;
    $eval->share_from('', '$baz');
    is($eval->eval('$baz'), 15, 'read shared from root'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    eval { $eval->share_from('$foo') };  # this should be share and not share_from.
    like($@, qr/\$foo does not look like a package name/, 'bad package name'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    eval { $eval->share_from('Eval::Safe::Does::NotExist', '$foo') };
    like($@, qr/Package.*does not exist/, 'share from non-existent package'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    eval { $eval->share_from('t', '$does_not_exist') };
    ok(!$@, 'share non-existent symbol'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->share_from('t', '&foo', '*bar');
    $t::foo = 1;
    $t::bar = 2;
    $eval->eval('$foo = 3; $bar = 4;');
    is_deeply([$t::foo, $t::bar], [1, 4], 'share glob'.$s);
  }
}
