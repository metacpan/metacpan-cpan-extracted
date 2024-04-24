#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.36;
use feature 'class';
no warnings 'experimental::class';


# https://github.com/Perl/perl5/issues/22159
{
    #'eval "class Foo {"; Foo->new'
    local $@;
    eval {
        eval "class Foo {"; Foo->new;
    };
    ok( ! $@, "No exception" ) or diag($@);
}

done_testing;
