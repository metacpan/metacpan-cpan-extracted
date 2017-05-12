#!perl -T

use Test::More 'no_plan';

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

my $jquery;


$jquery = $class->new(
    xhtml => 1,
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'mcDropdown', 
            library => {
                src => [ 'jquery.mcdropdown.js', 'jquery.bgiframe.js' ],
                css => [ { href => 'jquery.mcdropdown.css', media => 'all' } ],
            },
        },
        {
            name => 'Superfish', 
            library => {
                src => [ 'superfish.js' ],
                css => [ { href => 'superfish.css', media => 'all' } ],
            },
        },
    ],
);
isa_ok($jquery, $class);




# test with transient_plugins true

$jquery->transient_plugins(1);

$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#inputid',
    source_ul => '#ulid',
);

my $expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="jquery.mcdropdown.css" rel="stylesheet" media="all" />';
is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="jquery.mcdropdown.js"></script>
<script type="text/javascript" src="jquery.bgiframe.js"></script>';
is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

# add CDATA wrapper, since we want XHTML
$expected = <<'EOF';
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#inputid").mcDropdown("#ulid");
});
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

is($jquery->document_ready, '', 'empty output from second call document_ready');




# test with transient_plugins false

$jquery->transient_plugins(0);

$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#inputid',
    source_ul => '#ulid',
);
$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#divid1',
);
$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#divid2',
);
$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#divid3',
);

$expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="jquery.mcdropdown.css" rel="stylesheet" media="all" />
<link type="text/css" href="superfish.css" rel="stylesheet" media="all" />';
is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="jquery.mcdropdown.js"></script>
<script type="text/javascript" src="jquery.bgiframe.js"></script>
<script type="text/javascript" src="superfish.js"></script>';
is($jquery->script_src_elements, $expected, 'HERE output expected SCRIPT (with SRC attr) elements');

# add CDATA wrapper, since we want XHTML
$expected = <<'EOF';
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#inputid").mcDropdown("#ulid");
$("#divid1").superfish();
$("#divid2").superfish();
$("#divid3").superfish();
});
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

is($jquery->document_ready, $expected, 'same output from second call document_ready');

