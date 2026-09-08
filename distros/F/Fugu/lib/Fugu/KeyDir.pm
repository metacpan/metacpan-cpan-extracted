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

package Fugu::KeyDir;
our $VERSION = '0.3.0';

# Fugu::KeyDir - the names, the order and the generated text of a
# published key directory.
#
# An organization publishes its public keys under one prefix. This
# module holds the generic parts of that directory: the file name
# pattern, the type of a key, and the status vocabulary. It also
# holds the order of a key set, and the text of the Apache KEYS
# file, of the human index, and of security.txt.
#
# The module holds no policy. The organization word, each purpose,
# the contact and each date are arguments. A site build supplies
# them, so one tested implementation serves every FuguBSD site.
#
# The module runs no command. It needs neither gpg(1) nor signify(1),
# and it renders no HTML: the site owns the template. Every
# recoverable failure returns undef, and error holds the reason.

# The status vocabulary. A purpose holds exactly one current key, and
# at most one next key. A retired key stays published, so a release
# that it signed still verifies.
use constant STATUSES => qw(current next retired);

# The publication order of the statuses. A reader wants the key in
# force first, so current leads and retired trails.
my %STATUS_RANK = do {
	my $rank = 0;
	map { $_ => $rank++ } STATUSES;
};

# The digit bound of a serial. A serial counts the rotations of one
# purpose, so nine digits hold every key set that can ever exist.
#
# The bound also keeps every serial inside the exact integer range of
# each Perl build. A long run of digits becomes a float, and the
# threshold is the value and not the digit count: this build holds
# 18446744073709551615 exactly and turns the next integer into a
# float. parse_name stores the serial as a number, so a float would
# reach next_serial and then name_for, which rejects it. The
# rotation would stall with a reason that names neither the file nor
# the fault. Nine digits sit far below the threshold of every build.
use constant MAX_SERIAL_DIGITS => 9;

# The extension of a key file selects its type. OpenBSD names a
# signify key .pub, and the armored OpenPGP convention is .asc.
my %TYPE_OF_EXTENSION = (
	pub => 'signify',
	asc => 'openpgp',
);

my %EXTENSION_OF_TYPE = reverse %TYPE_OF_EXTENSION;

# Fugu::KeyDir->new(%args):
#	Build a key directory.
#
#	%args:
#		org => $word  # Required: the organization word
#
#	The organization word is the first field of every key name,
#	and parse_name holds a name to it. The method dies without
#	the word, and for a word that the name pattern cannot hold.
#	Each one is a programming error: a site build reads the word
#	from its own description block.
sub new ( $class, %args )
{
	my $org = $args{org};
	die "org is a necessary argument\n" unless defined $org;
	die "org must hold lower-case letters and digits only: $org\n"
	    unless $org =~ /\A[a-z][a-z0-9]*\z/;

	return bless { org => $org, error => undef }, $class;
}

# $self->org:
#	The organization word of the directory.
sub org ($self)
{
	return $self->{org};
}

# $self->error:
#	The reason of the most recent failure, or undef after a
#	success.
sub error ($self)
{
	return $self->{error};
}

# $self->parse_name($filename):
#	The parts of a key file name, as a hash reference with stem,
#	org, serial, purpose and type. The method returns undef on
#	every failure, and error holds the reason.
#
#	The pattern is <org>-<serial>-<purpose>.<ext>, for example
#	fugubsd-1-release.pub. The serial is an integer with no
#	padding, above zero, so a reader sorts it as a number. The
#	purpose names what the key signs, and a new purpose starts at
#	serial 1. A compromise of one purpose therefore leaves the
#	others in force.
sub parse_name ( $self, $filename )
{
	$self->{error} = undef;

	unless ( defined $filename && length $filename ) {
		return $self->_fail('the key file name is empty');
	}

	# A name is a file name and never a path. A caller that passes
	# a path would publish a key outside the directory.
	if ( $filename =~ m{/} ) {
		return $self->_fail("the key name holds a solidus: $filename");
	}

	# The extension must be lower case, and the pattern says so.
	# A separate match on any case tells an upper-case extension
	# from an absent one, because the two faults need two reasons.
	my ( $stem, $extension ) = $filename =~ /\A(.+)\.([a-z0-9]+)\z/;
	unless ( defined $stem ) {
		my ($upper) = $filename =~ /\A.+\.([A-Za-z0-9]+)\z/;
		if ( defined $upper ) {
			return $self->_fail( "the key extension must be "
				    . "lower case in $filename: $upper" );
		}
		return $self->_fail(
			"the key name holds no extension: " . $filename );
	}

	my $type = $TYPE_OF_EXTENSION{$extension};
	unless ( defined $type ) {
		return $self->_fail(
			"unknown key extension in $filename: $extension");
	}

	my ( $org, $serial, $purpose ) =
	    $stem =~ /\A([a-z][a-z0-9]*)-([0-9]+)-([a-z0-9-]+)\z/;
	unless ( defined $org ) {
		return $self->_fail( "the key name does not match "
			    . "<org>-<serial>-<purpose>.<ext>: $filename" );
	}

	unless ( $org eq $self->{org} ) {
		return $self->_fail( "the key name names the organization "
			    . "$org, and this directory is $self->{org}: $filename"
		);
	}

	# A serial counts the rotations of one purpose, so the bound is
	# far above any real key set. It also stops a run of digits
	# that Perl cannot hold exactly. Such a serial becomes a
	# float, and name_for then rejects the float and stalls the
	# rotation.
	if ( length($serial) > MAX_SERIAL_DIGITS ) {
		return $self->_fail( "the serial of $filename holds "
			    . length($serial)
			    . ' digits, and the bound is '
			    . MAX_SERIAL_DIGITS );
	}

	# The serial starts at 1 for each purpose, so zero names no
	# key. The test comes before the padding test, because 0 is
	# not a padded 1: the two faults need two reasons.
	if ( $serial eq '0' ) {
		return $self->_fail("the serial is zero in $filename");
	}

	# A padded serial sorts as text and not as a number, so two
	# names could then name one key.
	if ( $serial =~ /\A0/ ) {
		return $self->_fail(
			"the serial is padded in $filename: " . $serial );
	}

	return {
		stem    => $stem,
		org     => $org,
		serial  => 0 + $serial,
		purpose => $purpose,
		type    => $type,
	};
}

# $self->name_for(%args):
#	The file name of a key.
#
#	%args:
#		serial  => $n     # Required: above zero
#		purpose => $word  # Required
#		type    => $type  # Required: signify or openpgp
#
#	The method is the inverse of parse_name, so a caller never
#	builds a name by hand. It returns undef on every failure, and
#	error holds the reason.
sub name_for ( $self, %args )
{
	$self->{error} = undef;

	my ( $serial, $purpose, $type ) = @args{qw(serial purpose type)};

	unless ( defined $serial && $serial =~ /\A[1-9][0-9]*\z/ ) {
		return $self->_fail(
			'the serial must be an integer above zero: '
			    . ( $serial // '(undef)' ) );
	}

	# The same bound as parse_name, so the two stay inverses. A
	# name that this method built and parse_name rejected would
	# break every caller that writes a file and reads it back.
	if ( length($serial) > MAX_SERIAL_DIGITS ) {
		return $self->_fail( 'the serial holds '
			    . length($serial)
			    . ' digits, and the bound is '
			    . MAX_SERIAL_DIGITS );
	}

	unless ( defined $purpose && $purpose =~ /\A[a-z0-9-]+\z/ ) {
		return $self->_fail(
			'the purpose must hold lower-case letters, digits '
			    . 'and hyphens: '
			    . ( $purpose // '(undef)' ) );
	}

	my $extension = defined $type ? $EXTENSION_OF_TYPE{$type} : undef;
	unless ( defined $extension ) {
		return $self->_fail(
			'unknown key type: ' . ( $type // '(undef)' ) );
	}

	return "$self->{org}-$serial-$purpose.$extension";
}

# $self->next_serial($names, $purpose):
#	The serial that a rotation of the purpose must take: one above
#	the highest serial of that purpose. The answer is 1 when no
#	key of the purpose exists, so a new purpose starts at 1.
#
#	$names is an array reference of key file names. A name that
#	parse_name rejects is a failure, because a directory with an
#	unreadable name has no highest serial.
sub next_serial ( $self, $names, $purpose )
{
	$self->{error} = undef;

	unless ( ref $names eq 'ARRAY' ) {
		die "names must be an array reference\n";
	}

	unless ( defined $purpose && length $purpose ) {
		return $self->_fail('the purpose is empty');
	}

	my $highest = 0;
	for my $name (@$names) {
		my $parts = $self->parse_name($name) or return;
		next unless $parts->{purpose} eq $purpose;
		$highest = $parts->{serial} if $parts->{serial} > $highest;
	}

	my $next = $highest + 1;

	# The answer must pass name_for, or the caller stalls one step
	# later with a reason that names neither the purpose nor the
	# bound. The parser holds a name to the same bound, so this
	# method must not hand out a serial past it.
	if ( length($next) > MAX_SERIAL_DIGITS ) {
		return $self->_fail( "the purpose $purpose is at the "
			    . 'highest serial that the digit bound allows, '
			    . 'which is '
			    . ( '9' x MAX_SERIAL_DIGITS ) );
	}

	return $next;
}

# $self->order($keys):
#	The keys in publication order, as a new array reference.
#
#	A key is a hash reference that holds a name and a status. The
#	method parses the name, so the serial and the purpose need no
#	second source of truth. It returns undef on every failure, and
#	error holds the reason.
#
#	The order is current, then next, then retired. Inside one
#	status the serial descends, so the newest key of that status
#	leads. The purpose then breaks a tie, and the name breaks the
#	last one. The order is therefore total, and two runs write one
#	byte sequence.
sub order ( $self, $keys )
{
	$self->{error} = undef;

	my $parsed = $self->_parse_set($keys) or return;

	my @sorted = sort {
		$STATUS_RANK{ $a->{status} } <=> $STATUS_RANK{ $b->{status} }
		    || $b->{serial}          <=> $a->{serial}
		    || $a->{purpose}         cmp $b->{purpose}
		    || $a->{name}            cmp $b->{name}
	} @$parsed;

	return \@sorted;
}

# $self->check_statuses($keys):
#	Hold a key set to the status rule: each purpose must hold
#	exactly one current key, and at most one next key.
#
#	The method returns 1 on a pass. It returns undef on a failure,
#	and error names the purpose and the count. A purpose with two
#	current keys is the dangerous case: a reader cannot tell which
#	key signs a release today.
sub check_statuses ( $self, $keys )
{
	$self->{error} = undef;

	my $parsed = $self->_parse_set($keys) or return;

	my %count;
	for my $key (@$parsed) {
		$count{ $key->{purpose} }{ $key->{status} }++;
	}

	for my $purpose ( sort keys %count ) {
		my $current = $count{$purpose}{current} // 0;
		my $next    = $count{$purpose}{next}    // 0;

		if ( $current != 1 ) {
			return $self->_fail( "the purpose $purpose holds "
				    . "$current current keys, and it must hold 1"
			);
		}

		if ( $next > 1 ) {
			return $self->_fail( "the purpose $purpose holds "
				    . "$next next keys, and it must hold at most 1"
			);
		}
	}

	return 1;
}

# $self->keys_file($keys):
#	The text of the Apache KEYS file, or undef with the reason in
#	error.
#
#	The file holds each OpenPGP key of the set, in publication
#	order, with a comment block in front of each armored body.
#	gpg --import reads the file, and it skips a comment block.
#
#	The method skips a signify key: gpg(1) cannot read one, and a
#	signify key file already publishes at its own URL. A key of
#	type openpgp must hold an armor field, because the file holds
#	the armored body itself.
sub keys_file ( $self, $keys )
{
	$self->{error} = undef;

	my $ordered = $self->order($keys) or return;

	my $text = '';
	for my $key (@$ordered) {
		next unless $key->{type} eq 'openpgp';

		my $armor = $key->{armor};
		unless ( defined $armor && length $armor ) {
			return $self->_fail( "the OpenPGP key $key->{name} "
				    . 'holds no armor field' );
		}

		# One line holds one field, so a value with a newline
		# would forge a second field. The comment block sits in
		# front of an armored body. Such a value can therefore
		# forge a whole second block, and gpg --import reads it.
		# The stem, the purpose, the serial and the status each
		# come from parse_name or the vocabulary, so only the
		# free fields need the guard.
		for my $field (qw(fingerprint since until)) {
			my $value = $key->{$field};
			next unless defined $value;
			next unless $value =~ /[\r\n]/;
			return $self->_fail( "the $field of $key->{name} "
				    . 'holds a newline' );
		}

		# The armor field carries the whole payload, so a
		# newline in it is normal. One key holds one block,
		# though: a field with two blocks would publish a
		# second key under one name, and gpg --import would
		# read both. Fugu::OpenPGP reads the first block of a
		# text, so the index row would name the first key only.
		my $begins = () = $armor =~ /^-----BEGIN PGP /mg;
		my $ends   = () = $armor =~ /^-----END PGP /mg;
		unless ( $begins == 1 && $ends == 1 ) {
			return $self->_fail( "the armor of $key->{name} "
				    . "holds $begins BEGIN and $ends END "
				    . 'lines, and one key holds one block' );
		}

		# The block must be a public key. Nothing else in this
		# module reads the armored bytes, and the fingerprint
		# field is optional, so a private key block would reach
		# the published file with no other guard in its way.
		unless ( $armor =~ /^-----BEGIN PGP PUBLIC KEY BLOCK-----/m ) {
			my ($type) =
			    $armor =~ /^-----BEGIN PGP ([A-Z0-9 ]+)-----/m;
			return $self->_fail( "the armor of $key->{name} "
				    . 'holds a '
				    . ( $type // 'nameless' )
				    . ' block, and a key directory publishes '
				    . 'a PUBLIC KEY BLOCK' );
		}

		# Nothing may sit outside the block, at either end. Text
		# after the end line would stand in front of the next
		# comment block of the file. Text before the begin line
		# would stand in front of this key's own body, where a
		# reader takes it for part of the comment block. A guard
		# on the tail alone leaves the second forgery open.
		# Each class names the ASCII whitespace, and never \s.
		# Under the feature set of this file \s also matches
		# 0x85 and 0xA0, so a field that starts or ends with
		# one of those bytes would pass and write the byte into
		# the published file.
		unless (
			$armor =~ /\A[ \t\r\n]*-----BEGIN PGP [A-Z0-9 ]+-----/ )
		{
			return $self->_fail( "the armor of $key->{name} "
				    . 'holds text before its begin line' );
		}

		unless ( $armor =~ /-----END PGP [A-Z0-9 ]+-----[ \t\r\n]*\z/ )
		{
			return $self->_fail( "the armor of $key->{name} "
				    . 'holds text after its end line' );
		}

		$text .= "$key->{stem}\n";
		$text .= "purpose: $key->{purpose}\n";
		$text .= "serial: $key->{serial}\n";
		$text .= "status: $key->{status}\n";
		$text .= "fingerprint: $key->{fingerprint}\n"
		    if defined $key->{fingerprint};
		$text .= "since: $key->{since}\n" if defined $key->{since};
		$text .= "until: $key->{until}\n" if defined $key->{until};
		$text .= "\n";

		# One trailing newline, whatever the source held.
		my $body = $armor;
		$body =~ s/\n*\z//;
		$text .= "$body\n\n";
	}

	return $text;
}

# $self->index_data($keys):
#	The data of the human page, as an array reference of hash
#	references in publication order.
#
#	Each entry holds the stem, the serial, the purpose, the type,
#	the fingerprint, the status, the dates and the file name. The
#	method renders no HTML, because the site owns the template.
#	An absent optional field stays undef, so a template tests one
#	thing.
sub index_data ( $self, $keys )
{
	$self->{error} = undef;

	my $ordered = $self->order($keys) or return;

	my @rows;
	for my $key (@$ordered) {
		push @rows,
		    {
			name        => $key->{name},
			stem        => $key->{stem},
			serial      => $key->{serial},
			purpose     => $key->{purpose},
			type        => $key->{type},
			status      => $key->{status},
			fingerprint => $key->{fingerprint},
			since       => $key->{since},
			until       => $key->{until},
			email       => $key->{email},
		    };
	}

	return \@rows;
}

# $self->security_txt(%args):
#	The text of security.txt, per RFC 9116.
#
#	%args:
#		contact    => $value    # Required: one value, or an
#		                        # array reference of values
#		expires    => $stamp    # Required: an RFC 3339 stamp
#		encryption => $url      # Optional: one, or many
#		languages  => $list     # Optional: an array reference
#
#	RFC 9116 makes Contact and Expires necessary, so the method
#	fails without either one. The RFC gives no order to the field
#	types. It states only that the order of two Contact values
#	carries the preference of the operator.
#
#	This method therefore fixes one order of its own: Contact,
#	Expires, each Encryption field, then Preferred-Languages. A
#	fixed order makes two runs write one byte sequence, and it
#	keeps the contact first. Each list keeps the order that the
#	caller named.
sub security_txt ( $self, %args )
{
	$self->{error} = undef;

	# The sidecar states that a method dies for an argument of the
	# wrong reference type. Without this test a reference
	# stringifies into the file, and a field then reads
	# "Contact: HASH(0x55...)".
	for my $name (qw(contact expires encryption languages)) {
		my $value = $args{$name};
		next unless defined $value;
		next unless ref $value;
		next if ref $value eq 'ARRAY' && $name ne 'expires';
		die "$name must be a plain value"
		    . ( $name eq 'expires' ? '' : ' or an array reference' )
		    . "\n";
	}

	my @contact = _as_list( $args{contact} );
	unless (@contact) {
		return $self->_fail('contact is a necessary field');
	}

	my $expires = $args{expires};
	unless ( defined $expires && length $expires ) {
		return $self->_fail('expires is a necessary field');
	}

	# A field value must hold no newline: one line holds one
	# field, and an embedded newline would forge a second field.
	my @encryption = _as_list( $args{encryption} );
	my @languages  = _as_list( $args{languages} );
	for my $value ( @contact, $expires, @encryption, @languages ) {
		next unless $value =~ /[\r\n]/;
		return $self->_fail("a field value holds a newline: $value");
	}

	# The Preferred-Languages field joins its values on a comma,
	# so a value that holds one would forge a second language tag.
	# A tag of RFC 9116 never holds a comma.
	for my $value (@languages) {
		next unless $value =~ /,/;
		return $self->_fail("a language value holds a comma: $value");
	}

	my $text = '';
	$text .= "Contact: $_\n" for @contact;
	$text .= "Expires: $expires\n";
	$text .= "Encryption: $_\n" for @encryption;
	$text .= 'Preferred-Languages: ' . join( ', ', @languages ) . "\n"
	    if @languages;

	return $text;
}

# $self->_parse_set($keys):
#	Every key of the set with the parts of its name, its status,
#	and each field that the caller passed. The method returns a
#	new array reference, so no caller mutates its own input.
#
#	The method holds each key to the vocabulary, because order and
#	check_statuses both read the status. An empty set is a
#	failure: a directory with no key publishes nothing, and a
#	caller that passes an empty set has a bug of its own.
sub _parse_set ( $self, $keys )
{
	unless ( ref $keys eq 'ARRAY' ) {
		die "keys must be an array reference\n";
	}

	unless (@$keys) {
		return $self->_fail('the key set is empty');
	}

	my ( @out, %seen );
	for my $key (@$keys) {
		unless ( ref $key eq 'HASH' ) {
			die "each key must be a hash reference\n";
		}

		my $name  = $key->{name};
		my $parts = $self->parse_name($name) or return;

		if ( $seen{$name}++ ) {
			return $self->_fail("the key set holds $name twice");
		}

		my $status = $key->{status};
		unless ( defined $status && exists $STATUS_RANK{$status} ) {
			return $self->_fail( "the key $name holds the status "
				    . ( $status // '(undef)' )
				    . ', and the vocabulary is '
				    . join( ', ', STATUSES ) );
		}

		push @out, { %$key, %$parts, name => $name };
	}

	return \@out;
}

# $self->_fail($reason):
#	Record the reason and return undef, so each public method
#	fails the same way.
sub _fail ( $self, $reason )
{
	$self->{error} = $reason;
	return;
}

# _as_list($value):
#	One value, an array reference, or undef, as a list. A caller
#	names one contact or many, and the method takes both.
sub _as_list ($value)
{
	return () unless defined $value;
	if ( ref $value eq 'ARRAY' ) {
		for my $element (@$value) {
			next unless defined $element && ref $element;
			die "a list element must be a plain value\n";
		}
		return grep { defined $_ && length $_ } @$value;
	}
	return length $value ? ($value) : ();
}

1;
