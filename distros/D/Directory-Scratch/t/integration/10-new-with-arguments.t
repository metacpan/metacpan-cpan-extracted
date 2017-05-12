#!/usr/bin/perl
# 10-new-with-arguments.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 5;
use Directory::Scratch;
use File::Spec;

my $tmp = Directory::Scratch->new(
				  TEMPLATE => 'foo_bar_baz_XXXX',
				 );
ok($tmp);

my $dir = $tmp->base;
like($dir, qr/[^\w]foo_bar_baz_....[^\w]?$/, 'base matches template');

$tmp    = Directory::Scratch->new(
				  DIR      => File::Spec->tmpdir,
				  TEMPLATE => 'foo_bar_baz_XXXX',
				 );
ok($tmp);

my $new_dir = $tmp->base;
like($new_dir, qr/[^\w]foo_bar_baz_....[^\w]?$/, 'base matches template');
$dir =~ s/....$//;
$new_dir =~ s/....$//;
is($dir, $new_dir, 'DIR = tmpdir, and no DIR produce identical paths');

