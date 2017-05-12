#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More;

plan tests => 2;

{
    # while(1){}
    my $js = JavaScript::Writer->new();

    $js->while(1 => sub {});

    is "$js", "while(1){}", "an empty while loop";
}


{
    my $js = JavaScript::Writer->new();
    $js->while(1 => sub { $_[0]->alert("Nihao") });

    is "$js", 'while(1){alert("Nihao");}', "a simple while loop";
}
