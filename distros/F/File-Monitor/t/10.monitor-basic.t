#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Monitor;
use File::Monitor::Object;

my @READ_ONLY = qw(
    dev inode mode num_links uid gid rdev size atime mtime ctime blk_size
    blocks error files name
);

plan tests => 6 + @READ_ONLY * 2;

ok my $monitor = File::Monitor->new(), 'object creation OK';
isa_ok $monitor, 'File::Monitor';

eval { File::Monitor::Object->new(); };
like $@, qr/name/, 'name is mandatory';

ok my $object = File::Monitor::Object->new( $^X ), 'object creaton OK';
isa_ok $object, 'File::Monitor::Object';
is $object->name, $^X, 'name returns correct value';

for my $field (@READ_ONLY) {
    eval { $object->$field };
    ok !$@, "$field can be read";
    eval { $object->$field('something'); };
    like $@, qr/read\W+only/, "$field can't be written";
}
