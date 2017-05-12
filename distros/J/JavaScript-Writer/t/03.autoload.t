#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More 'no_plan';

{
    my $js = JavaScript::Writer->new();
    $js->alert("foo");

    is($js->as_string(), q{alert("foo");});
}

{
    my $js = JavaScript::Writer->new();
    $js->alert(q{"'?\$\\} );
    is($js->as_string(), q{alert("\"'?\\\\$\\\\");});
}

{
    my $js = JavaScript::Writer->new();
    $js->jump();
    is($js->as_string(), q{jump();});
}

{
    my $js = JavaScript::Writer->new();
    $js->jump;
    is($js->as_string(), q{jump();});
}

