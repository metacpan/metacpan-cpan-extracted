#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More;

plan tests => 1;

{
    my $js = JavaScript::Writer->new;

    my $func = $js->function(
        sub {
            my $js = shift;
            $js->alert("foo");
        }
    );
    is "$func", q{function(){alert("foo");}}
}
