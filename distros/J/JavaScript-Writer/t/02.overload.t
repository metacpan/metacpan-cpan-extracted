#!/usr/bin/env perl

use strict;
use warnings;

use JavaScript::Writer;
use Test::More;

plan tests => 1;

{
    # For "<<"
    no warnings;

    my $js = JavaScript::Writer->new();

    $js << q{alert('foo')};

    is("$js", q{alert('foo');});
}
