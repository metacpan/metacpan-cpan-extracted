#!perl

use strict;
use warnings;

use Test::More;
use HTML::Packer; 

if (! eval "use Test::Memory::Cycle; 1;" ) {
	plan skip_all => 'Test::Memory::Cycle required for this test';
}

my $packer = HTML::Packer->init;
memory_cycle_ok( $packer );

my $row = q@
<!doctype html>
<html>
<head>
<meta charset="utf-8">

<style type="text/css">
html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video {
margin : 0;
padding : 0;
border : 0;
font-size : 100%;
font : inherit;
vertical-align : baseline;
}
</style>

<title>Me</title>
</head>
<body>

<span>me</span>

<script type="text/javascript">
var Image1= new Image();
    Image1.src = '/img/next_ru.png';
var Image2 = new Image();
    Image2.src = '/img/next_runav.png';
var Image3= new Image();
    Image3.src = '/img/confirm.png';
var Image4 = new Image();
    Image4.src = '/img/confirmnav.png';
var Image13= new Image();
    Image13.src = '/img/submit_eng.png';
var Image14 = new Image();
    Image14.src = '/img/submit_engnav.png';

</script>

<script type="text/javascript">
$(document).ready(function(e) {
try {
//  $("body select").msDropDown();
$("#payin").msDropdown({visibleRows:3,rowHeight:30});
$("#payout").msDropdown({visibleRows:8,rowHeight:30});
$("#lang").msDropdown({visibleRows:2,rowHeight:16});

} catch(e) {
alert(e.message);
}
});
</script>


</body>
</html>
@;

for ( 1 .. 5 ) { 
	my %opts = (
		remove_newlines => "true",
		remove_comments => 'true',
		do_javascript   => 'best',
		do_stylesheet   => 'minify'
	);
	ok( $packer->minify( \$row,\%opts ),'minify' );
}

memory_cycle_ok( $packer );
done_testing();
