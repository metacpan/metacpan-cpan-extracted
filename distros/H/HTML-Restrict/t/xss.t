#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use HTML::Restrict;

my $hr = HTML::Restrict->new;
$hr->debug(0);
$hr->set_rules( { a => [ 'href', 'class' ] } );

my $text = '<a href="javascript:alert(1)">oops!</a>';

my $clean = $hr->process($text);
is $clean, '<a>oops!</a>', "bad scheme removed";

is $hr->process('<a href="javascript&#58;evil_script()">evil</a>'),
    '<a>evil</a>', 'bad scheme removed';

foreach my $uri (
    'http://vilerichard.com', 'https://vilerichard.com',
    '//vilerichard.com',      '/music'
    ) {
    my $img = qq[<a href="$uri">click</a>];
    is $hr->process($img), $img, "good uri scheme preserved";
}

is $hr->process(
    '<a class="&quot;&gt;&lt;script&gt;alert(&quot;oops&quot;);&lt;/script&gt;&lt;a href=&quot;"></a>'
    ),
    '<a class="&quot;&gt;&lt;script&gt;alert(&quot;oops&quot;);&lt;/script&gt;&lt;a href=&quot;"></a>',
    'attribute value filtered';

done_testing();
