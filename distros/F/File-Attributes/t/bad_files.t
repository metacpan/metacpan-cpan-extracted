#!/usr/bin/perl
# bad_files.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 1;
use File::Attributes qw(list_attributes);

eval {
    list_attributes('/foo/bar/this is made up/i hope this doesnt exist');
};

ok($@, 'looking up attributes on a nonexistent file fails');
