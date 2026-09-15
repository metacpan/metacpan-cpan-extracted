# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package Fugu::X509;
our $VERSION = '0.5.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();
use File::Spec  ();
use Fugu::Signer;
use MIME::Base64 qw(decode_base64);

our @ISA = ('Fugu::Signer');

# Fugu::X509 - read an X.509 certificate as bytes, and drive
# openssl(1) over a certificate.
#
# The module follows Fugu::Signer over openssl(1). The parent holds
# the constructor and the command resolution, the three verbs, the run
# through Fugu::Process, the key walk of a verification, and the
# failure convention. This module holds the byte reader, the DER walk,
# and the arguments of each openssl(1) command line.
#
# The byte reader decodes a PEM block, it computes the SHA-256
# fingerprint of the DER bytes, and it reads the subject, the issuer
# and the validity from the DER itself. It runs no command, so a
# fingerprint check and an expiry check run on a host where openssl(1)
# is absent. Each reader is a method of the object, and it reports
# through error.
#
# The command part makes a self-signed certificate, it makes a
# detached CMS signature over a file, and it verifies one against the
# one certificate that the caller names. The verifier checks no chain,
# so the caller vouches for that certificate by other means.
#
# The private key enters as a path and leaves as a file, so no key
# byte enters Perl and no key byte reaches a log.
#
# The module holds no issuer by name. A code signing certificate of
# Apple Developer ID is one use, and the module reads every issuer the
# same way. It reads no PKCS#12 file, and it reads no extension of the
# certificate.
#
# Every method that takes a certificate needs bytes. Each one rejects
# a string that holds a code point above 255, because Digest::SHA dies
# on such a string and a byte read takes the low byte of each
# character.

# The size bound of a PEM text, 1 MiB. A certificate holds a few
# kilobytes. A caller that names a disk image by mistake gets a
# clean failure, not a decode of 500 MB.
use constant MAX_PEM_SIZE => 1_048_576;

# The one PEM block type that the decoder takes. A key directory
# publishes what the decoder accepts, so a private key block and a
# second block are each a failure.
use constant PEM_TYPE => 'CERTIFICATE';

# The time bound of one openssl(1) call, in seconds. The default of
# the parent is 30. A command that a caller named can be the wrong
# program, and a signature over a file of a few hundred megabytes
# reads the whole file.
use constant OPENSSL_TIMEOUT => 300;

# The key of a generated certificate. An RSA key of 2048 bits makes a
# CMS signature under openssl(1) and under LibreSSL. A newer key type
# needs a newer command.
use constant KEY_TYPE => 'rsa:2048';

# The digest of a CMS signature. The signer names it, so an old
# default of the command never decides it.
use constant SIGNATURE_DIGEST => 'sha256';

# The DER tags of the walk, per ITU-T X.690. The version of a
# certificate sits behind an explicit context tag 0, and RFC 5280
# section 4.1 holds every other field to one of these.
use constant {
	TAG_INTEGER          => 0x02,
	TAG_OID              => 0x06,
	TAG_UTC_TIME         => 0x17,
	TAG_GENERALIZED_TIME => 0x18,
	TAG_SEQUENCE         => 0x30,
	TAG_SET              => 0x31,
	TAG_VERSION          => 0xA0,
};

# The largest number of length bytes that the reader takes. Four
# bytes hold 4 GiB, and MAX_PEM_SIZE bounds a certificate long
# before that.
use constant MAX_LENGTH_BYTES => 4;

# The attribute types of a distinguished name, from the object
# identifier to the short name of openssl(1). A caller reads the
# common name and the organizational unit by name, because the
# designated requirement of Apple pins the team identifier in the
# organizational unit. An attribute type that this table does not
# hold arrives under its dotted object identifier, so the reader
# drops no attribute.
my %ATTRIBUTE_NAME = (
	'2.5.4.3'              => 'CN',
	'2.5.4.6'              => 'C',
	'2.5.4.7'              => 'L',
	'2.5.4.8'              => 'ST',
	'2.5.4.10'             => 'O',
	'2.5.4.11'             => 'OU',
	'1.2.840.113549.1.9.1' => 'emailAddress',
);

# The string forms of an attribute value, from the DER tag to the
# name of the form. RFC 5280 section 4.1.2.4 holds a name to the
# DirectoryString forms, and it names IA5String for an email
# address. Another form is a failure, and the reason names the tag.
my %STRING_TAG = (
	0x0C => 'UTF8String',
	0x13 => 'PrintableString',
	0x16 => 'IA5String',
);

# The days of each month in a common year. _month_days adds the leap
# day of February.
my @MONTH_DAYS = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

# --- the command part -----------------------------------------------------

# Fugu::X509->new(%args):
#	Build a generator, a signer and a verifier over openssl(1). The
#	method resolves the command once, and it runs no process.
#
#	%args:
#		command => $command # Optional: a name or an absolute path
#		timeout => $seconds # Optional: the bound of one run
#
#	The method must not die for an absent command. It sets error
#	instead, and is_available then returns 0. An absent openssl(1)
#	is an install problem, and a caller reports it as one.
sub new ( $class, %args )
{
	$args{timeout} //= OPENSSL_TIMEOUT;

	return $class->SUPER::new(%args);
}

# $self->generate(%args):
#	Make one self-signed certificate and its private key. The
#	method returns 1, or undef with the reason in error.
#
#	%args:
#		public  => $path   # Required: the certificate
#		secret  => $path   # Required: the private key
#		subject => $text   # Required: the subject
#		days    => $number # Required: the validity in days
#
#	openssl(1) writes each half at its path, so no key byte enters
#	Perl. The parent writes the private key in a directory of its
#	own, and one rename then moves it into place. The parent also
#	refuses a path that exists, so one call never overwrites a key.
#
#	The subject takes the form of openssl(1), such as
#	/C=SE/O=Example/CN=Example Signer. A line ending or a NUL byte
#	would cut the argument, so the method refuses each of them
#	before the command runs.
#
#	The certificate is its own issuer, and it holds no chain. A
#	test of a signature needs one certificate, and no other
#	generator makes it.
sub generate ( $self, %args )
{
	my ( $subject, $days ) = @args{qw(subject days)};
	die "subject and days are necessary arguments\n"
	    unless defined $subject && defined $days;

	$self->_begin;

	return $self->_set_error('the subject is empty') unless length $subject;
	return $self->_set_error( 'the subject holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($subject);

	# The subject reaches the command as one argument. A NUL byte
	# ends that argument, and a line ending opens a second line of
	# a configuration form, so the certificate would carry a
	# subject that the caller never named.
	return $self->_set_error(
		'the subject holds a line ending or a NUL byte')
	    if $subject =~ /[\r\n\0]/;

	return $self->_set_error("the validity $days is not a whole number")
	    unless $days =~ /\A[0-9]+\z/;
	return $self->_set_error("the validity $days is not one day or more")
	    unless $days > 0;

	return $self->SUPER::generate(%args);
}

# $self->sign(%args):
#	Make a detached CMS signature over one file. The method returns
#	1, or undef with the reason in error.
#
#	%args:
#		public    => $path # Required: the certificate of the key
#		secret    => $path # Required: the PEM private key
#		file      => $path # Required: the file to sign
#		signature => $path # Required: the signature file
#
#	A PEM private key names no certificate, so the signer takes
#	public beside it, per LIB-SIGNER-5. openssl(1) reads the
#	private key from the path, and it writes the signature file
#	itself, so no key byte enters Perl. The caller converts a
#	PKCS#12 file with openssl pkcs12 before it names the two.
#
#	The signature is detached: it holds the digest of the file and
#	no byte of it. The verifier therefore needs the file again.
sub sign ( $self, %args )
{
	die "public is a necessary argument\n" unless defined $args{public};

	return $self->SUPER::sign(%args);
}

# --- the byte reader ------------------------------------------------------

# $self->decode_pem($text):
#	The DER bytes of a PEM certificate block, or undef with the
#	reason in error.
#
#	The method takes one CERTIFICATE block. It reads the two
#	delimiter lines and it decodes the base64 body. A PEM block
#	holds no checksum line, so the decoder holds the body to the
#	base64 alphabet itself: decode_base64 skips a character that
#	no alphabet holds, and a body with one bad character would
#	otherwise decode to a shorter certificate.
#
#	A private key block and a second block are each a failure,
#	because a key directory publishes what this method accepts.
sub decode_pem ( $self, $text )
{
	$self->_begin;

	return $self->_set_error('the PEM text is undef') unless defined $text;
	return $self->_set_error( 'the PEM text holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($text);

	if ( length($text) > MAX_PEM_SIZE ) {
		return $self->_set_error(
			sprintf 'the PEM text is larger than %d bytes',
			MAX_PEM_SIZE );
	}

	# PEM is text, so a producer can write either line ending. A
	# block that travelled through email holds CRLF. The
	# substitution gives a copy, so the caller keeps its own
	# string.
	$text =~ s/\r\n/\n/g;

	my @type = $text =~ /^-----BEGIN ([A-Z0-9 ]+)-----[ \t]*$/mg;
	return $self->_set_error( 'no BEGIN ' . PEM_TYPE . ' delimiter line' )
	    unless @type;

	for my $type (@type) {
		next if $type eq PEM_TYPE;
		return $self->_set_error( "the text holds a $type block, and "
			    . 'this method takes a '
			    . PEM_TYPE
			    . ' block' );
	}

	return $self->_set_error(
		sprintf 'the text holds %d %s blocks, and this '
		    . 'method takes one',
		scalar @type,
		PEM_TYPE
	) if @type > 1;

	my $begin  = '-----BEGIN ' . PEM_TYPE . '-----';
	my $end    = '-----END ' . PEM_TYPE . '-----';
	my ($body) = $text =~ /^\Q$begin\E[ \t]*\n(.*?)^\Q$end\E[ \t]*$/ms;
	return $self->_set_error( 'no END ' . PEM_TYPE . ' delimiter line' )
	    unless defined $body;

	# A mailer pads a line with a space or a tab, and the trim
	# takes the two ends of a line. \s must not stand here: under
	# the feature set of this file it also matches 0x0B, 0x0C,
	# 0x85 and 0xA0, and openssl(1) rejects a body that holds one
	# of them.
	my @line = grep { length } map { s/\A[ \t]+|[ \t]+\z//gr }
	    split /\n/, $body, -1;
	return $self->_set_error('no text between the delimiter lines')
	    unless @line;

	for my $line (@line) {
		return $self->_set_error("a body line is no base64 text: $line")
		    unless $line =~ m{\A[A-Za-z0-9+/]*={0,2}\z};
	}

	my $base64 = join '', @line;

	# The padding of base64 ends the data, so it sits at the end
	# of the body alone. A body with interior padding decodes to a
	# truncated certificate.
	return $self->_set_error(
		'the base64 padding sits before the end of the body')
	    if $base64 =~ /=(?!=*\z)/;

	return $self->_set_error('the base64 body is no whole number of groups')
	    if length($base64) % 4;

	my $der = decode_base64($base64);
	return $self->_set_error('the base64 body decodes to no byte')
	    unless length $der;

	return $der;
}

# $self->fingerprint($der):
#	The SHA-256 of the DER bytes, in upper-case hexadecimal with
#	no separator, or undef with the reason in error.
#
#	openssl(1) and the tools of other vendors print the hash of a
#	leaf certificate in that form, so a caller compares two
#	strings and not two encodings. The digest covers the bytes
#	that decode_pem answered, and it reads no field of them.
sub fingerprint ( $self, $der )
{
	$self->_begin;

	return $self->_set_error('the DER form is undef') unless defined $der;
	return $self->_set_error( 'the DER form holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($der);

	return uc Digest::SHA::sha256_hex($der);
}

# $self->parse($der):
#	The names and the validity of a certificate, or undef with the
#	reason in error.
#
#	The method returns a hash reference with subject, issuer,
#	not_before and not_after. Each name is a hash of attribute type
#	to value, and each time is seconds since the epoch.
#
#	The method reads the DER itself and it runs no command, so a
#	fingerprint check and an expiry check run on a host where
#	openssl(1) is absent.
#
#	The walk takes the fields of RFC 5280 section 4.1 in order,
#	and it stops after the subject. It reads no extension, and it
#	reads no public key.
sub parse ( $self, $der )
{
	$self->_begin;

	return $self->_set_error('the DER form is undef') unless defined $der;
	return $self->_set_error( 'the DER form holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($der);

	my ( $certificate, $reason ) =
	    _expect( $der, 0, TAG_SEQUENCE, 'the certificate' );
	return $self->_set_error($reason) unless defined $certificate;
	return $self->_set_error('bytes follow the certificate')
	    unless $certificate->{next} == length $der;

	my ( $tbs, $tbs_reason ) = _expect( $certificate->{content},
		0, TAG_SEQUENCE, 'the tbsCertificate' );
	return $self->_set_error($tbs_reason) unless defined $tbs;

	my $body = $tbs->{content};

	# The version sits behind an explicit context tag 0, and a
	# version 1 certificate holds none. Every other field of the
	# walk is necessary.
	my ( $version, $version_reason ) = _element( $body, 0 );
	return $self->_set_error("the tbsCertificate: $version_reason")
	    unless defined $version;

	my $offset = $version->{tag} == TAG_VERSION ? $version->{next} : 0;

	for my $field (
		[ TAG_INTEGER,  'the serial number' ],
		[ TAG_SEQUENCE, 'the signature algorithm' ] )
	{
		my ( $element, $skip_reason ) =
		    _expect( $body, $offset, @$field );
		return $self->_set_error($skip_reason) unless defined $element;
		$offset = $element->{next};
	}

	my ( $issuer, $issuer_reason ) =
	    _expect( $body, $offset, TAG_SEQUENCE, 'the issuer' );
	return $self->_set_error($issuer_reason) unless defined $issuer;

	my ( $validity, $validity_reason ) =
	    _expect( $body, $issuer->{next}, TAG_SEQUENCE, 'the validity' );
	return $self->_set_error($validity_reason) unless defined $validity;

	my ( $subject, $subject_reason ) =
	    _expect( $body, $validity->{next}, TAG_SEQUENCE, 'the subject' );
	return $self->_set_error($subject_reason) unless defined $subject;

	my %parsed;
	for my $pair ( [ issuer => $issuer ], [ subject => $subject ] ) {
		my ( $name, $name_reason ) =
		    _name( $pair->[1]{content}, "the $pair->[0]" );
		return $self->_set_error($name_reason) unless defined $name;
		$parsed{ $pair->[0] } = $name;
	}

	my $at = 0;
	for my $pair ( [ not_before => 'notBefore' ],
		[ not_after => 'notAfter' ] )
	{
		my ( $element, $element_reason ) =
		    _element( $validity->{content}, $at );
		return $self->_set_error("the validity: $element_reason")
		    unless defined $element;

		my ( $epoch, $time_reason ) =
		    _time( $element, "the $pair->[1]" );
		return $self->_set_error($time_reason) unless defined $epoch;

		$parsed{ $pair->[0] } = $epoch;
		$at = $element->{next};
	}

	return \%parsed;
}

# --- the hooks of the parent class ----------------------------------------

# $self->_command_label:
#	The name of the command in a diagnostic.
sub _command_label ($)
{
	return 'openssl';
}

# $self->_command_defaults:
#	The search list of the command. Every host that holds the
#	command holds it under the plain name.
sub _command_defaults ($)
{
	return ('openssl');
}

# $self->_generate(%args):
#	Run the generator of openssl(1) over the subject and the two
#	paths. The parent holds secret to a private directory, and it
#	moves that file into place.
#
#	-nodes writes a private key with no passphrase. LibreSSL takes
#	that name, and openssl(1) takes it beside the newer -noenc.
sub _generate ( $self, %args )
{
	my ( $public, $secret, $subject, $days ) =
	    @args{qw(public secret subject days)};

	$self->_openssl( [
			'req',    '-x509',   '-newkey', KEY_TYPE,
			'-nodes', '-days',   $days,     '-subj',
			$subject, '-keyout', $secret,   '-out',
			$public,
		],
		"cannot generate $public"
	) or return;

	return 1;
}

# $self->_sign(%args):
#	Run the signer of openssl(1) over the certificate, the private
#	key and the file. The command writes the signature file itself,
#	and a second run over one path replaces it.
#
#	The parent checks secret and file, so this hook checks the
#	certificate of the key alone.
sub _sign ( $self, %args )
{
	my ( $public, $secret, $file, $signature ) =
	    @args{qw(public secret file signature)};

	$self->_check_input($public) or return;

	$self->_openssl( [
			'cms',            '-sign',
			'-binary',        '-md',
			SIGNATURE_DIGEST, '-signer',
			$public,          '-inkey',
			$secret,          '-in',
			$file,            '-outform',
			'PEM',            '-out',
			$signature,
		],
		"cannot sign $file"
	) or return;

	return 1;
}

# $self->_verify($key, %args):
#	Verify one file against one certificate. The hook answers undef
#	when the certificate verified, and the reason that it did not.
#
#	A CMS signature carries the certificate of its signer, and
#	-nointern holds the command away from it, so a signature of
#	another certificate fails. -noverify then checks no chain and
#	no revocation: the caller vouches for the certificate by other
#	means, such as the fingerprint of a key directory.
#
#	The command writes the content of the signature to the null
#	device, because the caller holds the file already. A file of
#	500 MB therefore never enters memory.
sub _verify ( $self, $key, %args )
{
	$self->_command or return $self->error;

	$self->_openssl( [
			'cms',            '-verify',
			'-binary',        '-inform',
			'PEM',            '-in',
			$args{signature}, '-content',
			$args{file},      '-certfile',
			$key,             '-nointern',
			'-noverify',      '-out',
			File::Spec->devnull,
		] ) or return $self->error;

	return;
}

# $self->_reason($result):
#	The reason of an openssl(1) run that reached the child and
#	failed: the reason of the first error record, the first line of
#	the diagnostic, or the exit code. The parent holds the timeout.
#
#	openssl(1) writes one error record in each line of a stack,
#	and a colon separates the fields: the process, the word error,
#	the code, the library, the function, the reason, the file and
#	the line. The first record names the fault, and each later one
#	names what the fault broke. A wrong certificate therefore
#	gives "signer certificate not found", and a changed file gives
#	"verification failure".
#
#	The generator writes a progress line of dots and a line of
#	dashes before its diagnostic. Such a line holds no letter, and
#	it names no fault, so the reader steps over it.
sub _reason ( $, $result )
{
	my $first = '';
	for my $line ( split /\n/, $result->{stderr} // '' ) {
		next unless $line =~ /[A-Za-z]/;

		my @field = split /:/, $line, -1;
		return $field[5]
		    if @field >= 7
		    && $field[1] eq 'error'
		    && length $field[5];

		$first = $line unless length $first;
	}

	return length $first ? $first : "exit code $result->{exit_code}";
}

# --- the parts of this module alone ---------------------------------------

# $self->_openssl($args, $what):
#	Run one openssl(1) command, and answer the result of the run.
#	The method returns undef with the reason in error when the run
#	fails.
#
#	Each run takes the environment of the module. With no $what the
#	reason stands alone, because the key walk of the parent writes
#	a prefix of its own.
sub _openssl ( $self, $args, $what = undef )
{
	return $self->_run( $args, $what, env => _env() );
}

# _env():
#	The environment of one openssl(1) run. The child takes this
#	set and nothing else, so no variable of the caller reaches the
#	command. OPENSSL_CONF of the caller names a configuration file,
#	and no command of this module needs one. LC_ALL holds the
#	diagnostics in English, because _reason reads them.
sub _env ()
{
	return {
		PATH   => $ENV{PATH} // '',
		LC_ALL => 'C',
	};
}

# --- the DER reader -------------------------------------------------------

# _element($der, $offset):
#	One DER element at the offset, or undef with the reason as the
#	second value. The element holds the tag, the content and the
#	offset of the next element.
#
#	The reader takes the definite length forms alone. DER writes
#	no indefinite length, and a certificate holds no multi-byte
#	tag, so each of those is a failure.
sub _element ( $der, $offset )
{
	my $total = length $der;
	return ( undef, 'an element holds no tag and no length' )
	    unless $offset + 2 <= $total;

	my $tag = ord substr $der, $offset, 1;
	return ( undef, sprintf 'tag 0x%02X is a multi-byte tag', $tag )
	    if ( $tag & 0x1F ) == 0x1F;

	my $first = ord substr $der, $offset + 1, 1;
	my ( $length, $start );

	if ( $first < 0x80 ) {
		( $length, $start ) = ( $first, $offset + 2 );
	}
	else {
		my $count = $first & 0x7F;
		return ( undef, 'an indefinite length holds no whole element' )
		    unless $count;
		return ( undef,
			"a length of $count bytes is above the bound of "
			    . MAX_LENGTH_BYTES )
		    if $count > MAX_LENGTH_BYTES;
		return ( undef, 'the length bytes are truncated' )
		    unless $offset + 2 + $count <= $total;

		$length = 0;
		for my $index ( 0 .. $count - 1 ) {
			$length = ( $length << 8 ) +
			    ord( substr $der, $offset + 2 + $index, 1 );
		}
		$start = $offset + 2 + $count;
	}

	return ( undef, 'the element content is truncated' )
	    unless $start + $length <= $total;

	return ( {
			tag     => $tag,
			content => substr( $der, $start, $length ),
			next    => $start + $length,
		},
		undef
	);
}

# _expect($der, $offset, $tag, $what):
#	One DER element of the tag at the offset, or undef with the
#	reason as the second value. $what names the field, so the
#	reason of a walk names the field that failed.
sub _expect ( $der, $offset, $tag, $what )
{
	my ( $element, $reason ) = _element( $der, $offset );
	return ( undef, "$what: $reason" ) unless defined $element;

	return ( undef, sprintf '%s: tag 0x%02X, and not 0x%02X',
		$what, $element->{tag}, $tag )
	    unless $element->{tag} == $tag;

	return ( $element, undef );
}

# _name($bytes, $what):
#	A distinguished name as a hash reference of attribute type to
#	value, or undef with the reason as the second value.
#
#	A name holds a sequence of sets, and each set holds one
#	attribute or more. Two attributes of one type are a failure: a
#	hash holds one value for each type, and a caller that pins a
#	team identifier must never read one of two values.
sub _name ( $bytes, $what )
{
	my %name;
	my $offset = 0;

	while ( $offset < length $bytes ) {
		my ( $set, $set_reason ) = _expect( $bytes, $offset, TAG_SET,
			"$what: a relative distinguished name" );
		return ( undef, $set_reason ) unless defined $set;
		$offset = $set->{next};

		my $inner = 0;
		while ( $inner < length $set->{content} ) {
			my ( $pair, $pair_reason ) =
			    _expect( $set->{content}, $inner, TAG_SEQUENCE,
				"$what: an attribute" );
			return ( undef, $pair_reason ) unless defined $pair;
			$inner = $pair->{next};

			my ( $type, $value, $reason ) =
			    _attribute( $pair->{content}, $what );
			return ( undef, $reason ) unless defined $type;

			return ( undef, "$what: two attributes of type $type" )
			    if exists $name{$type};

			$name{$type} = $value;
		}
	}

	return ( \%name, undef );
}

# _attribute($bytes, $what):
#	The type and the value of one attribute, or undef with the
#	reason as the third value.
#
#	The value arrives as bytes. A UTF8String holds UTF-8, so a
#	caller that needs characters decodes them.
sub _attribute ( $bytes, $what )
{
	my ( $type, $type_reason ) =
	    _expect( $bytes, 0, TAG_OID, "$what: an attribute type" );
	return ( undef, undef, $type_reason ) unless defined $type;

	my ( $value, $value_reason ) = _element( $bytes, $type->{next} );
	return ( undef, undef, "$what: an attribute value: $value_reason" )
	    unless defined $value;

	return ( undef, undef, "$what: bytes follow an attribute value" )
	    unless $value->{next} == length $bytes;

	return (
		undef,
		undef,
		sprintf '%s: an attribute value is tag 0x%02X, and this '
		    . 'reader takes %s',
		$what,
		$value->{tag},
		join ', ',
		sort values %STRING_TAG
	) unless $STRING_TAG{ $value->{tag} };

	my $oid = _oid( $type->{content} );
	return ( undef, undef,
		"$what: an attribute type is no object " . 'identifier' )
	    unless defined $oid;

	return ( $ATTRIBUTE_NAME{$oid} // $oid, $value->{content}, undef );
}

# _oid($bytes):
#	The dotted form of an object identifier, or undef.
#
#	The first byte holds the first two arcs, and each later arc
#	takes seven bits of each byte. The high bit of a byte carries
#	the arc into the next one, so a high bit in the last byte
#	names an arc that the bytes do not hold.
sub _oid ($bytes)
{
	return unless length $bytes;

	my $first = ord substr $bytes, 0, 1;
	my @arc   = ( int( $first / 40 ), $first % 40 );

	my ( $value, $partial ) = ( 0, 0 );
	for my $byte ( unpack 'C*', substr $bytes, 1 ) {
		$value   = ( $value << 7 ) + ( $byte & 0x7F );
		$partial = 1;
		next if $byte & 0x80;
		push @arc, $value;
		( $value, $partial ) = ( 0, 0 );
	}

	return if $partial;

	return join '.', @arc;
}

# _time($element, $what):
#	One time of the validity, as seconds since the epoch, or undef
#	with the reason as the second value.
#
#	RFC 5280 section 4.1.2.5 holds each time to one of two forms.
#	A UTCTime writes YYMMDDHHMMSSZ, and a year of 50 or above
#	names the last century. A GeneralizedTime writes
#	YYYYMMDDHHMMSSZ, and every certificate that expires in 2050 or
#	later takes it. Both forms are UTC, and both hold the seconds.
#
#	The method reads each field before it computes, so the 31st of
#	February is a failure and never a date in March.
sub _time ( $element, $what )
{
	my $text = $element->{content};
	my ( $year, $rest );

	if ( $element->{tag} == TAG_UTC_TIME ) {
		return ( undef, "$what: a UTCTime holds YYMMDDHHMMSSZ" )
		    unless $text =~ /\A([0-9]{2})([0-9]{10})Z\z/;
		( $year, $rest ) = ( $1, $2 );
		$year += $year >= 50 ? 1900 : 2000;
	}
	elsif ( $element->{tag} == TAG_GENERALIZED_TIME ) {
		return ( undef,
			"$what: a GeneralizedTime holds YYYYMMDDHHMMSSZ" )
		    unless $text =~ /\A([0-9]{4})([0-9]{10})Z\z/;
		( $year, $rest ) = ( $1, $2 );
	}
	else {
		return ( undef, sprintf '%s: tag 0x%02X names no time',
			$what, $element->{tag} );
	}

	my ( $month, $day, $hour, $minute, $second ) =
	    map { 0 + $_ } unpack 'A2A2A2A2A2', $rest;

	return ( undef, "$what: month $month is no month" )
	    if $month < 1 || $month > 12;
	return ( undef, "$what: day $day is no day of month $month" )
	    if $day < 1 || $day > _month_days( $year, $month );
	return ( undef, "$what: $hour:$minute:$second is no time of day" )
	    if $hour > 23 || $minute > 59 || $second > 59;

	return ( _epoch( $year, $month, $day, $hour, $minute, $second ),
		undef );
}

# _month_days($year, $month):
#	The days of the month. A year that 4 divides is a leap year,
#	and a year that 100 divides is not, and a year that 400
#	divides is one again.
sub _month_days ( $year, $month )
{
	return $MONTH_DAYS[ $month - 1 ] unless $month == 2;

	my $leap = $year % 4 == 0 && ( $year % 100 != 0 || $year % 400 == 0 );

	return $leap ? 29 : 28;
}

# _epoch($year, $month, $day, $hour, $minute, $second):
#	The seconds since the epoch of a UTC date.
#
#	The sub counts the days from the civil date itself, over the
#	400-year cycle of the calendar. Time::Local would croak on a
#	date above the range of the integers of the build, and a
#	certificate comes from outside, so a die is no answer here.
sub _epoch ( $year, $month, $day, $hour, $minute, $second )
{
	# The year starts in March, so the leap day falls at the end
	# of it and every other month keeps its place.
	my $shifted = $year - ( $month <= 2 ? 1 : 0 );
	my $era     = int( $shifted / 400 );
	my $of_era  = $shifted - $era * 400;
	my $of_year =
	    int( ( 153 * ( $month + ( $month > 2 ? -3 : 9 ) ) + 2 ) / 5 ) +
	    $day - 1;
	my $day_of_era =
	    $of_era * 365 +
	    int( $of_era / 4 ) -
	    int( $of_era / 100 ) +
	    $of_year;

	# 719468 days separate the start of the era from the epoch.
	my $days = $era * 146_097 + $day_of_era - 719_468;

	return ( ( $days * 24 + $hour ) * 60 + $minute ) * 60 + $second;
}

1;
