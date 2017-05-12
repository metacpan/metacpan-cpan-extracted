#!/usr/bin/env perl -w

# Test that File::chdir works when multiple packages have nested, localized $CWD.

use strict;
use warnings;

use Test::More;

use File::chdir;

my $original_cwd = $CWD.'';

{
    package Inner;
    use File::chdir;

    sub foo {
        local $CWD = File::Spec->catdir($original_cwd, "lib");
    }
}


{
    package Outer;
    use File::chdir;

    sub bar {
        local $CWD = File::Spec->catdir($original_cwd, "t");
        Inner::foo();
    }
}


Outer::bar();
is $CWD, $original_cwd;


done_testing;
