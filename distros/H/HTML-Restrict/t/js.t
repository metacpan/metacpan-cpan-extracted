#!perl

use strict;
use warnings;

use HTML::Restrict ();
use Test::More;

my $hr = HTML::Restrict->new( debug => 0 );

my $html = q[<script type="text/javascript">
$(document).ready(function() {
        $('a.gallery').fancybox();
});
</script>];

is( $hr->process($html), undef, 'content of script tags removed by default' );

$hr->set_rules( { script => ['type'] } );

is( $hr->process($html), $html, 'content of script preserved' );

done_testing();
