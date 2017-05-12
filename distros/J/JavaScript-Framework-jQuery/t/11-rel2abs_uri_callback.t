#!perl -T

use Test::More tests => 11;

my $class;
BEGIN {
    $class = 'JavaScript::Framework::jQuery'; 
	use_ok( $class );
}

my $jquery;

sub fix_uri {
    my $uri = shift;
    return $uri if $uri =~ m!^http://!;
    $uri =~ s!^/!!;
    return 'http://example.com/subdir/' . $uri;
}

$jquery = $class->new(
    rel2abs_uri_callback => \&fix_uri,
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
);

my $expected = '<link type="text/css" href="http://example.com/subdir/ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="http://example.com/subdir/jquery.mcdropdown.css" rel="stylesheet" media="all" />';
is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="http://example.com/subdir/jquery.min.js"></script>
<script type="text/javascript" src="http://example.com/subdir/jquery.mcdropdown.js"></script>
<script type="text/javascript" src="http://example.com/subdir/jquery.bgiframe.js"></script>';
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

# add another option
$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#input2id',
    source_ul => '#ulid2',
);
$expected = <<'EOF';
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#input2id").mcDropdown("#ulid2");
});
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

# multiple plugin objects in one request
$jquery->config_plugin(
    name => 'Superfish',
    library => {
        src => [ 'jquery.superfish.js', 'jquery.supersubs.js' ],
        css => [ { href => 'superfish.css', media => 'all' } ],
    },
);
$jquery->construct_plugin(
    name => 'mcDropdown',
    target_selector => '#input2id',
    source_ul => '#ulid2',
);
$jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#ulid',
    use_supersubs => 1,
);
$expected = <<'EOF';
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#input2id").mcDropdown("#ulid2");
$("#ulid").supersubs().superfish();
});
//]]>
</script>
EOF
chomp $expected;
is($jquery->document_ready, $expected, 'output jQuery $(document).ready(...)');

# verify no output of duplicate assets
$jquery = $class->new(
    rel2abs_uri_callback => \&fix_uri,
    xhtml => 1,
    library => {
        src => [ 'jquery.min.js' ],
        css => [ { href => 'ui.all.css', media => 'screen' } ],
    },
    plugins => [
        {
            name => 'mcDropdown',
            library => {
                src => [ 'jquery.jplugin.js' ],
                css => [ { href => 'jquery.jplugin.css', media => 'all' } ],
            },
        },
        {
            name => 'FilamentGrpMenu',      # this could be any jQuery plugin that shares a library with another plugin
            library => {
                src => [ 'jquery.jplugin.js' ],
                css => [ { href => 'jquery.jplugin.css', media => 'all' } ],
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
$jquery->construct_plugin(
    name => 'FilamentGrpMenu',
    target_selector => '#inputid',
    content_from => '#myul',
);

$expected = '<link type="text/css" href="http://example.com/subdir/ui.all.css" rel="stylesheet" media="screen" />
<link type="text/css" href="http://example.com/subdir/jquery.jplugin.css" rel="stylesheet" media="all" />';
is($jquery->link_elements, $expected, 'output expected LINK elements');

$expected = '<script type="text/javascript" src="http://example.com/subdir/jquery.min.js"></script>
<script type="text/javascript" src="http://example.com/subdir/jquery.jplugin.js"></script>';
is($jquery->script_src_elements, $expected, 'output expected script src elements');

$expected = '<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#inputid").mcDropdown("#ulid");
$("#inputid").menu({
content : #myul
});
});
//]]>
</script>';
is($jquery->document_ready, $expected, 'output expected document_ready');

