#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use Test::More tests => 8;
use Test::Exception;
use File::Temp::Rename;

my $file = "t/foo";
my $file_tmp;

unlink $file if -e $file;

{
    my $tr = File::Temp::Rename->new(FILE => $file);
    $file_tmp = $tr->filename;
    ok(-f $file_tmp, "tmp file exists while object exists");
    ok(!-f $file,     "final file doesn't while object exists");
}
ok(! -f $file_tmp, "tmp file doesn't exist afterwards");
ok(-f $file,       "final file exists afterwards");
ok(-z $file,       "and it should be empty since we didn't write anything");

ok(! defined File::Temp::Rename->new(FILE => $file), "attempt to clobber file without CLOBBER => 1 should fail");

lives_ok sub {
    my $tr = File::Temp::Rename->new(FILE => $file, CLOBBER => 1);
    $tr->print("hello world\n");
}, "but with CLOBBER it's ok";
ok(-s $file, "and it should be non-empty since we wrote something");

unlink $file if -e $file;

