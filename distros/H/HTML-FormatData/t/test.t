#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More 'no_plan';

BEGIN { use_ok('HTML::FormatData') };

no warnings;

my %strings = (
	s001 => 'Eric',
	s002 => 'Er&amp;ic',
	s003 => '<b>Eric</b>',
	s004 => '<b>Er&amp;ic</b>',
	s005 => '<b>Er&amp;ic</i>',
	s006 => "Er\nic",

	s007 => 'Eric Folley',
	s008 => 'Eric&quot;Folley',
	s009 => '<span class="foo">Eric Folley</span>',
	s010 => '<b>Eric&quot;Folley</b>',
	s011 => "Eric \nFolley",

	s012 => '',
	s013 => undef,
);

my $f = HTML::FormatData->new;

# no jobs: we should get back whatever we put in
{
	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s} );
		my $testname = "no jobs: $s ($strings{$s})";
		is( $rv, $strings{$s}, $testname );
	}
}


# job: decode_xml
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&ic</b>',
		s005 => '<b>Er&ic</i>',
		s006 => "Er\nic",
	
		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric \nFolley",
	
		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, decode_xml=>1 );
		my $testname = "decode_xml: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}

# job: decode_html
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&ic</b>',
		s005 => '<b>Er&ic</i>',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric"Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric"Folley</b>',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, decode_html=>1 );
		my $testname = "decode_html: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}

# job: strip_html
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => 'Eric',
		s004 => 'Er&amp;ic',
		s005 => 'Er&amp;ic',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => 'Eric Folley',
		s010 => 'Eric&quot;Folley',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, strip_html=>1 );
		my $testname = "strip_html: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}

# job: strip_whitespace
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Eric",

		s007 => 'EricFolley',
		s008 => 'Eric&quot;Folley',
		s009 => '<spanclass="foo">EricFolley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "EricFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, strip_whitespace=>1 );
		my $testname = "strip_whitespace: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}

# job: clean_encoded_html
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, clean_encoded_html=>1 );
		my $testname = "clean_encoded_html: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: clean_encoded_text
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, clean_encoded_text=>1 );
		my $testname = "clean_encoded_text: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: clean_whitespace
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Er ic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric Folley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, clean_whitespace=>1 );
		my $testname = "clean_whitespace: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: clean_whitespace_keep_all_breaks
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, clean_whitespace_keep_all_breaks=>1 );
		my $testname = "clean_whitespace_keep_all_breaks: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: clean_whitespace_keep_full_breaks
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;ic',
		s003 => '<b>Eric</b>',
		s004 => '<b>Er&amp;ic</b>',
		s005 => '<b>Er&amp;ic</i>',
		s006 => "Er ic",

		s007 => 'Eric Folley',
		s008 => 'Eric&quot;Folley',
		s009 => '<span class="foo">Eric Folley</span>',
		s010 => '<b>Eric&quot;Folley</b>',
		s011 => "Eric Folley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, clean_whitespace_keep_full_breaks=>1 );
		my $testname = "clean_whitespace_keep_full_breaks: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: force_lc
{
	my %outputs = (
		s001 => 'eric',
		s002 => 'er&amp;ic',
		s003 => '<b>eric</b>',
		s004 => '<b>er&amp;ic</b>',
		s005 => '<b>er&amp;ic</i>',
		s006 => "er\nic",

		s007 => 'eric folley',
		s008 => 'eric&quot;folley',
		s009 => '<span class="foo">eric folley</span>',
		s010 => '<b>eric&quot;folley</b>',
		s011 => "eric \nfolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, force_lc=>1 );
		my $testname = "force_lc: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: force_uc
{
	my %outputs = (
		s001 => 'ERIC',
		s002 => 'ER&AMP;IC',
		s003 => '<B>ERIC</B>',
		s004 => '<B>ER&AMP;IC</B>',
		s005 => '<B>ER&AMP;IC</I>',
		s006 => "ER\nIC",

		s007 => 'ERIC FOLLEY',
		s008 => 'ERIC&QUOT;FOLLEY',
		s009 => '<SPAN CLASS="FOO">ERIC FOLLEY</SPAN>',
		s010 => '<B>ERIC&QUOT;FOLLEY</B>',
		s011 => "ERIC \nFOLLEY",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, force_uc=>1 );
		my $testname = "force_uc: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: truncate_with_ellipses (8)
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&am...',
		s003 => '<b>Er...',
		s004 => '<b>Er...',
		s005 => '<b>Er...',
		s006 => "Er\nic",

		s007 => 'Eric ...',
		s008 => 'Eric&...',
		s009 => '<span...',
		s010 => '<b>Er...',
		s011 => "Eric ...",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, truncate_with_ellipses=>8 );
		my $testname = "decode html: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: truncate (8)
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;i',
		s003 => '<b>Eric<',
		s004 => '<b>Er&am',
		s005 => '<b>Er&am',
		s006 => "Er\nic",

		s007 => 'Eric Fol',
		s008 => 'Eric&quo',
		s009 => '<span cl',
		s010 => '<b>Eric&',
		s011 => "Eric \nFo",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, truncate=>8 );
		my $testname = "truncate_no_ellipses: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: encode_xml
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;amp;ic',
		s003 => '&lt;b&gt;Eric&lt;/b&gt;',
		s004 => '&lt;b&gt;Er&amp;amp;ic&lt;/b&gt;',
		s005 => '&lt;b&gt;Er&amp;amp;ic&lt;/i&gt;',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&amp;quot;Folley',
		s009 => '&lt;span class="foo"&gt;Eric Folley&lt;/span&gt;',
		s010 => '&lt;b&gt;Eric&amp;quot;Folley&lt;/b&gt;',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, encode_xml=>1 );
		my $testname = "encode_xml: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}
# job: encode_html
{
	my %outputs = (
		s001 => 'Eric',
		s002 => 'Er&amp;amp;ic',
		s003 => '&lt;b&gt;Eric&lt;/b&gt;',
		s004 => '&lt;b&gt;Er&amp;amp;ic&lt;/b&gt;',
		s005 => '&lt;b&gt;Er&amp;amp;ic&lt;/i&gt;',
		s006 => "Er\nic",

		s007 => 'Eric Folley',
		s008 => 'Eric&amp;quot;Folley',
		s009 => '&lt;span class=&quot;foo&quot;&gt;Eric Folley&lt;/span&gt;',
		s010 => '&lt;b&gt;Eric&amp;quot;Folley&lt;/b&gt;',
		s011 => "Eric \nFolley",

		s012 => '',
		s013 => undef,
	);

	foreach my $s ( sort keys %strings ) {
		my $rv = $f->format_text( $strings{$s}, encode_html=>1 );
		my $testname = "encode_html: $s ($strings{$s})";
		is( $rv, $outputs{$s}, $testname );
	}
}

### format_date
{
	my $dt = DateTime->new(
		year		=> '2004',
		month		=> '01',
		day			=> '01',
		hour		=> '12',
		minute		=> '34',
		second		=> '56',
		time_zone	=> 'UTC',
	);

	my $dt_str = $f->format_date( $dt, '%s' );
	is( $dt_str, '1072960496' );

	$dt_str = $f->format_date( $dt, '%Y%m%d%H%M%S' );
	is( $dt_str, '20040101123456' );

	$dt_str = $f->format_date( $dt, '%m-%d-%y' );
	is( $dt_str, '01-01-04' );
}

### parse_date
{
	my $dt_str = '20040101123456';
	my $dt = $f->parse_date( $dt_str, '%Y%m%d%H%M%S' );
	isa_ok( $dt, 'DateTime' );
	my $secs = $f->format_date( $dt, '%s' );
	is( $secs, '1072978496' );

	$dt_str = 'Mar 15 2004';
	$dt = $f->parse_date( $dt_str, '%b %d %Y' );
	isa_ok( $dt, 'DateTime' );
	$secs = $f->format_date( $dt, '%s' );
	is( $secs, '1079326800' );
}

