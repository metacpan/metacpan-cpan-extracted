#!perl -T

use Test::More 'no_plan';

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

my (
    $jquery,
    $expected,
);

$jquery = $class->new(
    xhtml => 1,
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
);
isa_ok($jquery, $class);

$expected =
'<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
// comment
});
//]]>
</script>';
$jquery->add_func_calls('// comment');
is($jquery->document_ready, $expected, 'document_ready prints code added with add_func_calls meth');

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

# test in conjunction with the use of other plugins

# Order of operations is important!
# The statements created by add_func_calls
# and construct_plugin will be included
# in the output in the order in which they're
# created.
$jquery->add_func_calls(
    q|$('.foobar').do_stuff();|
);

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
$('.foobar').do_stuff();
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

