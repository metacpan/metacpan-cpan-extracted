#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More;

plan tests => 1;

{
    my $js = JavaScript::Writer->new;
    $js->object(1)->do(sub { $_[0]->alert(42) });
    is "$js", "if(1){alert(42);}"
}
