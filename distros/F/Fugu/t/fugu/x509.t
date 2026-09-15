#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Guards for Fugu::X509
#
# The test makes its own certificates through generate, because a
# committed certificate expires and the tree then fails on a date.
# The subtests that need a certificate skip when openssl(1) is absent,
# and each subtest that reads a PEM block or a DER element builds its
# own bytes and runs everywhere.
#
# Each assertion over a real certificate reads the answer of
# openssl(1) itself, so no assertion rests on the module that it
# checks. The two validity subtests read the days that the generator
# took: openssl(1) writes notBefore at the current second and
# notAfter that many days later, so the difference of the two answers
# is an exact number.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Temp   qw(tempdir);
use MIME::Base64 qw(decode_base64 encode_base64);
use Digest::SHA  ();
use Time::Local  qw(timegm_modern);
use FindBin      qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::X509');
use Fugu::Process;

my $WORK = tempdir( 'fugu-x509-XXXXXXXX', TMPDIR => 1, CLEANUP => 1 );

# The object of the byte reader. Each reader is a method now, and it
# needs no command, so this object serves every reader subtest.
my $X509 = Fugu::X509->new;

# The subject of every certificate that this test makes. The four
# attributes cover the types that a code signing certificate holds,
# and the values hold a space, so the reader must keep one.
my $SUBJECT = '/C=SE/O=Fugu Example/OU=Fugu Team/CN=Fugu Test';
my %EXPECTED = (
	C  => 'SE',
	O  => 'Fugu Example',
	OU => 'Fugu Team',
	CN => 'Fugu Test',
);

# The first second of 2050, in UTC. RFC 5280 holds a certificate that
# expires then or later to a GeneralizedTime, so a notAfter above
# this bound proves the second time form.
use constant YEAR_2050 => 2_524_608_000;

# The bytes that the built certificates hold. 2.5.4.3 is the common
# name, and 2.5.4.15 is the business category, which the name table
# of the module does not hold. The tags name the DER forms that the
# subtests of the reader need.
use constant {
	OID_CN                => "\x55\x04\x03",
	OID_BUSINESS_CATEGORY => "\x55\x04\x0F",
	TAG_OCTET_STRING      => 0x04,
	TAG_UTF8_STRING       => 0x0C,
	TAG_PRINTABLE_STRING  => 0x13,
	TAG_UTC_TIME          => 0x17,
	TAG_GENERALIZED_TIME  => 0x18,
	TAG_BMP_STRING        => 0x1E,
};

my $openssl = Fugu::Process->find_command( undef, 'openssl' );

# reader($method, @args):
#	The answer of one reader, and the reason of a failure. Each
#	reader reports through error, per LIB-SIGNER-8, so a subtest
#	that checks a failure reads the two together.
sub reader ( $method, @args )
{
	my $answer = $X509->$method(@args);

	return ( $answer, $X509->error );
}

# pem_block($type, $bytes):
#	A PEM block of the type over the bytes. The block-rule
#	subtests need no certificate, so they build their own body.
sub pem_block ( $type, $bytes )
{
	return "-----BEGIN $type-----\n"
	    . encode_base64( $bytes, "\n" )
	    . "-----END $type-----\n";
}

# write_file($path, $bytes):
#	Write a fixture file, and answer the path.
sub write_file ( $path, $bytes )
{
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "Cannot close $path: $!";

	return $path;
}

# slurp($path):
#	The bytes of a file.
sub slurp ($path)
{
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/ = undef;
	my $bytes = <$fh>;
	close $fh;

	return $bytes;
}

# openssl(@args):
#	Run openssl(1) and answer the standard output. The check
#	drives the command directly, so no assertion rests on the
#	module that it checks.
sub openssl (@args)
{
	my $result = Fugu::Process->run(
		cmd     => [ $openssl, @args ],
		timeout => 120,
		env     => { PATH => $ENV{PATH} // '', LC_ALL => 'C' },
	);
	die "openssl @args: $result->{stderr}" unless $result->{success};

	return $result->{stdout};
}

# make_certificate($stem, $days):
#	A self-signed certificate and its private key, as two paths.
#	The generator of the module makes the pair, so the tree
#	carries no certificate that expires. The pair carries no
#	passphrase, and it dies with the work directory of this test.
sub make_certificate ( $stem, $days )
{
	my $certificate = "$WORK/$stem.pem";
	my $secret      = "$WORK/$stem.key";

	my $x509 = Fugu::X509->new;
	$x509->generate(
		public  => $certificate,
		secret  => $secret,
		subject => $SUBJECT,
		days    => $days
	) or die "Cannot generate $certificate: " . $x509->error;

	return ( $certificate, $secret );
}

# der($tag, $bytes):
#	One DER element of the tag over the bytes. The helper writes
#	the short length form under 128 bytes, and the one-byte long
#	form above it. Each element of this test is smaller than 256
#	bytes.
sub der ( $tag, $bytes )
{
	die 'the DER helper writes no length above 255 bytes'
	    if length $bytes > 255;

	my $length =
	    length($bytes) < 128
	    ? chr( length $bytes )
	    : "\x81" . chr( length $bytes );

	return chr($tag) . $length . $bytes;
}

# attribute($oid, $tag, $value):
#	One attribute of a name, as a SEQUENCE of the object
#	identifier and the value.
sub attribute ( $oid, $tag, $value )
{
	return der( 0x30, der( 0x06, $oid ) . der( $tag, $value ) );
}

# rdn(@attribute):
#	One relative distinguished name, as a SET of the attributes.
sub rdn (@attribute)
{
	return der( 0x31, join '', @attribute );
}

# certificate(%args):
#	The DER bytes of a certificate that holds the fields which
#	parse reads: the serial number, the signature algorithm, the
#	issuer, the validity and the subject. An argument replaces
#	one field, so a test names the one field that it breaks.
#
#	openssl(1) writes a correct certificate only, so it reaches
#	no failure branch of the reader. The test therefore builds
#	these bytes itself, and each subtest of a failure branch runs
#	where openssl(1) is absent.
sub certificate (%args)
{
	my $name = rdn( attribute( OID_CN, TAG_PRINTABLE_STRING, 'Fugu Test' ) );
	my $time = der( TAG_UTC_TIME, '240102030405Z' );

	# The serial number stands first, because a version 1
	# certificate holds no version element. The signature
	# algorithm is an empty SEQUENCE: the walk reads its tag and
	# steps over it.
	my $tbs =
	      der( 0x02, "\x01" )
	    . der( 0x30, '' )
	    . der( 0x30, $args{issuer} // $name )
	    . der( 0x30,
		( $args{not_before} // $time ) . ( $args{not_after} // $time ) )
	    . der( 0x30, $args{subject} // $name );

	return der( 0x30, der( 0x30, $tbs ) );
}

# --- the shape of the module ----------------------------------------------

subtest 'the module follows the signer shape' => sub {
	isa_ok( $X509, 'Fugu::Signer' );

	ok( Fugu::X509->can('generate'), 'generate exists' );
	ok( Fugu::X509->can('sign'),     'sign exists' );
	ok( Fugu::X509->can('verify'),   'verify exists' );

	# The parent holds the command resolution, so the module holds
	# no resolver of its own.
	ok( !Fugu::X509->can('_find_command'),
		'the module holds no resolver of its own' );

	# The old names took the signature as text, and LIB-SIGNER-2
	# names the three verbs. No shim keeps the old shape.
	ok( !Fugu::X509->can('sign_cms'),   'sign_cms is gone' );
	ok( !Fugu::X509->can('verify_cms'), 'verify_cms is gone' );

	# A reader reports through error now, so the failure helper of
	# the class methods is gone too.
	ok( !Fugu::X509->can('_fail'), 'the reader holds no failure helper' );

	# The parent names the command through the label and the
	# search list of the subclass.
	is( $X509->_command_label, 'openssl', 'the label names the command' );
	is_deeply( [ $X509->_command_defaults ],
		['openssl'], 'and the search list names openssl' );
};

subtest 'the module raises the timeout of the parent' => sub {

	# LIB-X509-8 holds the default at 300 seconds, over the parent
	# default of 30, because a signature reads the whole file. The
	# constructor runs no process, so the subtest runs where
	# openssl(1) is absent.
	is( Fugu::X509->new->{timeout},
		300, 'the default timeout is 300 seconds' );
	is( Fugu::X509->new( timeout => 5 )->{timeout},
		5, 'and the caller names its own' );
};

# --- the byte reader ------------------------------------------------------

subtest 'a reader answers no reason in list context' => sub {

	# LIB-SIGNER-8 forbids a reason as a second return value. A
	# reader that kept the old shape would answer two values here,
	# and the reason would reach a caller that asked for one
	# answer.
	for my $case ( [ 'decode_pem', 'no block here' ],
		[ 'fingerprint', "\x{263A}" ],
		[ 'parse',       "\x30" ] )
	{
		my ( $method, $input ) = @$case;
		my @answer = $X509->$method($input);
		my $reason = $X509->error;

		is( $answer[0], undef, "$method answers undef" );
		ok( length($reason), 'and error holds the reason' );
		cmp_ok( scalar @answer, '<=', 1,
			'and the method answers no second value' );
		is( scalar( grep { defined && $_ eq $reason } @answer ),
			0, 'and no return value holds the reason' );
	}
};

subtest 'the reader needs bytes, and says so' => sub {

	# Digest::SHA dies on a string that holds a code point above
	# 255, and a byte read takes the low byte of each character.
	# The contract is a clean failure, so each method tests it.
	my $wide = "\x{263A}";

	my ( $der, $pem_reason ) = reader( 'decode_pem', $wide );
	is( $der, undef, 'decode_pem answers undef for a wide string' );
	like( $pem_reason, qr/above 255/, 'and the reason says so' );

	my ( $hex, $hex_reason ) = reader( 'fingerprint', $wide );
	is( $hex, undef, 'fingerprint answers undef for a wide string' );
	like( $hex_reason, qr/above 255/, 'and the reason says so' );

	my ( $parsed, $parse_reason ) = reader( 'parse', $wide );
	is( $parsed, undef, 'parse answers undef for a wide string' );
	like( $parse_reason, qr/above 255/, 'and the reason says so' );

	for my $method (qw(decode_pem fingerprint parse)) {
		my ( $answer, $reason ) = reader( $method, undef );
		is( $answer, undef, "$method answers undef for undef" );
		like( $reason, qr/undef/, 'and the reason says so' );
	}
};

subtest 'a reader clears the reason of the call before it' => sub {

	# Each reader starts one call, per LIB-SIGNER-8. A reader that
	# kept the reason of a failed call would report a failure
	# after a success.
	my ( $failed, $reason ) = reader( 'decode_pem', 'no block here' );
	is( $failed, undef, 'the first call fails' );
	ok( length $reason, 'and it holds a reason' );

	my ( $hex, $clean ) = reader( 'fingerprint', 'the certificate bytes' );
	ok( defined $hex, 'the call after it answers' );
	is( $clean, undef, 'and error holds no reason of the call before it' );
};

subtest 'decode_pem answers the body of one CERTIFICATE block' => sub {
	my $bytes = join '', map { chr } 0 .. 255;

	my ( $der, $reason ) =
	    reader( 'decode_pem', pem_block( 'CERTIFICATE', $bytes ) );
	is( $der,    $bytes, 'the block decodes to its bytes' );
	is( $reason, undef,  'and it reports no reason' );
};

subtest 'decode_pem takes one CERTIFICATE block and no other' => sub {
	my $certificate = pem_block( 'CERTIFICATE', 'the certificate' );
	my $secret      = pem_block( 'PRIVATE KEY', 'the private key' );

	# A key directory publishes what this method accepts, so a
	# private key block must never decode as a certificate.
	my ( $alone, $alone_reason ) = reader( 'decode_pem', $secret );
	is( $alone, undef, 'a private key block alone fails' );
	like( $alone_reason, qr/PRIVATE KEY block/,
		'and the reason names the block type' );

	my ( $both, $both_reason ) =
	    reader( 'decode_pem', $certificate . $secret );
	is( $both, undef, 'a certificate with its private key fails' );
	like( $both_reason, qr/PRIVATE KEY block/,
		'and the reason names the private key' );

	my ( $two, $two_reason ) =
	    reader( 'decode_pem', $certificate . $certificate );
	is( $two, undef, 'a second certificate block fails' );
	like( $two_reason, qr/2 CERTIFICATE blocks/,
		'and the reason counts the blocks' );

	my ( $none, $none_reason ) = reader( 'decode_pem', "no block here\n" );
	is( $none, undef, 'a text with no block fails' );
	like( $none_reason, qr/no BEGIN CERTIFICATE/,
		'and the reason names the missing line' );

	my $truncated = $certificate;
	$truncated =~ s/^-----END.*\n//m;
	my ( $end, $end_reason ) = reader( 'decode_pem', $truncated );
	is( $end, undef, 'a block with no END line fails' );
	like( $end_reason, qr/no END CERTIFICATE/,
		'and the reason names the missing line' );
};

subtest 'decode_pem holds the body to the base64 alphabet' => sub {

	# MIME::Base64 skips a character that no alphabet holds, so a
	# body of the right character count with one bad character
	# decodes to a shorter certificate. The method must catch that
	# itself: a PEM block holds no checksum line.
	my @case = (
		[ 'a character of no alphabet', 'QU*D', qr/no base64 text/ ],
		[ 'a part of a group',          'QUJ',  qr/whole number of/ ],
		[
			'padding before the end', "QQ==\nQUJD",
			qr/padding sits before the end/
		],
	);

	for my $case (@case) {
		my ( $label, $body, $expected ) = @$case;
		my $text =
		    "-----BEGIN CERTIFICATE-----\n$body\n"
		    . "-----END CERTIFICATE-----\n";
		my ( $der, $reason ) = reader( 'decode_pem', $text );
		is( $der, undef, "a body with $label fails" )
		    or next;
		like( $reason, $expected, 'and the reason says why' );
	}

	my ( $empty, $empty_reason ) = reader( 'decode_pem',
		"-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----\n" );
	is( $empty, undef, 'a block with no body fails' );
	like( $empty_reason, qr/no text between/, 'and the reason says so' );
};

subtest 'decode_pem reads either line ending and a padded line' => sub {
	my $bytes = 'the certificate bytes';
	my $text  = pem_block( 'CERTIFICATE', $bytes );

	my $crlf = $text =~ s/\n/\r\n/gr;
	is( $X509->decode_pem($crlf),
		$bytes, 'a block with CRLF gives the same bytes' );

	# A mailer pads a line with a space or a tab.
	my $padded = $text =~ s/\n/ \t\n/gr;
	is( $X509->decode_pem($padded),
		$bytes, 'a padded block gives the same bytes' );

	my $copy = $text;
	$X509->decode_pem($copy);
	is( $copy, $text, 'the method never changes the string of the caller' );
};

subtest 'decode_pem bounds the input size' => sub {
	my $huge =
	      "-----BEGIN CERTIFICATE-----\n"
	    . encode_base64( 'x' x ( 2 * 1024 * 1024 ), "\n" )
	    . "-----END CERTIFICATE-----\n";

	my ( $der, $reason ) = reader( 'decode_pem', $huge );
	is( $der, undef, 'a text above the bound fails' );
	like( $reason, qr/larger than/, 'and the reason says so' );
};

subtest 'fingerprint answers the upper-case SHA-256 of the bytes' => sub {
	my $bytes = 'the certificate bytes';

	my ( $hex, $reason ) = reader( 'fingerprint', $bytes );
	is( $hex, uc Digest::SHA::sha256_hex($bytes),
		'the answer is the SHA-256 in upper case' );
	is( $reason, undef, 'and it reports no reason' );
	like( $hex, qr/\A[0-9A-F]{64}\z/,
		'and it holds 64 hexadecimal characters with no separator' );
};

subtest 'parse rejects bytes that hold no certificate' => sub {
	my %case = (
		''     => qr/holds no tag/,
		"\x30" => qr/holds no tag/,

		# A SEQUENCE that names 10 content bytes and holds 3.
		"\x30\x0A\x02\x01\x01" => qr/content is truncated/,

		# A SET where the certificate stands.
		"\x31\x03\x02\x01\x01" => qr/tag 0x31, and not 0x30/,

		# The indefinite length of BER, which DER never writes.
		"\x30\x80\x02\x01\x01\x00\x00" => qr/indefinite length/,

		# A multi-byte tag, which a certificate never holds.
		"\x3F\x81\x00\x02\x01\x01" => qr/multi-byte tag/,

		# A whole SEQUENCE with one byte after it.
		"\x30\x03\x02\x01\x01\x00" => qr/bytes follow the certificate/,

		# A certificate holds a tbsCertificate first.
		"\x30\x03\x02\x01\x01" => qr/tbsCertificate: tag 0x02/,
	);

	for my $der ( sort keys %case ) {
		my ( $parsed, $reason ) = reader( 'parse', $der );
		is( $parsed, undef, sprintf 'the DER %s fails', unpack 'H*', $der )
		    or next;
		like( $reason, $case{$der}, 'and the reason says why' );
	}
};

subtest 'parse reads each time form and each century' => sub {

	# Time::Local answers the epoch here, so no assertion rests
	# on the module that it checks. A UTCTime year of 50 or above
	# names the last century, per RFC 5280 section 4.1.2.5.
	my %case = (
		'a UTCTime of this century' =>
		    [ TAG_UTC_TIME, '240102030405Z', 2024, 1, 2, 3, 4, 5 ],
		'a UTCTime of the last century' =>
		    [ TAG_UTC_TIME, '960102030405Z', 1996, 1, 2, 3, 4, 5 ],
		'a GeneralizedTime' => [
			TAG_GENERALIZED_TIME, '20510102030405Z',
			2051, 1, 2, 3, 4, 5
		],
		'the 29th of February in a leap year' =>
		    [ TAG_UTC_TIME, '240229120000Z', 2024, 2, 29, 12, 0, 0 ],
	);

	for my $label ( sort keys %case ) {
		my ( $tag, $text, @field ) = @{ $case{$label} };
		my ( $year, $month, $day, $hour, $minute, $second ) = @field;

		my ( $parsed, $reason ) = reader( 'parse',
			certificate( not_before => der( $tag, $text ) ) );
		unless ( ok( defined $parsed, "$label parses" ) ) {
			diag($reason);
			next;
		}

		is(
			$parsed->{not_before},
			timegm_modern(
				$second, $minute, $hour, $day, $month - 1, $year
			),
			"and $label names the second of the epoch"
		);
	}
};

subtest 'parse rejects a time that names no date' => sub {

	# The reader reads each field before it computes, so the 31st
	# of April is a failure and never a date in May.
	my %case = (
		'a month above 12' =>
		    [ TAG_UTC_TIME, '241302030405Z', qr/month 13 is no month/ ],
		'a day above the length of its month' => [
			TAG_UTC_TIME, '240431030405Z',
			qr/day 31 is no day of month 4/
		],
		'an hour above 23' => [
			TAG_UTC_TIME, '240102240405Z',
			qr/24:4:5 is no time of day/
		],
		'the 29th of February in a common year' => [
			TAG_UTC_TIME, '230229120000Z',
			qr/day 29 is no day of month 2/
		],
		'a UTCTime of four year digits' => [
			TAG_UTC_TIME, '20240102030405Z',
			qr/a UTCTime holds YYMMDDHHMMSSZ/
		],
		'a tag that names no time' => [
			TAG_OCTET_STRING, '240102030405Z',
			qr/tag 0x04 names no time/
		],
	);

	for my $label ( sort keys %case ) {
		my ( $tag, $text, $expected ) = @{ $case{$label} };

		my ( $parsed, $reason ) = reader( 'parse',
			certificate( not_before => der( $tag, $text ) ) );
		is( $parsed, undef, "a notBefore with $label fails" ) or next;
		like( $reason, qr/\Athe notBefore: /,
			'and the reason names the field' );
		like( $reason, $expected, 'and it says why' );
	}
};

subtest 'parse rejects a name that it cannot read' => sub {
	my $cn   = attribute( OID_CN, TAG_PRINTABLE_STRING, 'Fugu Test' );
	my $form = 'IA5String, PrintableString, UTF8String';

	# A hash holds one value for each type, so a caller that pins
	# a team identifier must never read one of two values.
	my %case = (
		'two attributes of one type in one set' =>
		    [ rdn( $cn, $cn ), qr/two attributes of type CN/ ],
		'two attributes of one type in two sets' =>
		    [ rdn($cn) . rdn($cn), qr/two attributes of type CN/ ],
		'an attribute value under an unsupported string tag' => [
			rdn( attribute( OID_CN, TAG_BMP_STRING, "\x00F" ) ),
			qr/value is tag 0x1E, and this reader takes \Q$form\E/
		],
	);

	for my $label ( sort keys %case ) {
		my ( $subject, $expected ) = @{ $case{$label} };

		my ( $parsed, $reason ) =
		    reader( 'parse', certificate( subject => $subject ) );
		is( $parsed, undef, "a subject with $label fails" ) or next;
		like( $reason, qr/\Athe subject: /,
			'and the reason names the name' );
		like( $reason, $expected, 'and it says why' );
	}
};

subtest 'parse names an attribute type outside the table' => sub {

	# The name table of the module holds no business category, so
	# the reader must answer that attribute under its dotted
	# object identifier. A reader that drops it would hide an
	# attribute of the subject.
	my $subject =
	    rdn( attribute( OID_CN, TAG_PRINTABLE_STRING, 'Fugu Test' ) )
	    . rdn(
		attribute(
			OID_BUSINESS_CATEGORY, TAG_UTF8_STRING,
			'Private Organization'
		)
	    );

	my ( $parsed, $reason ) =
	    reader( 'parse', certificate( subject => $subject ) );
	ok( defined $parsed, 'the certificate parses' ) or diag($reason);
	is_deeply(
		$parsed->{subject},
		{
			CN         => 'Fugu Test',
			'2.5.4.15' => 'Private Organization'
		},
		'the reader names the attribute by its dotted identifier'
	);
};

# --- the command part, with no command ------------------------------------

subtest 'the object answers cleanly for an absent command' => sub {

	# An absent openssl(1) is an install problem, and new must
	# never die for one. Each command method then answers undef,
	# and it reports the absent command through command_absent.
	my $x509 = Fugu::X509->new( command => "$WORK/no-such-openssl" );

	is( $x509->is_available,   0,     'is_available answers 0' );
	is( $x509->command_absent, 1,     'command_absent answers 1' );
	is( $x509->command,        undef, 'command stays undef' );
	like( $x509->error, qr/no executable openssl command/,
		'error names the reason' );

	my $dir  = tempdir( 'absent-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	my $file = write_file( "$dir/release.txt", "the release bytes\n" );
	my $key  = write_file( "$dir/key.pem",     "no certificate here\n" );

	is(
		$x509->generate(
			public  => "$dir/made.pem",
			secret  => "$dir/made.key",
			subject => $SUBJECT,
			days    => 30
		),
		undef,
		'generate answers undef'
	);
	is( $x509->command_absent, 1, 'and command_absent answers 1' );

	is(
		$x509->sign(
			public    => $key,
			secret    => $key,
			file      => $file,
			signature => "$dir/release.p7s"
		),
		undef,
		'sign answers undef'
	);
	is( $x509->command_absent, 1, 'and command_absent answers 1' );

	is(
		$x509->verify(
			keys      => [$key],
			file      => $file,
			signature => $key
		),
		undef,
		'verify answers undef'
	);
	is( $x509->command_absent, 1, 'and command_absent answers 1' );

	# The walk stops at the first key, because every later key
	# would fail the same way.
	like( $x509->error, qr/\Ano executable openssl command/,
		'and the walk reports that one reason alone' );

	ok( !-e "$dir/made.pem" && !-e "$dir/made.key",
		'no call wrote a half' );
};

subtest 'each command method dies for an absent argument' => sub {
	my $x509 = Fugu::X509->new;

	ok( !eval { $x509->generate( public => 'p', secret => 's' ); 1 },
		'generate dies for an absent subject' );
	like( $@, qr/subject/, 'the message names subject' );

	ok(
		!eval {
			$x509->generate( subject => $SUBJECT, days => 30 );
			1;
		},
		'generate dies for an absent public'
	);
	like( $@, qr/public/, 'the message names public' );

	ok(
		!eval {
			$x509->sign( secret => 's', file => 'f', signature => 'x' );
			1;
		},
		'sign dies for an absent public'
	);
	like( $@, qr/public/, 'the message names public' );

	ok( !eval { $x509->sign( public => 'p', secret => 's', file => 'f' ); 1 },
		'sign dies for an absent signature' );
	like( $@, qr/signature/, 'the message names signature' );

	ok( !eval { $x509->verify( file => 'f', signature => 's' ); 1 },
		'verify dies for an absent keys' );
	like( $@, qr/keys/, 'the message names keys' );

	ok(
		!eval {
			$x509->verify( keys => [], file => 'f', signature => 's' );
			1;
		},
		'verify dies for an empty keys'
	);
	like( $@, qr/non-empty/, 'the message names the empty list' );
};

subtest 'generate refuses a subject that names no subject' => sub {

	# The subject reaches openssl(1) as one argument. A NUL byte
	# ends that argument, and a line ending opens a second line,
	# so the certificate would carry a subject that the caller
	# never named. The refusal stands before the command runs.
	my $x509 = Fugu::X509->new;
	my $dir  = tempdir( 'subject-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );

	my @case = (
		[ 'an empty subject',  '' ],
		[ 'a newline',         "/CN=Fugu Test\n/CN=Other" ],
		[ 'a carriage return', "/CN=Fugu Test\r/CN=Other" ],
		[ 'a NUL byte',        "/CN=Fugu Test\0/CN=Other" ],
		[ 'a wide subject',    "/CN=Caf\x{263A}" ],
	);

	for my $case (@case) {
		my ( $name, $subject ) = @$case;
		is(
			$x509->generate(
				public  => "$dir/made.pem",
				secret  => "$dir/made.key",
				subject => $subject,
				days    => 30
			),
			undef,
			"$name fails"
		);
		like( $x509->error, qr/empty|line ending|above 255/,
			'and error names the fault' );
	}

	ok( !-e "$dir/made.pem", 'and no refused call wrote a half' );
};

subtest 'generate refuses a validity that is no number of days' => sub {
	my $x509 = Fugu::X509->new;
	my $dir  = tempdir( 'days-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );

	my @case = (
		[ 'a word',     'tomorrow' ],
		[ 'a fraction', '30.5' ],
		[ 'zero days',  0 ],
		[ 'a past day', -30 ],
	);

	for my $case (@case) {
		my ( $name, $days ) = @$case;
		is(
			$x509->generate(
				public  => "$dir/made.pem",
				secret  => "$dir/made.key",
				subject => $SUBJECT,
				days    => $days
			),
			undef,
			"$name fails"
		);
		like( $x509->error, qr/whole number|one day or more/,
			'and error names the fault' );
	}

	ok( !-e "$dir/made.pem", 'and no refused call wrote a half' );
};

subtest 'a command method refuses a path that is no plain file' => sub {

	# LIB-SIGNER-7 refuses an input path that is no plain file,
	# before the command runs. The refusal needs no openssl(1).
	my $x509 = Fugu::X509->new;
	my $dir  = tempdir( 'input-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	my $file = write_file( "$dir/release.txt", "the release bytes\n" );

	is(
		$x509->sign(
			public    => $file,
			secret    => "$dir/absent.key",
			file      => $file,
			signature => "$dir/release.p7s"
		),
		undef,
		'sign refuses an absent private key'
	);
	like( $x509->error, qr/\Qnot a plain file: $dir\/absent.key\E/,
		'and error names the path' );
	is( $x509->command_absent, 0, 'a refusal is no absent command' );

	is(
		$x509->verify(
			keys      => [$file],
			file      => $file,
			signature => "$dir/absent.p7s"
		),
		undef,
		'verify refuses an absent signature file'
	);
	like( $x509->error, qr/\Qnot a plain file: $dir\/absent.p7s\E/,
		'and error names the path' );
};

# --- the command part, over openssl(1) ------------------------------------

my ( $CERT, $KEY, $MADE, $LONG, $OTHER, $OTHER_KEY, $FILE, $SIGNATURE );

if ( defined $openssl ) {
	$MADE = time;
	( $CERT,  $KEY )       = make_certificate( 'cert',  30 );
	( $LONG,  undef )      = make_certificate( 'long',  10_000 );
	( $OTHER, $OTHER_KEY ) = make_certificate( 'other', 30 );

	$FILE      = write_file( "$WORK/release.txt", "the release bytes\n" );
	$SIGNATURE = "$WORK/release.p7s";

	my $x509 = Fugu::X509->new;
	$x509->sign(
		public    => $CERT,
		secret    => $KEY,
		file      => $FILE,
		signature => $SIGNATURE
	) or die 'Cannot sign the release: ' . $x509->error;
}

subtest 'generate writes the certificate and the private key' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	ok( -f $CERT, 'the certificate exists' );
	ok( -f $KEY,  'the private key exists' );

	like( slurp($CERT), qr/\A-----BEGIN CERTIFICATE-----/,
		'the certificate is a PEM certificate block' );
	like( slurp($KEY), qr/-----BEGIN PRIVATE KEY-----/,
		'the private key is a PEM private key block' );

	# LIB-SIGNER-4 makes a key with no passphrase. An encrypted
	# key names itself in the block type, and it would then need
	# a passphrase at each signature.
	unlike( slurp($KEY), qr/ENCRYPTED/,
		'and the private key carries no passphrase' );

	# The private key must hold no group mode and no other mode.
	is( sprintf( '%04o', ( stat $KEY )[2] & 07777 ),
		'0600', 'the private key is owner-only' );

	# The parent makes the private directory beside the private
	# key, and it removes the tree on every exit.
	is_deeply( [ glob "$WORK/.fugu-signer.*" ],
		[], 'and the private directory is gone' );

	# openssl(1) itself must read the pair, or the module writes a
	# form that no other tool takes.
	my $printed = openssl( 'x509', '-in', $CERT, '-noout', '-subject' );
	like( $printed, qr/CN\s*=\s*Fugu Test/,
		'openssl(1) reads the subject that the caller named' );

	# The parent refuses a path that exists, so one call never
	# overwrites a key.
	my $x509 = Fugu::X509->new;
	is(
		$x509->generate(
			public  => $CERT,
			secret  => $KEY,
			subject => $SUBJECT,
			days    => 30
		),
		undef,
		'a second generate over one path returns undef'
	);
	like( $x509->error, qr/\Qthe path exists: $CERT\E/,
		'error names the path that exists' );
	is( $x509->command_absent, 0, 'a refusal is no absent command' );
};

subtest 'generate reports a failure of the command' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $x509   = Fugu::X509->new;
	my $public = "$WORK/bad.pem";
	my $secret = "$WORK/bad.key";

	is(
		$x509->generate(
			public  => $public,
			secret  => $secret,
			subject => 'no solidus here',
			days    => 30
		),
		undef,
		'a subject that openssl(1) refuses fails'
	);
	like( $x509->error, qr/\Acannot generate \Q$public\E: /,
		'the reason names the act and the path' );

	# The generator writes a progress line of dots and a line of
	# dashes before its diagnostic, and neither names a fault.
	unlike( $x509->error, qr/: [-.+*]+\z/,
		'and the reason is no progress line' );

	is( $x509->command_absent, 0, 'and the failure is no install problem' );
	ok( !-e $public && !-e $secret, 'and no half stays behind' );
};

subtest 'decode_pem and fingerprint agree with openssl(1)' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $der = $X509->decode_pem( slurp($CERT) );
	ok( defined $der, 'the certificate of the generator decodes' );
	is( $der, openssl( 'x509', '-in', $CERT, '-outform', 'DER' ),
		'and the bytes are the DER form of openssl(1)' );

	# "sha256 Fingerprint=A0:9E:..." holds the digest of the tool.
	my $printed =
	    openssl( 'x509', '-in', $CERT, '-noout', '-fingerprint', '-sha256' );
	my ($want) = $printed =~ /Fingerprint=([0-9A-Fa-f:]+)/;
	$want =~ s/://g;

	is( $X509->fingerprint($der),
		uc $want, 'the fingerprint is the answer of openssl(1)' );
};

subtest 'parse reads the names and the validity' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $der = $X509->decode_pem( slurp($CERT) );
	my ( $parsed, $reason ) = reader( 'parse', $der );
	ok( defined $parsed, 'the certificate parses' ) or diag($reason);
	is( $reason, undef, 'and it reports no reason' );

	is_deeply( $parsed->{subject}, \%EXPECTED,
		'the subject holds each attribute that generate named' );
	is_deeply( $parsed->{issuer}, \%EXPECTED,
		'and a self-signed certificate names itself as the issuer' );

	# openssl(1) writes notBefore at the current second, and
	# notAfter that many days later.
	cmp_ok( abs( $parsed->{not_before} - $MADE ),
		'<=', 300, 'notBefore names the second of the generation' );
	is( $parsed->{not_after} - $parsed->{not_before},
		30 * 86_400, 'and notAfter stands 30 days after it' );
	cmp_ok( $parsed->{not_after}, '<', YEAR_2050,
		'a certificate of 30 days takes the UTCTime form' );
};

subtest 'parse reads a GeneralizedTime' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	# RFC 5280 holds a certificate that expires in 2050 or later
	# to the second time form, and that form writes four digits of
	# the year.
	my $der    = $X509->decode_pem( slurp($LONG) );
	my $parsed = $X509->parse($der);
	ok( defined $parsed, 'the certificate parses' );
	cmp_ok( $parsed->{not_after}, '>', YEAR_2050,
		'a certificate of 10000 days expires in 2050 or later' );
	is( $parsed->{not_after} - $parsed->{not_before},
		10_000 * 86_400, 'and notAfter stands 10000 days after it' );
};

subtest 'parse rejects a damaged certificate' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $der = $X509->decode_pem( slurp($CERT) );

	my ( $short, $short_reason ) =
	    reader( 'parse', substr $der, 0, length($der) - 1 );
	is( $short, undef, 'a truncated certificate fails' );
	like( $short_reason, qr/truncated/, 'and the reason says so' );

	my ( $long, $long_reason ) = reader( 'parse', $der . "\x00" );
	is( $long, undef, 'a certificate with one byte after it fails' );
	like( $long_reason, qr/bytes follow the certificate/,
		'and the reason says so' );

	my $flipped = $der;
	substr $flipped, 0, 1, "\x31";
	my ( $tag, $tag_reason ) = reader( 'parse', $flipped );
	is( $tag, undef, 'a certificate under the wrong tag fails' );
	like( $tag_reason, qr/tag 0x31, and not 0x30/,
		'and the reason names the tag' );
};

subtest 'sign writes a signature that verify takes' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $x509 = Fugu::X509->new;
	ok( $x509->is_available, 'the object resolved openssl(1)' );
	like( $x509->command, qr/openssl/, 'and command names it' );

	ok( -f $SIGNATURE, 'the signer wrote the signature file' );
	like( slurp($SIGNATURE), qr/\A-----BEGIN CMS-----\n/,
		'and it holds a PEM CMS block' );

	# The signature is detached: it holds the digest of the file
	# and no byte of it. The guard reads the decoded bytes,
	# because the base64 of a PEM text can never hold the plain
	# text of the file. An opaque signature carries the file, and
	# it still verifies with -content, so the PEM text proves
	# nothing.
	my $body = slurp($SIGNATURE) =~ s/^-----(BEGIN|END) CMS-----\n//gmr;
	my $bytes = decode_base64($body);
	ok( length $bytes, 'the signature decodes to DER bytes' );
	is( index( $bytes, slurp($FILE) ),
		-1, 'and the signature holds no byte of the file' );

	is(
		$x509->verify(
			keys      => [$CERT],
			file      => $FILE,
			signature => $SIGNATURE
		),
		$CERT,
		'verify answers the certificate that verified the signature'
	) or diag( $x509->error );
	is( $x509->error,          undef, 'error is undef after a success' );
	is( $x509->command_absent, 0,     'and command_absent answers 0' );

	# A rotation signs one manifest again, so a second sign over
	# one signature path replaces the file, per LIB-SIGNER-5.
	is(
		$x509->sign(
			public    => $CERT,
			secret    => $KEY,
			file      => $FILE,
			signature => $SIGNATURE
		),
		1,
		'a second sign over one path answers 1'
	) or diag( $x509->error );
	is(
		$x509->verify(
			keys      => [$CERT],
			file      => $FILE,
			signature => $SIGNATURE
		),
		$CERT,
		'and verify takes the signature that replaced it'
	) or diag( $x509->error );

	# openssl(1) itself must read the same signature, or the
	# module answers a form that no other tool takes.
	ok(
		eval {
			openssl(
				'cms',       '-verify',
				'-binary',   '-inform',
				'PEM',       '-in',
				$SIGNATURE,  '-content',
				$FILE,       '-certfile',
				$CERT,       '-nointern',
				'-noverify', '-out',
				'/dev/null'
			);
			1;
		},
		'and openssl(1) verifies the same signature'
	);
};

subtest 'verify walks the key set in trust order' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	# The walk pins one certificate in one run, and it answers the
	# one that verified. A caller therefore learns that a release
	# moved to the next certificate.
	my $x509 = Fugu::X509->new;

	is(
		$x509->verify(
			keys      => [ $OTHER, $CERT ],
			file      => $FILE,
			signature => $SIGNATURE
		),
		$CERT,
		'a later certificate of the set verifies the signature'
	) or diag( $x509->error );

	# The reason of the first key must not survive a call that
	# verified.
	is( $x509->error, undef, 'and error holds no reason of the first key' );
};

subtest 'verify pins the certificate that the caller names' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	# A CMS signature carries the certificate of its signer, so a
	# verifier that reads that copy accepts a signature of any
	# certificate. The verifier must read the one certificate of
	# the caller and no other.
	my $x509      = Fugu::X509->new;
	my $signature = "$WORK/other.p7s";

	$x509->sign(
		public    => $OTHER,
		secret    => $OTHER_KEY,
		file      => $FILE,
		signature => $signature
	) or diag( $x509->error );

	is(
		$x509->verify(
			keys      => [$OTHER],
			file      => $FILE,
			signature => $signature
		),
		$OTHER,
		'the signature verifies against its own certificate'
	);

	is(
		$x509->verify(
			keys      => [$CERT],
			file      => $FILE,
			signature => $signature
		),
		undef,
		'and it fails against another certificate'
	);
	like( $x509->error, qr/\Q$FILE: no key verified the signature\E/,
		'error names the file' );
	like( $x509->error, qr/\Q$CERT\E: [^\n]*signer certificate not found/,
		'and it names the certificate with its own reason' );
	is( $x509->command_absent, 0, 'and the failure is no install problem' );
};

subtest 'verify fails for a changed file' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $x509    = Fugu::X509->new;
	my $changed = write_file( "$WORK/changed.txt", "the other bytes\n" );

	is(
		$x509->verify(
			keys      => [$CERT],
			file      => $changed,
			signature => $SIGNATURE
		),
		undef,
		'a signature over other bytes fails'
	);
	like( $x509->error, qr/verification failure/,
		'and the reason names the failure' );

	my $junk = write_file( "$WORK/junk.p7s",
		"-----BEGIN CMS-----\nQUJD\n-----END CMS-----\n" );
	is(
		$x509->verify(
			keys      => [$CERT],
			file      => $FILE,
			signature => $junk
		),
		undef,
		'a signature that holds no CMS structure fails'
	);
	ok( length $x509->error, 'and the reason comes from openssl(1)' );
};

subtest 'sign reports a failure of the command' => sub {
	plan skip_all => 'openssl(1) not available' unless defined $openssl;

	my $x509 = Fugu::X509->new;
	my $junk = write_file( "$WORK/junk.pem", "no certificate here\n" );

	is(
		$x509->sign(
			public    => $junk,
			secret    => $KEY,
			file      => $FILE,
			signature => "$WORK/junk-sign.p7s"
		),
		undef,
		'a certificate that no PEM block holds fails'
	);
	like( $x509->error, qr/\Acannot sign \Q$FILE\E: /,
		'the reason names the act and the file' );
	is( $x509->command_absent, 0,
		'and the failure is no install problem' );

	# The parent checks secret and file, and the hook checks the
	# certificate of the key. openssl(1) must never see a path
	# that is no plain file.
	my $absent = "$WORK/no-such.pem";
	is(
		$x509->sign(
			public    => $absent,
			secret    => $KEY,
			file      => $FILE,
			signature => "$WORK/absent-sign.p7s"
		),
		undef,
		'a certificate that no file holds fails'
	);
	like( $x509->error, qr/\Qnot a plain file: $absent\E/,
		'and error names the path' );
};

done_testing();
