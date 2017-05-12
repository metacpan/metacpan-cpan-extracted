# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/HTML-EasyTags.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..79\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::EasyTags 1.071;
$loaded = 1;
print "ok 1\n";
use strict;
use warnings;

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the first test, above

sub result {
	$test_num++;
	my ($worked, $detail) = @_;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");	
	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub vis {
	my ($str) = @_;
	$str =~ s/\n/\\n/g;  # make newlines visible
	$str =~ s/\t/\\t/g;  # make tabs visible
	return( $str );
}

sub serialize {
	my ($input,$is_key) = @_;
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( '{ ', ( map { 
				( serialize( $_, 1 ), serialize( $input->{$_} ) ) 
			} sort keys %{$input} ), '}, ' ) 
		: ref($input) eq 'ARRAY' ? 
			( '[ ', ( map { 
				( serialize( $_ ) ) 
			} @{$input} ), '], ' ) 
		: defined($input) ?
			"'$input'".($is_key ? ' => ' : ', ')
		: "undef".($is_key ? ' => ' : ', ')
	) );
}

######################################################################

message( "START TESTING HTML::EasyTags" );

######################################################################
# test new(), clone(), and property setting methods, and prologue_tag()

{
	my $html1 = HTML::EasyTags->new();
	result( UNIVERSAL::isa( $html1, "HTML::EasyTags" ), "new() ret EasyTags obj" );

	my ($res1);
	my ($did, $should);

	my $html2 = HTML::EasyTags->new();

	$res1 = $html2->groups_by_default();
	result( $res1 == 0, "new() inits group prop to '$res1'" );
			
	$res1 = $html2->groups_by_default( 1 );
	result( $res1 == 1, "groups_by_default( 1 ) returns '$res1'" );

	$did = $html2->prologue_tag();
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">";
	result( $did eq $should, "new() inits prologue prop to '".vis($did)."'" );

	$did = $html2->prologue_tag( 'my NEW doctype' );
	$should = "my NEW doctype";
	result( $did eq $should, "prologue_tag( 'my NEW doctype' ) ".
		"returns '".vis($did)."'" );
	
	my $html3 = $html2->clone();

	$res1 = $html3->groups_by_default();
	result( $res1 == 1, "clone() copies group prop as '$res1'" );
	
	$res1 = $html3->groups_by_default( 0 );
	result( $res1 == 0, "groups_by_default( 0 ) returns '$res1'" );

	$did = $html3->prologue_tag();
	$should = "my NEW doctype";
	result( $did eq $should, "clone() copies prologue prop as '$did'" );
}

######################################################################
# test comment_tag()

{
	my $html = new HTML::EasyTags();
	my ($did, $should);

	$did = $html->comment_tag();
	$should = "\n<!--  -->";
	result( $did eq $should, "comment_tag() ".
		"returns '".vis($did)."'" );

	$did = $html->comment_tag( "hello" );
	$should = "\n<!-- hello -->";
	result( $did eq $should, "comment_tag( 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->comment_tag( ["hello", "world"] );
	$should = "\n<!-- \n\thello\n\tworld\n -->";
	result( $did eq $should, "comment_tag( ['hello','world'] ) ".
		"returns '".vis($did)."'" );
}

######################################################################
# test make_html_tag()

{
	my $html = new HTML::EasyTags();
	my ($did, $should);

	# try no args

	$did = $html->make_html_tag();
	$should = "\n<></>";
	result( $did eq $should, "make_html_tag() ".
		"returns '".vis($did)."'" );

	# try with tag name only

	$did = $html->make_html_tag( 'p' );
	$should = "\n<p></p>";
	result( $did eq $should, "make_html_tag( 'p' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img' );
	$should = "\n<img />";
	result( $did eq $should, "make_html_tag( 'img' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( '0' );
	$should = "\n<0></0>";
	result( $did eq $should, "make_html_tag( '0' ) ".
		"returns '".vis($did)."'" );

	# try with tag name and visible text only

	$did = $html->make_html_tag( 'p', undef, 'hello' );
	$should = "\n<p>hello</p>";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello' );
	$should = "\n<img />hello";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'p', undef, '0' );
	$should = "\n<p>0</p>";
	result( $did eq $should, "make_html_tag( 'p', undef, '0' ) ".
		"returns '".vis($did)."'" );

	# try with tag name, visible text, and part to make (4 types)

	$did = $html->make_html_tag( 'p', undef, 'hello', 'group' );
	$should = "\n<p>hello</p>";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello', 'group' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello', 'group' );
	$should = "\n<img />hello";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello', 'group' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'p', undef, 'hello', 'pair' );
	$should = "\n<p>hello</p>";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello', 'pair' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello', 'pair' );
	$should = "\n<img>hello</img>";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello', 'pair' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'p', undef, 'hello', 'start' );
	$should = "\n<p>hello";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello', 'start' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello', 'start' );
	$should = "\n<img>hello";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello', 'start' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'p', undef, 'hello', 'end' );
	$should = "\n</p>";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello', 'end' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello', 'end' );
	$should = "\n</img>";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello', 'end' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'p', undef, 'hello', 'mini' );
	$should = "\n<p />hello";
	result( $did eq $should, "make_html_tag( 'p', undef, 'hello', 'mini' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'img', undef, 'hello', 'mini' );
	$should = "\n<img />hello";
	result( $did eq $should, "make_html_tag( 'img', undef, 'hello', 'mini' ) ".
		"returns '".vis($did)."'" );

	# try with tag name and tag params only

	$did = $html->make_html_tag( 'input', {} );
	$should = "\n<input />";
	result( $did eq $should, "make_html_tag( 'input', {} ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'input', { type => 'radio' } );
	$should = "\n<input type=\"radio\" />";
	result( $did eq $should, "make_html_tag( 'input', { type => 'radio' } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'input', { type => 'radio', 
		name => 'choice', size => 42, checked => 0 } );
	$should = "\n<input type=\"radio\" name=\"choice\" size=\"42\" />";
	result( $did eq $should, "make_html_tag( 'input', { type => 'radio', ".
		"name => 'choice', size => 42, checked => 0 } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'input', { type => 'radio', 
		name => 'choice', size => 42, checked => 1 } );
	$should = "\n<input type=\"radio\" name=\"choice\" checked=\"1\" size=\"42\" />";
	result( $did eq $should, "make_html_tag( 'input', { type => 'radio', ".
		"name => 'choice', size => 42, checked => 1 } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'input', { type => 'radio', zb => 'xy' } );
	$should = "\n<input type=\"radio\" zb=\"xy\" />";
	result( $did eq $should, "make_html_tag( 'input', { type => 'radio', zb => 'xy' } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag( 'input', { 0 => '0' } );
	$should = "\n<input 0=\"0\" />";
	result( $did eq $should, "make_html_tag( 'input', { 0 => '0' } ) ".
		"returns '".vis($did)."'" );

	# try with tag name, tag params, visible text

	$did = $html->make_html_tag( 'p', { class => 'Standard' }, 'hello' );
	$should = "\n<p class=\"Standard\">hello</p>";
	result( $did eq $should, "make_html_tag( 'p', { class => 'Standard' }, 'hello' ) ".
		"returns '".vis($did)."'" );
}

######################################################################
# test make_html_tag_group()

{
	my $html = new HTML::EasyTags();
	my ($did, $should);

	# try no args

	$did = $html->make_html_tag_group();
	$should = "\n<></>";
	result( $did eq $should, "make_html_tag_group() ".
		"returns '".vis($did)."'" );

	# try with tag name only

	$did = $html->make_html_tag_group( 'p' );
	$should = "\n<p></p>";
	result( $did eq $should, "make_html_tag_group( 'p' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'img' );
	$should = "\n<img />";
	result( $did eq $should, "make_html_tag_group( 'img' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( '0' );
	$should = "\n<0></0>";
	result( $did eq $should, "make_html_tag_group( '0' ) ".
		"returns '".vis($did)."'" );

	# try with tag name and visible text only

	$did = $html->make_html_tag_group( 'p', undef, 'hello' );
	$should = "\n<p>hello</p>";
	result( $did eq $should, "make_html_tag_group( 'p', undef, 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'img', undef, 'hello' );
	$should = "\n<img />hello";
	result( $did eq $should, "make_html_tag_group( 'img', undef, 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'td', undef, ['hello', 'world'] );
	$should = "\n<td>hello</td>\n<td>world</td>";
	result( $did eq $should, "make_html_tag_group( 'td', undef, ['hello', 'world'] ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'td', undef, [1..5] );
	$should = "\n<td>1</td>\n<td>2</td>\n<td>3</td>\n<td>4</td>\n<td>5</td>";
	result( $did eq $should, "make_html_tag_group( 'td', undef, [1..5] ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'td', undef, [undef, undef] );
	$should = "\n<td></td>\n<td></td>";
	result( $did eq $should, "make_html_tag_group( 'td', undef, [undef, undef] ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'p', undef, '0' );
	$should = "\n<p>0</p>";
	result( $did eq $should, "make_html_tag_group( 'p', undef, '0' ) ".
		"returns '".vis($did)."'" );

	# try with tag name and tag params only

	$did = $html->make_html_tag_group( 'input', {} );
	$should = "\n<input />";
	result( $did eq $should, "make_html_tag_group( 'input', {} ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { type => 'radio' } );
	$should = "\n<input type=\"radio\" />";
	result( $did eq $should, "make_html_tag_group( 'input', { type => 'radio' } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { type => 'radio', 
		name => 'choice', size => 42, checked => 0 } );
	$should = "\n<input type=\"radio\" name=\"choice\" size=\"42\" />";
	result( $did eq $should, "make_html_tag_group( 'input', { type => 'radio', ".
		"name => 'choice', size => 42, checked => 0 } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { type => 'radio', 
		name => 'choice', size => 42, checked => 1 } );
	$should = "\n<input type=\"radio\" name=\"choice\" checked=\"1\" size=\"42\" />";
	result( $did eq $should, "make_html_tag_group( 'input', { type => 'radio', ".
		"name => 'choice', size => 42, checked => 1 } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { type => 'radio', checked => [1,0,1,1,0] } );
	$should = "\n<input type=\"radio\" checked=\"1\" />\n<input type=\"radio\" />\n<input type=\"radio\" checked=\"1\" />\n<input type=\"radio\" checked=\"1\" />\n<input type=\"radio\" />";
	result( $did eq $should, "make_html_tag_group( 'input', type => 'radio', checked => [1,0,1,1,0] } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { type => 'radio', zb => 'xy' } );
	$should = "\n<input type=\"radio\" zb=\"xy\" />";
	result( $did eq $should, "make_html_tag_group( 'input', { type => 'radio', zb => 'xy' } ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'input', { 0 => '0' } );
	$should = "\n<input 0=\"0\" />";
	result( $did eq $should, "make_html_tag_group( 'input', { 0 => '0' } ) ".
		"returns '".vis($did)."'" );

	# try with tag name, tag params, visible text

	$did = $html->make_html_tag_group( 'p', { class => 'Standard' }, 'hello' );
	$should = "\n<p class=\"Standard\">hello</p>";
	result( $did eq $should, "make_html_tag_group( 'p', { class => 'Standard' }, 'hello' ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'p', { class => 'Standard' }, ['hello','world'] );
	$should = "\n<p class=\"Standard\">hello</p>\n<p class=\"Standard\">world</p>";
	result( $did eq $should, "make_html_tag_group( 'p', { class => 'Standard' }, ['hello','world'] ) ".
		"returns '".vis($did)."'" );

	$did = $html->make_html_tag_group( 'p', { align => ['left','center','right'] }, ['hello','world'] );
	$should = "\n<p align=\"left\">hello</p>\n<p align=\"center\">world</p>\n<p align=\"right\">world</p>";
	result( $did eq $should, "make_html_tag_group( 'p', { align => ['left','center','right'] }, ['hello','world'] ) ".
		"returns '".vis($did)."'" );

	# try with force list
	
	$did = serialize( $html->make_html_tag_group( 'img', undef, 'hello', 1 ) );
	$should = serialize( [ "\n<img />hello" ] );
	result( $did eq $should, "make_html_tag_group( 'img', undef, 'hello', 1 ) ".
		"returns '".vis($did)."'" );

	$did = serialize( $html->make_html_tag_group( 'td', undef, ['hello', 'world'], 1 ) );
	$should = serialize( [ "\n<td>hello</td>", "\n<td>world</td>" ] );
	result( $did eq $should, "make_html_tag_group( 'td', undef, ['hello', 'world'], 1 ) ".
		"returns '".vis($did)."'" );
}

######################################################################
# test autoloaded methods

{
	my $html = new HTML::EasyTags();
	my ($did, $should);
	
	$did = $html->p( "some text" );
	$should = "\n<p>some text</p>";
	result( $did eq $should, "p( 'some text' ) returns '".vis($did)."'" );
	
	$did = $html->p_start( "some text" );
	$should = "\n<p>some text";
	result( $did eq $should, "p_start( 'some text' ) returns '".vis($did)."'" );
	
	$did = $html->p_end( "some text" );
	$should = "\n</p>";
	result( $did eq $should, "p_end( 'some text' ) returns '".vis($did)."'" );
	
	$did = $html->p_pair( "some text" );
	$should = "\n<p>some text</p>";
	result( $did eq $should, "p_pair( 'some text' ) returns '".vis($did)."'" );
	
	$did = $html->p_group( "some text" );
	$should = "\n<p>some text</p>";
	result( $did eq $should, "p_group( 'some text' ) returns '".vis($did)."'" );
	
	$did = $html->p_group( ['some','text'] );
	$should = "\n<p>some</p>\n<p>text</p>";
	result( $did eq $should, "p_group( ['some','text'] ) returns '".vis($did)."'" );
	
	$did = $html->a( href => 'url', text => 'here' );
	$should = "\n<a href=\"url\">here</a>";
	result( $did eq $should, "a( href => 'url', text => 'here' ) returns '".vis($did)."'" );
	
	$did = $html->input_group( -type => 'checkbox', -name => 'words',
		-value => ['eenie', 'meenie', 'minie', 'moe'], -checked => [1, 0, 1, 0],
		-text => ['Eenie', 'Meenie', 'Minie', 'Moe'] );
	$should = "\n<input type=\"checkbox\" name=\"words\" checked=\"1\" value=\"eenie\" />Eenie".
		"\n<input type=\"checkbox\" name=\"words\" value=\"meenie\" />Meenie".
		"\n<input type=\"checkbox\" name=\"words\" checked=\"1\" value=\"minie\" />Minie".
		"\n<input type=\"checkbox\" name=\"words\" value=\"moe\" />Moe";
	result( $did eq $should, "input_group( -type => 'checkbox', -name => ".
		"'words', -value => ['eenie', 'meenie', 'minie', 'moe'], -checked => ".
		"[1, 0, 1, 0], -text => ['Eenie', 'Meenie', 'Minie', 'Moe'] ) ".
		"returns '".vis($did)."'" );
	
	$did = serialize( $html->p_group( text => ['some','text'], list => 1 ) );
	$should = serialize( [ "\n<p>some</p>", "\n<p>text</p>" ] );
	result( $did eq $should, "p_group( text => ['some','text'], list => 1 ) returns '".vis($did)."'" );
	
	$html->groups_by_default( 0 );
	$did = $html->p( text => ['some','text'], list => 1 );
	$did =~ s/\(.*?\)/()/;
	$should = "\n<p>ARRAY()</p>";
	result( $did eq $should, "p( text => ['some','text'], list => 1 ) under no group by def returns '".vis($did)."'" );
	
	$html->groups_by_default( 1 );
	$did = serialize( $html->p( text => ['some','text'], list => 1 ) );
	$should = serialize( [ "\n<p>some</p>", "\n<p>text</p>" ] );
	result( $did eq $should, "p( text => ['some','text'], list => 1 ) under yes group by def returns '".vis($did)."'" );
}

######################################################################
# test start_html()

{
	my $html = new HTML::EasyTags();
	my ($did, $should);
	
	$did = $html->start_html();
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>Untitled Document</title>\n</head>\n<body>";
	result( $did eq $should, "start_html() returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my page' );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my page</title>\n</head>\n<body>";
	result( $did eq $should, "start_html( 'my page' ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my page', '<meta>' );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my page</title><meta>\n</head>\n<body>";
	result( $did eq $should, "start_html( 'my page', '<meta>' ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my page', '<meta>', {bgcolor=>'white'} );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my page</title><meta>\n</head>\n<body bgcolor=\"white\">";
	result( $did eq $should, "start_html( 'my page', '<meta>', {bgcolor=>'white'} ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my frameset', undef, undef, {} );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my frameset</title>\n</head>".
		"\n<frameset></frameset>".
		"\n<noframes>\n<body>";
	result( $did eq $should, "start_html( 'my frameset', undef, undef, {} ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my frameset', undef, undef, { rows => '100,*', cols => '200,*', border => 1 } );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my frameset</title>\n</head>".
		"\n<frameset rows=\"100,*\" cols=\"200,*\" border=\"1\"></frameset>".
		"\n<noframes>\n<body>";
	result( $did eq $should, "start_html( 'my frameset', undef, undef, { rows => '100,*', cols => '200,*', border => 1 } ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my frameset', undef, undef, '<frame name="left" SRC="abc"><frame name="right" SRC="xyz">' );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my frameset</title>\n</head>".
		"\n<frameset><frame name=\"left\" SRC=\"abc\"><frame name=\"right\" SRC=\"xyz\"></frameset>".
		"\n<noframes>\n<body>";
	result( $did eq $should, "start_html( 'my frameset', undef, undef, '<frame name=\"left\" SRC=\"abc\"><frame name=\"right\" SRC=\"xyz\">' ) returns '".vis($did)."'" );
	
	$did = $html->start_html( 'my frameset', undef, undef, { text => '<frame name="left" SRC="abc"><frame name="right" SRC="xyz">' } );
	$should = "\n<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n<html>".
		"\n<head>\n<title>my frameset</title>\n</head>".
		"\n<frameset><frame name=\"left\" SRC=\"abc\"><frame name=\"right\" SRC=\"xyz\"></frameset>".
		"\n<noframes>\n<body>";
	result( $did eq $should, "start_html( 'my frameset', undef, undef, { text => '<frame name=\"left\" SRC=\"abc\"><frame name=\"right\" SRC=\"xyz\">' } ) returns '".vis($did)."'" );
}
	
######################################################################
# test end_html()

{
	my $html = new HTML::EasyTags();
	my ($did, $should);
	
	$did = $html->end_html();
	$should = "\n</body>\n</html>";
	result( $did eq $should, "end_html() returns '".vis($did)."'" );
	
	$did = $html->end_html( 1 );
	$should = "\n</body>\n</noframes>\n</html>";
	result( $did eq $should, "end_html( 1 ) returns '".vis($did)."'" );
}
	
######################################################################

message( "DONE TESTING HTML::EasyTags" );

######################################################################

1;