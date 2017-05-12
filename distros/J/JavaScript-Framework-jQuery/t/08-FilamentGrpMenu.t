#!perl -T

use Test::More tests => 9;

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

 # example output:
 # $('#adminmenubtn').menu({
 #     content: $("#menu-items").html(),
 #     posX: "left",
 #     posY: "bottom",
 #     directionV: "down",
 #     showSpeed: 200,
 #     backLink: false
 # });

my $jquery;


$jquery = $class->new(
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'FilamentGrpMenu', 
            library => {
                src => [
                    '/js/fg.menu.js',
                ],
                css => [
                    { href => '/css/fg.menu.css', media => 'all' },
                ],
            },
        },
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'FilamentGrpMenu',
    target_selector => '#menu-items',
    content_from => '$("#menu-items").html()',
);

my $expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="/css/fg.menu.css" rel="stylesheet" media="all" />';

is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="/js/fg.menu.js"></script>';

is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

$expected = q|$(document).ready(function (){
$("#menu-items").menu({
content : $("#menu-items").html()
});
});|;

$expected = <<EOF;
<script type="text/javascript">
//<![CDATA[
$expected
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

# repeat tests with option objects to jQuery method calls
$jquery = $class->new(
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'FilamentGrpMenu', 
            library => {
                src => [
                    '/js/fg.menu.js',
                ],
                css => [
                    { href => '/css/fg.menu.css', media => 'all' },
                ],
            },
        },
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'FilamentGrpMenu',
    target_selector => '#menu-items',
    content_from => '$("#menu-items").html()',
    options =>
'posX : "left",
posY : "bottom",
backLink : false'
);

$expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="/css/fg.menu.css" rel="stylesheet" media="all" />';

is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="/js/fg.menu.js"></script>';

is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

$expected = q|$(document).ready(function (){
$("#menu-items").menu({
content : $("#menu-items").html(),
posX : "left",
posY : "bottom",
backLink : false
});
});|;

$expected = <<EOF;
<script type="text/javascript">
//<![CDATA[
$expected
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

