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

package Protocol::Imsg;
our $VERSION = '0.1.2';

use Errno qw(EBADMSG EMSGSIZE);

# Protocol::Imsg - the base-system imsg(3) frame, as bytes.
#
# The codec takes bytes and returns bytes. It performs no system call,
# it opens no file, and it names no socket. Fugu::Imsg owns the socket
# and uses this module for the frame.
#
# The header is native-endian, so the format never crosses a host. See
# the first paragraph of Protocol/Imsg.pod for that limit and the two
# others.
#
# The wire format is in spec/MDNS-Imsg.md in this repository.
# That document is a curated reference, not an installed manual.

# Header and size constants per spec/MDNS-Imsg.md §1-§2. The header
# has four native uint32 fields: type, len, peerid, pid. The len field
# counts the whole message, and MAX_IMSGSIZE bounds it. The
# HEADER_TEMPLATE pack template pins the field order and widths.
# Change them only against the spec.
use constant {
	HEADER_SIZE     => 16,
	HEADER_TEMPLATE => 'L4',    # type, len, peerid, pid; native order
	MAX_IMSGSIZE    => 16384,
};
use constant MAX_PAYLOAD => MAX_IMSGSIZE - HEADER_SIZE;

# The high bit of len marks fd-passing messages [MDNS-Imsg §2]. The
# protocols this module serves never set it. But a receiver must mask
# it off before it trusts the length.
use constant FD_MARK => 0x80000000;

# Protocol::Imsg->new:
#	Make a codec with an empty decode buffer.
sub new ($class)
{
	return bless {
		buffer => '',
		failed => 0,
	}, $class;
}

# $self->encode(%args):
#	type   => $n	message type (required)
#	data   => $bytes payload (default empty)
#	peerid => $n	caller-chosen correlation value (default 0)
#	pid    => $n	sender pid (default this process)
#	Return the framed bytes of one message. The method returns
#	undef, with $! set to EMSGSIZE, for an oversized payload. An
#	encoder must refuse a larger payload rather than truncate it
#	[MDNS-Imsg §2].
#
#	The peerid field is opaque to this module [MDNS-Imsg §1]. A
#	request and response protocol puts its correlation value there
#	and reads it back from next_message.
#
#	The pid default uses || and not //, because imsg substitutes
#	the sender's pid when the caller passes 0 [MDNS-Imsg §3]. A //
#	default would put a literal 0 on the wire, which native imsg
#	never produces.
sub encode ( $self, %args )
{
	my $type   = $args{type}   // die 'type parameter required';
	my $data   = $args{data}   // '';
	my $peerid = $args{peerid} // 0;
	my $pid    = $args{pid} || $$;

	if ( length($data) > MAX_PAYLOAD ) {
		$! = EMSGSIZE;
		return;
	}

	return _encode_header( $type, HEADER_SIZE + length($data), $peerid,
		$pid ) . $data;
}

# $self->append($bytes):
#	Add received bytes to the decode buffer. The method returns the
#	object.
sub append ( $self, $bytes )
{
	$self->{buffer} .= $bytes if defined $bytes;

	return $self;
}

# $self->next_message:
#	Pop one complete message off the buffer and return a hashref
#	with type, peerid, pid and data. The method returns undef when
#	more bytes are necessary.
#
#	An invalid length sets $! to EBADMSG and makes the failure
#	permanent: native imsg drops such a connection, and so must
#	every reader [MDNS-Imsg §2, §4].
sub next_message ($self)
{
	return if $self->{failed};
	return if length( $self->{buffer} ) < HEADER_SIZE;

	my ( $type, $len, $peerid, $pid ) = unpack( HEADER_TEMPLATE,
		substr( $self->{buffer}, 0, HEADER_SIZE ) );
	$len &= ~FD_MARK;

	if ( $len < HEADER_SIZE || $len > MAX_IMSGSIZE ) {
		$self->{failed} = 1;
		$! = EBADMSG;
		return;
	}
	return if length( $self->{buffer} ) < $len;

	my $data = substr( $self->{buffer}, HEADER_SIZE, $len - HEADER_SIZE );
	substr( $self->{buffer}, 0, $len ) = '';

	return {
		type   => $type,
		peerid => $peerid,
		pid    => $pid,
		data   => $data,
	};
}

# $self->is_failed:
#	Report the permanent framing failure. Nothing clears it but
#	reset.
sub is_failed ($self)
{
	return $self->{failed} ? 1 : 0;
}

# $self->reset:
#	Empty the buffer and clear the failure. The method returns the
#	object.
#
#	Fugu::Imsg::close needs it: without the reset, a closed
#	connection could still hand out a frame that arrived before the
#	close, because the transport extracts before it checks the dead
#	flag.
sub reset ($self)
{
	$self->{buffer} = '';
	$self->{failed} = 0;

	return $self;
}

# _encode_header($type, $len, $peerid, $pid):
#	Encode one header [MDNS-Imsg §1]. This internal seam lets the
#	tests assert the encoded bytes.
sub _encode_header ( $type, $len, $peerid, $pid )
{
	return pack( HEADER_TEMPLATE, $type, $len, $peerid, $pid );
}

1;
