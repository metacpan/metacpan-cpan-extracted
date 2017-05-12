#!/usr/bin/perl
# create_tree.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 14;
use Directory::Scratch;
use strict;
use warnings;
use Path::Class;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');

eval { $tmp->create_tree() };
ok(!$@, 'creating an empty tree works');
is(scalar $tmp->ls, 0, 'no files created');

my %tree = ( foo       => 'foo',
	     'bar/baz' => 'this is bar/baz',
	     'quux'    => 'this is quux',
	     'lines'   => ['lots', 'of', 'lines'],
	     'dir'     => \undef,
	   );
$tmp->create_tree(\%tree);

foreach my $file (keys %tree){
    ok($tmp->exists($file), "$file exists")
}

ok(-d $tmp->exists('bar'), 'bar is a directory');
ok(-d $tmp->exists('dir'), 'dir is a dir');

foreach my $file (keys %tree){
    is_deeply([$tmp->read($file)], [$tree{$file}], 
	      "$file contains expected text")
      unless ref $tree{$file};
}

is_deeply($tree{lines}, [$tmp->read('lines')], 'read lines');

