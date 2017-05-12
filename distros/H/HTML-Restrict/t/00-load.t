#!perl

use Test::More;

use strict;
use warnings;

use Data::Dump;
use HTML::Restrict;
use Scalar::Util;

my $version = $HTML::Restrict::VERSION || 'development';
diag( "Testing HTML::Restrict $version, Perl $], $^X" );

my $hr = HTML::Restrict->new( debug => 0 );
isa_ok( $hr, 'HTML::Restrict' );

isa_ok( $hr->parser, 'HTML::Parser' );

my $default_rules = $hr->get_rules;

cmp_ok( Scalar::Util::reftype( $default_rules ),
    'eq', 'HASH', "default rules are empty" );

# basic stripping -- all tags strippped
my $bold      = '<b>i am bold</b>';
my $processed = $hr->process( $bold );
cmp_ok( $processed, 'eq', 'i am bold', "b tag stripped" );

# updating rules
my $b_rules = { b => [] };
$hr->set_rules( $b_rules );
my $updated_rules = $hr->get_rules;
is_deeply( $b_rules, $updated_rules, "rules update correctly" );

# ensure allowed tags aren't stripped
$processed = $hr->process( $bold );
cmp_ok( $processed, 'eq', $bold, "b tag not stripped" );

# more complex set with multiple tags
# ensure allowed tags aren't stripped and others are removed
$hr->set_rules( { a => [qw( href target )] } );
my $link
    = q[<center><a href="http://google.com" target="_blank" id="test">google</a></center>];
my $processed_link = $hr->process( $link );
cmp_ok(
    $processed_link, 'eq',
    q[<a href="http://google.com" target="_blank">google</a>],
    "allowed link but not center tag",
);

# ensure closing slash is maintained for tags
# with no end tag
$hr->set_rules( { img => [qw( src width height /)] } );
my $img = q[<body><img src="/face.jpg" width="10" height="10" /></body>];
my $processed_img = $hr->process( $img );
cmp_ok(
    $processed_img, 'eq',
    '<img src="/face.jpg" width="10" height="10" />',
    "closing slash preserved in image"
);

# rest rules to default set
$hr->set_rules( {} );
cmp_ok( $hr->process( $bold ), 'eq', 'i am bold', "back to default rules" );

# stripping of comments
cmp_ok( $hr->process( "<!-- comment this -->ok" ),
    'eq', 'ok', "comments are stripped" );

# stripping of javascript includes
cmp_ok(
    $hr->process(
        q{<script type="text/javascript" src="/js/jquery-1.3.2.js"></script>ok}
    ),
    'eq', 'ok',
    "javascript includes are stripped"
);

# stripping of css includes
cmp_ok(
    $hr->process(
        q{<link href="/style.css" media="screen" rel="stylesheet" type="text/css" />ok}
    ),
    'eq', 'ok',
    "css includes are stripped"
);

ok( $hr->trim, "trim enabled by default" );

# stripping of leading and trailing spaces
cmp_ok( $hr->process( "   ok ok ok  " ),
    'eq', 'ok ok ok', "leading and trailing spaces trimmed" );

# stripping of div tags
cmp_ok( $hr->process( "<div>ok</div>" ),
    'eq', 'ok', "divs are stripped away" );

# undef should be returned when no value is passed to the process method
is( $hr->process(), undef, "undef is returned when no value passed" );


# start fresh
# RT #55775
$hr = HTML::Restrict->new;

cmp_ok( $hr->process( 0 ), 'eq', '0', "untrue values not processed");
cmp_ok( $hr->process( '0' ), 'eq', '0', "untrue values not processed");
cmp_ok( $hr->process( '000' ), 'eq', '000', "untrue values not processed");

ok( !$hr->process("<html>"), "process only HTML" );


# bugfix: check URI scheme for "src" attributes
$hr = HTML::Restrict->new( rules => { img => [qw( src )] } );
$hr->set_uri_schemes( [ undef, 'http', 'https' ] );
cmp_ok( $hr->process('<img src="file:/some/file">'), 'eq', '<img>' );

# bugfix: ensure stripper stack is reset in case of broken html
$hr = HTML::Restrict->new;
$hr->strip_enclosed_content( ['script'] );
$hr->process('<script < b >');
cmp_ok($hr->process('some text'), 'eq', 'some text', "stripper stack reset");

done_testing();
