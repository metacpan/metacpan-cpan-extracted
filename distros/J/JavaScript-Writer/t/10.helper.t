#!/usr/bin/perl

use strict;
use warnings;
use JavaScript::Writer;
use JavaScript::Writer::BasicHelpers;
use Test::More;

plan tests => 1;

{
    my $func = sub {
        $_[0]->alert(42);
    };

    my $js = JavaScript::Writer->new;
    $js->delay(20, $func);

    my $j2 = JavaScript::Writer->new;
    $j2->setTimeout($func, 20);

    is("$j2", "$js", 'delay()');
}
