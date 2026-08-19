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

use v5.36;

package Fugu::Random;
our $VERSION = '0.1.2';

use MIME::Base64 ();

# Fugu::Random - random bytes and random passwords for a daemon.
#
# Every method is a class method. The module keeps no state, never
# logs, and uses core Perl only. A programming error dies; there is no
# partial result and no quiet fallback, because a caller cannot recover
# from a secret with a known prefix.
#
# Protocol::HAP::Crypto reads /dev/urandom too. The duplication is
# deliberate: the protocol library stays self-contained across a future
# distribution boundary.

use constant {
	URANDOM_PATH    => '/dev/urandom',
	PASSWORD_LENGTH => 32,
};

# $class->random_bytes($length):
#	Return $length bytes from /dev/urandom.
#
#	The method dies when the device does not open, and dies on a
#	short read. Neither one has a recovery: a caller that continues
#	with fewer bytes than it asked for builds a secret with a known
#	prefix.
sub random_bytes ( $class, $length )
{
	die 'random_bytes needs a positive length'
	    unless defined $length && $length > 0;

	open my $fh, '<', URANDOM_PATH
	    or die 'Cannot open ' . URANDOM_PATH . ": $!";
	binmode $fh;

	my $bytes = '';
	while ( length($bytes) < $length ) {
		my $n = read $fh, my $chunk, $length - length($bytes);
		if ( !defined $n ) {
			close $fh;
			die 'Cannot read ' . URANDOM_PATH . ": $!";
		}
		if ( $n == 0 ) {
			close $fh;
			die 'Short read from '
			    . URANDOM_PATH
			    . ': got '
			    . length($bytes)
			    . ", expected $length";
		}
		$bytes .= $chunk;
	}
	close $fh;

	return $bytes;
}

# $class->random_password($length):
#	Return a random password of exactly $length characters. The
#	alphabet is URL-safe base64, so the password survives a shell,
#	a URL and a configuration file with no quoting.
sub random_password ( $class, $length = PASSWORD_LENGTH )
{
	die 'random_password needs a positive length'
	    unless defined $length && $length > 0;

	# Base64 turns three bytes into four characters. Ask for more
	# than the password needs, then trim.
	my $raw     = $class->random_bytes( int( $length * 3 / 4 ) + 3 );
	my $encoded = MIME::Base64::encode_base64url( $raw, '' );

	return substr( $encoded, 0, $length );
}

1;
