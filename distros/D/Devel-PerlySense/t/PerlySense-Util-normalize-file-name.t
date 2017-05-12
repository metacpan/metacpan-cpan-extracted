#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use Test::Exception;

use Path::Class;


use lib "lib";

use_ok("Devel::PerlySense::Util");


is(filePathNormalize("sample.txt"), "sample.txt", "Simple file name");

is(
    filePathNormalize(file("dir", "sample.txt")),
    file("dir", "sample.txt") . "",
    "Simple file name",
);


#This is a hopeless thing to test cross platform, because the Unix
#version is "broken", in that realpath doesn't remove ../ properly,
#but the Win32 thing does.
#
#And nowhere is the path separator exposed.
#
#By using the same test code as implementation code, at least it
#should be bug compatible across platforms. Win32 doesn't need
#testing, because it's not broken. Unix will test the thing properly.
my $file = file("dir", "remove", "..", "sample.txt");
is(
    filePathNormalize($file),
    file("dir", "sample.txt") . "",
    "Simple file name",
);




__END__
