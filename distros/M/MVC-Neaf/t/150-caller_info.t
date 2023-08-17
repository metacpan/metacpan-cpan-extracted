#!/usr/bin/env perl

package main;

use strict;
use warnings;
use Test::More;

sub foo {
    package MVC::Neaf::X::Nonexistent;
    use MVC::Neaf::Util qw(caller_info);
    return caller_info();
};

sub bar {
    package My::Plugin;
    use parent qw(MVC::Neaf::X);
    use MVC::Neaf::Util qw(caller_info);
    return caller_info();
};

is_deeply [(foo())[0,1,2]], ['main', __FILE__, __LINE__], "caller info is correct via package name";
is_deeply [(bar())[0,1,2]], ['main', __FILE__, __LINE__], "caller info is correct via isa";

done_testing;
