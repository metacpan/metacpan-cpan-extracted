#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use JavaScript::Writer;
use Test::More;
use Test::JE;

plan tests => 4;

{
    my $js = JavaScript::Writer->new;
    $js->object("Widget.Lightbox")->call("show", "Nihao");

    is $js->as_string(), 'Widget.Lightbox.show("Nihao");';

    my $je = Test::JE->new;
    $je->eval("Widget={ Lightbox: { show: function(){} } };");
    $je->eval_ok($js->as_string);
}

{
    my $js = JavaScript::Writer->new;

    $js->var(Widget => {
        Lightbox => {
            show => sub {
            }
        }
    });
    $js->object("Widget.Lightbox")->call("show", "Nihao");

    is $js->as_string, 'var Widget = {"Lightbox":{"show":function(){}}};Widget.Lightbox.show("Nihao");';

    my $je = Test::JE->new;
    $je->eval_ok($js->as_string);
}
