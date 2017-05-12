#!perl -T

use Test::More tests => 11;

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
             name => 'mcDropdown',
            library => {
                src => [ 'jquery.mcdropdown.js', 'jquery.bgiframe.js' ],
                css => [ { href => 'jquery.mcdropdown.css', media => 'all' } ],
            },
        },
    ],
);
isa_ok($jquery, $class);

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

$expected = q|$(document).ready(function (){
$("#inputid").mcDropdown("#ulid");
});|;
# add CDATA wrapper, since we want XHTML
$expected = <<EOF;
<script type="text/javascript">
//<![CDATA[
$expected
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

# turn off xhtml, make sure we get the expected tag style
$jquery = $class->new(
    xhtml => 0,
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
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#inputid',
    source_ul => '#ulid',
);

$expected = '<link type="text/css" href="ui.all.css" rel="stylesheet" media="screen">
<link type="text/css" href="jquery.mcdropdown.css" rel="stylesheet" media="all">';
is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="jquery.min.js"></script>
<script type="text/javascript" src="jquery.mcdropdown.js"></script>
<script type="text/javascript" src="jquery.bgiframe.js"></script>';
is($jquery->script_src_elements, $expected, 'output expected SCRIPT (with SRC attr) elements');

$expected = q|<script type="text/javascript">
$(document).ready(function (){
$("#inputid").mcDropdown("#ulid");
});
</script>|;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

# add options hash
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
    ],
);
isa_ok($jquery, $class);

$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#inputid',
    source_ul => '#ulid',
    options =>
'maxWidth : 12,
maxHeight : 24'
);
$expected = q|$(document).ready(function (){
$("#inputid").mcDropdown("#ulid", {
maxWidth : 12,
maxHeight : 24
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

