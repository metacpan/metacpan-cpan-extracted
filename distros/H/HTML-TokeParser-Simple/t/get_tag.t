#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 59; 
my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib/';
    $CLASS = 'HTML::TokeParser::Simple';
    use_ok($CLASS) || die;
}

my $TOKEN_CLASS = "${CLASS}::Token";
my $TAG_CLASS   = "${TOKEN_CLASS}::Tag";
can_ok($CLASS, 'new');
my $p = $CLASS->new(\*DATA);
isa_ok( $p, $CLASS =>             '... and the object it returns' );

can_ok($p, 'get_tag');
my $token = $p->get_tag;
isa_ok( $token, $TAG_CLASS =>   '... and the object it returns' );
my $old_token = $token;

can_ok($token, 'is_declaration');
ok(! $token->is_declaration,      '... and it should return false' );
is_deeply($token,$old_token,      '... and the token should not be changed' );

can_ok($token, 'is_start_tag');
ok( $token->is_start_tag('html'), '... and it should correctly identify a given start tag' );
ok(!$token->is_start_tag('fake'), "... bug it shouldn't give false positives" );
ok( $token->is_start_tag,         '... and it should correctly identify a start tag' );

can_ok($token, 'is_tag');
ok($token->is_tag('html'),        '... and it should identify a token as a given tag'  );
ok(!$token->is_tag('fake'),       "... and it shouldn't give false positives");
ok($token->is_tag,                '... and it should identify that the token is a tag');

can_ok($token, 'get_tag');
ok(my $tag = $token->get_tag,     '... and calling it should succeed' );
is($tag, 'html',                  '... by returning the correct tag');

can_ok($token, 'return_tag');
ok($tag = $token->return_tag,     '... and calling this deprecated method should succeed' );
is($tag, 'html',                  '... by returning the correct tag');

# important to remember that whitespace counts as a token.
$token = $p->get_tag for ( 1 .. 2 );

can_ok($token, 'is_comment');
ok(!$token->is_comment,           "... but it shouldn't have false positives");

can_ok($token, 'return_text');
{
  my $warning;
  local $SIG{__WARN__} = sub { $warning = shift };
  is($token->return_text,
                       '<title>', '... and it should return the correct text' );
  ok( $warning,                   '... while issuing a warning');                  
  like($warning, qr/\Qreturn_text() is deprecated.  Use as_is() instead\E/,
                                  '... with an appropriate error message');
}

can_ok($token, 'as_is');
is( $token->as_is, '<title>',     '... and it should return the correct text');

$token = $p->get_tag; 

can_ok($token, 'is_end_tag');
ok( $token->is_end_tag('/title'), '... and it should identify a particular end tag' );
ok( $token->is_end_tag('title'),  '... even without a slash' );
ok( $token->is_end_tag('TITLE'),  '... regardless of case' );
ok( $token->is_end_tag,           '... and should identify the token as just being an end tag' );

$token = $p->get_tag for 1..2;

can_ok($token, 'get_attr');
my $attr = $token->get_attr;
is( ref $attr , 'HASH',           '... and it should return a hashref' );
is( $attr->{'bgcolor'}, '#ffffff','... correctly identifying the bgcolor' );
is( $attr->{'alink'}, '#0000ff',  '... and the alink color' );
is($token->get_attr('bgcolor'), '#ffffff', 
                                  '... and fetching a specific attribute should succeed');
is($token->get_attr('BGCOLOR'), '#ffffff', 
                                  '... and fetching a specific attribute should succeed');
is($token->get_attr('alink'), '#0000ff', 
                                  '... and fetching a specific attribute should succeed');
                                  
can_ok($token, 'return_attr');
$attr = $token->return_attr;
is( ref $attr , 'HASH',           '... and calling this deprecated method should return a hashref' );
is( $attr->{'bgcolor'}, '#ffffff','... correctly identifying the bgcolor' );
is( $attr->{'alink'}, '#0000ff',  '... and the alink color' );
is($token->return_attr('bgcolor'), '#ffffff', 
                                  '... and fetching a specific attribute should succeed');
is($token->return_attr('BGCOLOR'), '#ffffff', 
                                  '... and fetching a specific attribute should succeed');
is($token->return_attr('alink'), '#0000ff', 
                                  '... and fetching a specific attribute should succeed');

can_ok($token, 'set_attr');
$attr = $token->get_attr;
$attr->{bgcolor} = "whatever";
$token->set_attr($attr);
is($token->as_is, '<body alink="#0000ff" bgcolor="whatever">',
                                  'set_attr() should accept what get_attr() returns');

can_ok($token, 'get_attrseq');
my $arrayref = $token->get_attrseq;
is( ref $arrayref, 'ARRAY',       '... and it should return an array reference' );
is( scalar @{$arrayref}, 2,       '... with the correct number of elements' );
is( "@$arrayref", 'alink bgcolor', '... in the correct order' );

can_ok($token, 'return_attrseq');
$arrayref = $token->return_attrseq;
is( ref $arrayref, 'ARRAY',       '... and calling this deprecated method should return an array reference' );
is( scalar @{$arrayref}, 2,       '... with the correct number of elements' );
is( "@$arrayref", 'alink bgcolor', '... in the correct order' );

__DATA__
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
	<head>
		<!-- This is a comment -->
		<title>This is a title</title>
		<?php 
			print "<!-- this is generated by php -->";
		?>
	</head>
	<body alink="#0000ff" bgcolor="#ffffff">
		<h1>Do not edit this HTML lest the tests fail!!!</h1>
	</body>
</html>
