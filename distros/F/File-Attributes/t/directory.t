#!/usr/bin/perl
# directory.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

# make sure File::Attributes works on directories, too

use Test::More tests => 3;
use File::Attributes qw(get_attribute set_attribute);
use Directory::Scratch;

my $tmp = Directory::Scratch->new;
my $dir = $tmp->mkdir('dir');
ok(-d $dir);

set_attribute($dir, foo => 'bar');
set_attribute($dir, bar => 'baz');

is(get_attribute($dir, 'foo') => 'bar');
is(get_attribute($dir, 'bar') => 'baz');


 
