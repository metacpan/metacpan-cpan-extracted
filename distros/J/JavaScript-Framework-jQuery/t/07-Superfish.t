#!perl -T

use Test::More tests => 9;

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

my $jquery;


$jquery = $class->new(
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'Superfish', 
            library => {
                src => [
                    '/js/hoverintent.js',
                    '/js/superfish.js',
                    '/js/supersubs.js',
                ],
                css => [
                    { href => '/css/superfish-vertical.css', media => 'all' },
                    { href => '/css/superfish-navbar.css', media => 'all' },
                    { href => '/css/superfish.css', media => 'all' },
                ],
            },
        },
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#navbar',
    use_supersubs => 1,
);

my $expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="/css/superfish-vertical.css" rel="stylesheet" media="all" />
<link type="text/css" href="/css/superfish-navbar.css" rel="stylesheet" media="all" />
<link type="text/css" href="/css/superfish.css" rel="stylesheet" media="all" />';

is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="/js/hoverintent.js"></script>
<script type="text/javascript" src="/js/superfish.js"></script>
<script type="text/javascript" src="/js/supersubs.js"></script>';

is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

$expected = q|$(document).ready(function (){
$("#navbar").supersubs().superfish();
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
            name => 'Superfish', 
            library => {
                src => [
                    '/js/hoverintent.js',
                    '/js/superfish.js',
                    '/js/supersubs.js',
                ],
                css => [
                    { href => '/css/superfish-vertical.css', media => 'all' },
                    { href => '/css/superfish-navbar.css', media => 'all' },
                    { href => '/css/superfish.css', media => 'all' },
                ],
            },
        },
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#navbar',
    options => 'option1 : 42',
    use_supersubs => 1,
    supersubs_options => 'option1 : "apples"',
);

$expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="/css/superfish-vertical.css" rel="stylesheet" media="all" />
<link type="text/css" href="/css/superfish-navbar.css" rel="stylesheet" media="all" />
<link type="text/css" href="/css/superfish.css" rel="stylesheet" media="all" />';

is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="/js/hoverintent.js"></script>
<script type="text/javascript" src="/js/superfish.js"></script>
<script type="text/javascript" src="/js/supersubs.js"></script>';

is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

$expected = q|$(document).ready(function (){
$("#navbar").supersubs({
option1 : "apples"
}).superfish({
option1 : 42
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

