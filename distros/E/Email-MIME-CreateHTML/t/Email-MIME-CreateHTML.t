#!/usr/local/bin/perl

##################################################################################
# -t : Trace
# -T : Deep Trace
# -m <address> : send the emails that we create for each test (set $SMTP_HOST)
##################################################################################

use strict;
use vars qw/$opt_m/;
use Test::Assertions::TestScript(tests => 49, options => {'m=s' => \$opt_m});
use File::Slurp;
use File::Copy;

my $mailto = $opt_m || 'somebody@example.com';

# SetUp
my $text_body = "Hello World";
my $html_body = "<html><body>Hello HTML World</body></html>";
my ($html_in, $html_out);

#######################################################
#
# The tests
#
#######################################################

use Email::MIME;
use Email::MIME::CreateHTML;
ASSERT(1,"compiled version $Email::MIME::CreateHTML::VERSION");

#
# Test Mail Construction
#

# HTML, no embedded objects, no text alternative
# ----------------------------------------------
my $mime = Email::MIME->create_html(
	header => [
		From => 'unittest_a@example.co.uk',
		To => $mailto,
		Subject => 'HTML, no embedded objects, no text alternative',
	],
	body => $html_body,
);

ASSERT(ref $mime eq 'Email::MIME', "------ HTML, no embedded objects, no text alternative - Email::MIME object returned");

test_mime( $mime, qr'text/html', $html_body );

send_mail( $mime ) if($opt_m);


# HTML, no embedded objects, with text alternative
# ------------------------------------------------
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_b@example.co.uk',
		To => $mailto,
		Subject => 'HTML, no embedded objects, with text alternative',
	],
	body => $html_body,
	text_body => $text_body,
);

ASSERT(ref $mime eq 'Email::MIME', "------ HTML, no embedded objects, with text alternative - Email::MIME object returned");

test_mime( $mime, qr'multipart/alternative', undef );

my @parts = $mime->parts;
ASSERT( scalar(@parts) == 2, "number of parts");
test_mime( $parts[0], qr'text/plain', $text_body );
test_mime( $parts[1], qr'text/html', $html_body );

send_mail( $mime ) if($opt_m);


# HTML with embedded objects, no text alternative
# using objects hash
# -----------------------------------------------
# inline_css is false, no base or base_rewrite
# -----------------------------------------------
$html_in = read_file( './data/CreateHTML_01.html' );
$html_out = $html_in;
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_c@example.co.uk',
		To => $mailto,
		Subject => 'HTML with embedded objects, no text alternative',
	],
	body => $html_in,
	objects => {
		'123@bbc.co.uk' => './data/end.png',
		'landscapeview' => './data/landscape.jpg',
	},
	inline_css => 0,
);

ASSERT(ref $mime eq 'Email::MIME', "------ HTML with embedded objects, no text alternative - Email::MIME object returned");

test_mime( $mime, qr'multipart/related', undef );

@parts = $mime->parts;
ASSERT( scalar(@parts) == 3, "number of parts");
test_mime( $parts[0], qr'text/html', $html_out );
my $p = join '', map defined $_ ? $_->content_type : '', @parts[1..2];
ASSERT($p =~ m|image/png|i && $p =~ m|image/jpeg|i, "Mime types image/png and image/jpeg");

send_mail( $mime ) if($opt_m);

# HTML with embedded objects, with text alternative
# using embedded images
# -----------------------------------------------
# inline_css default on, base with base_rewrite, embed default on,
# multiple reference to same object do not cause multiple attached mime parts,
# can use objects and embed together, fully qualified links are not rewritten
# -----------------------------------------------
$html_in = read_file( './data/CreateHTML_02a.html' );
$html_out = read_file( './data/CreateHTML_02b.html' );
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_d@example.co.uk',
		To => $mailto,
		Subject => 'HTML with embedded objects, with text alternative',
	],
	body => $html_in,
	text_body => $text_body,
	base => './data',
	objects => {
		'123@bbc.co.uk' => 'end.png',
	},
	inline_javascript => 1,
);

ASSERT(ref $mime eq 'Email::MIME', "------ HTML with embedded objects, with text alternative - Email::MIME object returned");

test_mime( $mime, qr'multipart/alternative', undef );

@parts = $mime->parts;
ASSERT( scalar(@parts) == 2, "number of parts");
test_mime( $parts[0], qr'text/plain', $text_body );
test_mime( $parts[1], qr'multipart/related', undef );

my @sub_parts = defined $parts[1] ? $parts[1]->parts : ();
ASSERT( scalar(@sub_parts) == 3, "number of parts");
test_mime( $sub_parts[0], qr'text/html', $html_out );
my $sp = [map { defined($_) ? $_->content_type : () } @sub_parts[1..2]];
DUMP("Sub parts",$sp);
ASSERT((grep { m!image/png!i } @$sp), "MIME type image/png present");
ASSERT((grep { m!image/jpeg!i } @$sp), "MIME type image/jpeg present");

send_mail( $mime ) if($opt_m);


# HTML with embedded objects, no text alternative
# use a different char set
# -----------------------------------------------
# no base but have base_rewrite, embed is false
# -----------------------------------------------
$html_in = read_file( './data/CreateHTML_03a.html' );
$html_out = read_file( './data/CreateHTML_03b.html' );
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_e@example.co.uk',
		To => $mailto,
		Subject => 'HTML with embedded objects, no text alternative, uses ISO-8859-1',
	],
	body => $html_in,
	body_attributes => { charset => 'ISO-8859-1' },
	objects => {
		'landscapeview' => './data/landscape.jpg',
	},
	embed => 0,
);

ASSERT(ref $mime eq 'Email::MIME', "------ HTML with embedded objects, no text alternative - Email::MIME object returned");

test_mime( $mime, qr'multipart/related', undef );

@parts = $mime->parts;
ASSERT( scalar(@parts) == 2, "number of parts");
test_mime( $parts[0], qr'text/html', $html_out );
test_mime( $parts[1], qr'image/jpeg', undef );

send_mail( $mime ) if($opt_m);


# Caching
# ----------------------------------------------
my $cache = "this is not a cache object";
ASSERT( copy( './data/landscape.jpg','./data/cache_test_landscape.jpg' ) &&
		copy( './data/end.png','./data/cache_test_end.png' ), "------ Caching : Image files in place" );
$html_in = read_file( './data/CreateHTML_04a.html' );
$html_out = read_file( './data/CreateHTML_04b.html' );
# bad cache object
eval {
	$mime = Email::MIME->create_html(
		header => [
			From => 'unittest_f@example.co.uk',
			To => $mailto,
			Subject => 'Test of caching',
		],
		body => $html_in,
		base => './data',
		objects => {
			'abcdefghi@bbc.co.uk' => 'cache_test_end.png',
		},
		object_cache => $cache,
	);
};
ASSERT( scalar( $@ =~ /object_cache must be an object/ ), "Bad object_cache caught");
# good cache object
$cache = new UnitTestCache();
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_f@example.co.uk',
		To => $mailto,
		Subject => 'Test of caching',
	],
	body => $html_in,
	base => './data',
	objects => {
		'abcdefghi@bbc.co.uk' => 'cache_test_end.png',
	},
	object_cache => $cache,
);
ASSERT( ref $mime eq 'Email::MIME', "mime object created");
@parts = $mime->parts;
ASSERT( scalar(@parts) == 3, "number of parts");
test_mime( $parts[0], qr'text/html', $html_out );
test_mime( $parts[1], qr'image/png', undef );
test_mime( $parts[2], qr'image/jpeg', undef );
ASSERT( unlink('./data/cache_test_landscape.jpg', './data/cache_test_end.png') == 2, "Image files removed" );
$mime = Email::MIME->create_html(
	header => [
		From => 'unittest_f@example.co.uk',
		To => $mailto,
		Subject => 'Test of caching',
	],
	body => $html_in,
	base => './data',
	objects => {
		'abcdefghi@bbc.co.uk' => 'cache_test_end.png',
	},
	object_cache => $cache,
);
ASSERT( ref $mime eq 'Email::MIME', "mime object created (second mail)");
@parts = $mime->parts;
ASSERT( scalar(@parts) == 3, "number of parts");
test_mime( $parts[0], qr'text/html', $html_out );
test_mime( $parts[1], qr'image/png', undef );
test_mime( $parts[2], qr'image/jpeg', undef );

send_mail( $mime ) if($opt_m);

# End of tests
#######################################################
#
# Subroutines
#
#######################################################

sub test_mime {
	my ($mime, $exp_content_type, $exp_body) = @_;

	my $got_content_type = defined $mime ? $mime->content_type : undef;
	ASSERT( defined $got_content_type && $got_content_type =~ /^$exp_content_type/i, "content-type: $got_content_type");

	if ( defined $exp_body ) {
		my $got_body;

		$exp_body =~ s/\s+$//g;
		$exp_body =~ s/(?<!\r)\n/\r\n/g; # MIME mandates CRLF line endings in all encodings except binary

		if(defined $mime) {
		    $got_body = $mime->body;
			# we don't care about trailing white space
	 	    $got_body =~ s/\s+$//g;
			# This is a quick fix to allow us to test against randomly generated cids
			# note that the 10 is because the existing tests had some short all numeric cids
			$got_body =~ s/cid:\d{10}\d+/cid:/g;
		}
		DUMP("test_mime", { expected => $exp_body, got => $got_body });
		ASSERT(defined $got_body && $got_body eq $exp_body, "body");
	}
}

# Actually send the mail
sub send_mail {
	my $email = shift;
	my $smtp_host = $ENV{SMTP_HOST} || 'localhost';
	warn "SMTP_HOST env var not set in environment using 'localhost'\n" unless ($ENV{SMTP_HOST});
	require Email::Send;
	warn "Sending email to '$mailto'...\n";
	if ( $Email::Send::VERSION < 2.0 ) {
		my $rv = Email::Send::send('SMTP',$email, $smtp_host);
		die $rv if ! $rv;
	}
	else {
		my $sender = Email::Send->new({mailer => 'SMTP'});
		$sender->mailer_args([Host => $smtp_host]);
		my $rv = $sender->send($email);
		die $rv if ! $rv;
	}
}

#######################################################
#
# Simple in-memory cache for testing
#
#######################################################

package UnitTestCache;

sub new {
	return bless({}, shift());	
}

sub set {
	my ($self, $key, $value) = @_;
	$self->{$key} = $value;
}

sub get {
	my ($self, $key) = @_;	
	return $self->{$key};
}

1;
