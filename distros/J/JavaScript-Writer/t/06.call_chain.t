#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';

use JavaScript::Writer;
use Test::More;
use Test::JE;

plan tests => 3;

{
    my $js = JavaScript::Writer->new;

    $js->call("foo")->call("bar");

    is $js->as_string(), q{foo().bar();};
}

{
    my $js = JavaScript::Writer->new;

    $js->foo->bar;

    is $js->as_string(), q{foo().bar();};
}

{
    my $js = JavaScript::Writer->new;

    $js->say("You")->say("Me");

    is $js->as_string(), q{say("You").say("Me");};
}
