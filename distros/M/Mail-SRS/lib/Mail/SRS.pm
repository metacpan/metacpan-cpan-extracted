package Mail::SRS;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS
				$SRS0TAG $SRS1TAG
				$SRS0RE $SRS1RE
				$SRSSEP
				$SRSTAG $SRSWRAP
				$SRSHASHLENGTH $SRSMAXAGE
				);
use Exporter;
use Carp;
use Digest::HMAC_SHA1;

$VERSION = "0.31";
@ISA = qw(Exporter);

$SRS0TAG = "SRS0";
$SRS1TAG = "SRS1";
$SRS0RE = qr/^$SRS0TAG([-+=])/io;
$SRS1RE = qr/^$SRS1TAG([-+=])/io;
$SRSSEP = "=";

# These are deprecated.
$SRSTAG = $SRS0TAG;
$SRSWRAP = $SRS1TAG;

$SRSHASHLENGTH = 4;
$SRSMAXAGE = 21;

@EXPORT_OK = qw($SRS0TAG $SRS1TAG
				$SRS0RE $SRS1RE
				$SRSSEP
				$SRSTAG $SRSWRAP
				$SRSHASHLENGTH $SRSMAXAGE
				);
%EXPORT_TAGS = (
		all	=> \@EXPORT_OK,
			);

=head1 NAME

Mail::SRS - Interface to Sender Rewriting Scheme

=head1 SYNOPSIS

	use Mail::SRS;
	my $srs = new Mail::SRS(
		Secret     => [ .... ],    # scalar or array
		MaxAge     => 49,          # days
		HashLength => 4,           # base64 characters: 4 x 6bits
		HashMin    => 4,           # base64 characters
			);
	my $srsaddress = $srs->forward($sender, $alias);
	my $sender = $srs->reverse($srsaddress);

=head1 DESCRIPTION

The Sender Rewriting Scheme preserves .forward functionality in an
SPF-compliant world.

SPF requires the SMTP client IP to match the envelope sender
(return-path). When a message is forwarded through an intermediate
server, that intermediate server may need to rewrite the return-path
to remain SPF compliant. If the message bounces, that intermediate
server needs to validate the bounce and forward the bounce to the
original sender.

SRS provides a convention for return-path rewriting which allows
multiple forwarding servers to compact the return-path. SRS also
provides an authentication mechanism to ensure that purported bounces
are not arbitrarily forwarded.

SRS is documented at http://spf.pobox.com/srs.html and many points
about the scheme are discussed at http://www.anarres.org/projects/srs/

For a better understanding of this code and how it functions, please
read this document and run the interactive walkthrough in eg/simple.pl
in this distribution. To run this from the build directory, type
"make teach".

=head1 METHODS

=head2 $srs = new Mail::SRS(...)

Construct a new Mail::SRS object and return it. Available parameters
are:

=over 4

=item Secret => $string

A key for the cryptographic algorithms. This may be an array or a single
string. A string is promoted into an array of one element.

=item MaxAge

The maximum number of days for which a timestamp is considered
valid. After this time, the timestamp is invalid.

=item HashLength => $integer

The number of bytes of base64 encoded data to use for the cryptographic
hash. More is better, but makes for longer addresses which might
exceed the 64 character length suggested by RFC2821. This defaults to
4, which gives 4 x 6 = 24 bits of cryptographic information, which
means that a spammer will have to make 2^24 attempts to guarantee
forging an SRS address.

=item HashMin => $integer

The shortest hash which we will allow to pass authentication. Since we
allow any valid prefix of the full SHA1 HMAC to pass authentication,
a spammer might just suggest a hash of length 0. We require at least
HashMin characters, which must all be correct. Naturally, this must
be no greater than HashLength and will default to HashLength unless
otherwise specified.

=item Separator => $character

Specify the initial separator to use immediately after the SRS tag. SRS
uses the = separator throughout EXCEPT for the initial separator,
which may be any of + - or =.

Some MTAs already have a feature by which text after a + or - is
ignored for the purpose of identifying a local recipient. If the
initial separator is set to + or -, then an administrator may process
all SRS mails by creating users SRS0 and SRS1, and using Mail::SRS
in the default delivery rule for these users.

Some notes on the use and preservation of these separators are found
in the perldoc for L<Mail::SRS::Guarded>.

=item AlwaysRewrite => $boolean

SRS rewriting is not performed by default if the alias host matches
the sender host, since it would be unnecessary to do so, and it
interacts badly with ezmlm if we do. Set this to true if you want
always to rewrite when requested to do so.

=item IgnoreTimestamp => $boolean

Consider all timestamps to be valid. Defaults to false. It is STRONGLY
recommended that this remain false. This parameter is provided so that
timestamps may be ignored temporarily after a change in the timestamp
format or encoding, until all timestamps in the old encoding would
have become invalid. Note that timestamps still form a part of the
cryptographic data when this is enabled.

=item AllowUnsafeSrs

This is a backwards compatibility option for an older version of the
protocol where SRS1 was not hash-protected. The 'reverse' method
will detect such addresses, and handle them properly. Deployments
upgrading from version <=0.27 to any version >=0.28 should enable
this for MaxAge+1 days.

When this option is enabled, all new addresses will be generated with
cryptographic protection.

=back

Some subclasses require other parameters. See their documentation for
details.

=cut

sub new {
	my $class = shift;

	if ($class eq 'Mail::SRS') {
		require Mail::SRS::Guarded;
		return new Mail::SRS::Guarded(@_);
	}

	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	$self->{Secret} = [ $self->{Secret} ]
					unless ref($self->{Secret}) eq 'ARRAY';
	$self->{MaxAge} = $SRSMAXAGE unless $self->{MaxAge};
	$self->{HashLength} = $SRSHASHLENGTH unless $self->{HashLength};
	$self->{HashMin} = $self->{HashLength} unless $self->{HashMin};
	$self->{Separator} = '=' unless exists $self->{Separator};
	unless ($self->{Separator} =~ m/^[-+=]$/) {
		die "Initial separator must be = - or +, " .
						"not $self->{Separator}";
	}
	return bless $self, $class;
}

=head2 $srsaddress = $srs->forward($sender, $alias)

Map a sender address into a new sender and a cryptographic cookie.
Returns an SRS address to use as the new sender.

There are alternative subclasses, some of which will return SRS
compliant addresses, some will simply return non-SRS but valid RFC821
addresses. See the interactive walkthrough for more information on this
("make teach").

=cut

sub forward {
	my ($self, $sender, $alias) = @_;

	$sender =~ m/^(.*)\@([^\@]+)$/
					or die "Sender '$sender' contains no \@";
	my ($senduser, $sendhost) = ($1, $2);
	$senduser =~ m/\@/ and die 'Sender username may not contain an @';

	# We don't require alias to be a full address, just a domain will do
	if ($alias =~ m/^(.*)\@([^@]+)$/) {
		$alias = $2;
	}
	my $aliashost = $alias;

	if (lc $aliashost eq lc $sendhost) {
		return "$senduser\@$sendhost" unless $self->{AlwaysRewrite};
	}

	# Subclasses may override the compile() method.
	my $srsdata = $self->compile($sendhost, $senduser);
	return "$srsdata\@$aliashost";
}

=head2 $sender = $srs->reverse($srsaddress)

Reverse the mapping to get back the original address. Validates all
cryptographic and timestamp information. Returns the original sender
address. This method will die if the address cannot be reversed.

=cut

sub reverse {
	my ($self, $address) = @_;

	$address =~ m/^(.*)\@([^@])+$/ or croak 'Address contains no @';
	my ($user, $host) = ($1, $2);

	my ($sendhost, $senduser) = eval { $self->parse($user); };
	die "Parse error in `$user': $@" if $@;

	return "$senduser\@$sendhost";
}

=head2 $srs->compile($sendhost, $senduser)

This method, designed to be overridden by subclasses, takes as
parameters the original host and user and must compile a new username
for the SRS transformed address. It is expected that this new username
will be joined on $SRSSEP, and will contain a hash generated from
$self->hash_create(...), and possibly a timestamp generated by
$self->timestamp_create().

=cut

sub compile {
	croak "How did Mail::SRS::compile get called? " .
					"All subclasses override it";
}

=head2 $srs->parse($srsuser)

This method, designed to be overridden by subclasses, takes an
SRS-transformed username as an argument, and must reverse the
transformation produced by compile(). It is required to verify any
hash and timestamp in the parsed data, using $self->hash_verify($hash,
...) and $self->timestamp_check($timestamp).

=cut

sub parse {
	croak "How did Mail::SRS::parse get called? " .
					"All subclasses override it";
}

=head2 $srs->timestamp_create([$time])

Return a two character timestamp representing 'today', or $time if
given. $time is a Unix timestamp (seconds since the aeon).

This Perl function has been designed to be agnostic as to base,
and in practice, base32 is used since it can be reversed even if a
remote MTA smashes case (in violation of RFC2821 section 2.4). The
agnosticism means that the Perl uses division instead of rightshift,
but in Perl that doesn't matter. C implementors should implement this
operation as a right shift by 5.

=cut

# We have two options. We can either encode an send date or an expiry
# date. If we encode a send date, we have the option of changing
# the expiry date later. If we encode an expiry date, we can send
# different expiry dates for different sources/targets, and we don't
# have to store them.

# Do NOT use BASE64 since the timestamp_check routine now explicit
# smashes case in the timestamp just in case there was a problem.
# my @BASE64 = ('A'..'Z', 'a'..'z', '0'..'9', '+', '/');
my @BASE32 = ('A'..'Z', '2'..'7');

my @BASE = @BASE32;
my %BASE = map { $BASE[$_] => $_ } (0..$#BASE);
# This checks for more than one bit set in the size.
# i.e. is the size a power of 2?
die "Invalid base array of size " . scalar(@BASE)
				if scalar(@BASE) & (scalar(@BASE) - 1);
my $PRECISION = 60 * 60 * 24;	# One day
my $TICKSLOTS = scalar(@BASE) * scalar(@BASE);	# Two chars

sub timestamp_create {
	my ($self, $time) = @_;
	$time = time() unless defined $time;
	# Since we only mask in the bottom few bits anyway, we
	# don't need to take this modulo anything (e.g. @BASE^2).
	$time = int($time / $PRECISION); #% $TICKSLOTS;
	# print "Time is $time\n";
	my $out = $BASE[$time & $#BASE];	# $#BASE is 2^n -1
	$time = int($time / scalar(@BASE));	# Use right shift.
	return $BASE[$time & $#BASE] . $out;
}

=head2 $srs->timestamp_check($timestamp)

Return 1 if a timestamp is valid, undef otherwise. There are 4096
possible timestamps, used in a cycle. At any time, $srs->{MaxAge}
timestamps in this cycle are valid, the last one being today. A
timestamp from the future is not valid, neither is a timestamp from
too far into the past. Of course if you go far enough into the future,
the cycle wraps around, and there are valid timestamps again, but the
likelihood of a random timestamp being valid is 4096/$srs->{MaxAge},
which is usually quite small: 1 in 132 by default.

=cut

sub timestamp_check {
	my ($self, $timestamp) = @_;
	return 1 if $self->{IgnoreTimestamp};
	$timestamp = uc $timestamp;			# LOOK OUT - USE BASE32
	my $time = 0;
	foreach (split(//, $timestamp)) {
		$time = $time * scalar(@BASE) + $BASE{$_};
	}
	my $now = int(time() / $PRECISION) % $TICKSLOTS;
	# print "Time is $time, Now is $now\n";
	$now += $TICKSLOTS while $now < $time;
	return 1 if $now <= ($time + $self->{MaxAge});
	return undef;
}

=head2 $srs->time_check($time)

Similar to $srs->timestamp_check($timestamp), but takes a Unix time, and
checks that an alias created at that Unix time is still valid. This is
designed for use by subclasses with storage backends.

=cut

sub time_check {
	my ($self, $time) = @_;
	return 1 if time() <= ($time + ($self->{MaxAge} * $PRECISION));
	return undef;
}

=head2 $srs->hash_create(@data)

Returns a cryptographic hash of all data in @data. Any piece of data
encoded into an address which must remain inviolate should be hashed,
so that when the address is reversed, we can check that this data has
not been tampered with. You must provide at least one piece of data
to this method (otherwise this system is both cryptographically weak
and there may be collision problems with sender addresses).

=cut

sub hash_create {
	my ($self, @args) = @_;

	my @secret = $self->get_secret;
	croak "Cannot create a cryptographic MAC without a secret"
					unless @secret;
	my $hmac = new Digest::HMAC_SHA1($secret[0]);
	foreach (@args) {
		$hmac->add(lc $_);
	}
	my $hash = $hmac->b64digest;
	return substr($hash, 0, $self->{HashLength});
}

=head2 $srs->hash_verify($hash, @data)

Verify that @data has not been tampered with, given the cryptographic
hash previously output by $srs->hash_create(); Returns 1 or undef.
All known secrets are tried in order to see if the hash was created
with an old secret.

=cut

sub hash_verify {
	my ($self, $hash, @args) = @_;
	return undef unless length $hash >= $self->{HashMin};
	my @secret = $self->get_secret;
	croak "Cannot verify a cryptographic MAC without a secret"
					unless @secret;
	my @valid = ();
	foreach my $secret (@secret) {
		my $hmac = new Digest::HMAC_SHA1($secret);
		foreach (@args) {
			$hmac->add(lc $_);
		}
		my $valid = substr($hmac->b64digest, 0, length($hash));
		# We test all case sensitive matches before case insensitive
		# matches. While the risk of a case insensitive collision is
		# quite low, we might as well be careful.
		return 1 if $valid eq $hash;
		push(@valid, $valid);	# Lowercase it later.
	}
	$hash = lc($hash);
	foreach (@valid) {
		if ($hash eq lc($_)) {
			warn "SRS: Case insensitive hash match detected. " .
				"Someone smashed case in the local-part.";
			return 1;
		}
	}
	return undef;
}

=head2 $srs->set_secret($new, @old)

Add a new secret to the rewriter. When an address is returned, all
secrets are tried to see if the hash can be validated. Don't use "foo",
"secret", "password", "10downing", "god" or "wednesday" as your secret.

=cut

sub set_secret {
	my $self = shift;
	$self->{Secret} = [ @_ ];
}

=head2 $srs->get_secret()

Return the list of secrets. These are secret. Don't publish them.

=cut

sub get_secret {
	return @{$_[0]->{Secret}};
}

=head2 $srs->separator()

Return the initial separator, which follows the SRS tag. This is only
used as the initial separator, for the convenience of administrators
who wish to make srs0 and srs1 users on their mail servers and require
to use + or - as the user delimiter. All other separators in the SRS
address must be C<=>.

=cut

sub separator {
	return $_[0]->{Separator};
}

=head1 EXPORTS

Given :all, this module exports the following variables.

=over 4

=item $SRSSEP

The SRS separator. The choice of C<=> as internal separator was fairly
arbitrary. It cannot be any of the following:

=over 4

=item / +

Used in Base64.

=item -

Used in domains.

=item ! %

Used in bang paths and source routing.

=item :

Cannot be used in a Windows NT or Apple filename.

=item ; | *

Shell or regular expression metacharacters are probably to be avoided.

=back

=item $SRS0TAG

The SRS0 tag.

=item $SRS1TAG

The SRS1 tag.

=item $SRSTAG

Deprecated, equal to $SRS0TAG.

=item $SRSWRAP

Deprecated, equal to $SRS1TAG.

=item $SRSHASHLENGTH

The default hash length for the SRS HMAC.

=item $SRSMAXAGE

The default expiry time for timestamps.

=back

=head1 EXAMPLES OF USAGE

For people wanting boilerplate and those less familiar with using
Perl modules in larger applications.

=head2 Forward Rewriting

	my $srs = new Mail::SRS(...);
	my $address = ...
	my $domain = ...
	my $srsaddress = eval { $srs->forward($srsaddress, $domain); };
	if ($@) {
		# The rewrite failed
	}
	else {
		# The rewrite succeeded
	}

=head2 Reverse Rewriting

	my $srs = new Mail::SRS(...);
	my $srsaddress = ...
	my $address = eval { $srs->reverse($srsaddress); };
	if ($@) {
		# The rewrite failed
	}
	else {
		# The rewrite succeeded
	}

=head1 NOTES ON SRS

=head2 Case Sensitivity

RFC2821 states in section 2.4: "The local-part of a mailbox MUST BE
treated as case sensitive. Therefore, SMTP implementations MUST take
care to preserve the case of mailbox local-parts. [...]  In particular,
for some hosts the user "smith" is different from the user "Smith".
However, exploiting the case sensitivity of mailbox local-parts
impedes interoperability and is discouraged."

SRS does not rely on case sensitivity in the local part. It uses
base64 for encoding the hash, but allows a case insensitive match,
making this approximately equivalent to base36 at worst. It will
issue a warning if it detects that a remote MTA has smashed case. The
timestamp is encoded in base32.

=head2 The 64 Billion Character Question

RFC2821 section 4.5.3.1: Size limits and minimums:

	There are several objects that have required minimum/maximum
	sizes.	Every implementation MUST be able to receive objects
	of at least these sizes. Objects larger than these sizes
	SHOULD be avoided when possible. However, some Internet
	mail constructs such as encoded X.400 addresses [16] will
	often require larger objects: clients MAY attempt to transmit
	these, but MUST be prepared for a server to reject them if
	they cannot be handled by it. To the maximum extent possible,
	implementation techniques which impose no limits on the length
	of these objects should be used.

	local-part
		The maximum total length of a user name or other
		local-part is 64 characters.

Clearly, by including 2 domain names and a local-part in the rewritten
address, there is no way in which SRS can guarantee to stay under
this limit. However, very few systems are known to actively enforce
this limit, and those which become known to the developers will be
listed here.

=over 4

=item Cisco: PIX MailGuard (firewall gimmick)

=item WebShield [something] (firewall gimmick)

=back

=head2 Invalid SRS Addresses

DO NOT MALFORMAT ADDRESSES. This is designed to be an interoperable
format. Certain things are allowed, such as changing the semantics
of the hash or the timestamp. However, both of these fields must
be present and separated by the SRS separator character C<=>. The
purpose of this section is to illustrate that if a malicious party
were to malformat an address, he would gain nothing by doing so,
nor would the network suffer.

The SRS protocol is predicated on the fact that the first forwarder
provides a cryptographic wrapper on the forward chain for sending
mail to the original sender. So what happens if an SRS address is
invalid, or faked by a spammer? 

The minimum parsing of existing SRS addresses is done at each hop. If
an SRS0 address is not valid or badly formatted, it will not affect
the operation of the system: the mail will go out along the forwarder
chain, and return to the invalid or badly formatted address.

If the spammer is not pretending to be the first hop, then he
must somehow construct an SRS0 address to embed within his SRS1
address. The cryptographic checks on this SRS0 address will fail at
the first forwarder and the mail will be dropped.

If the spammer is pretending to be the first hop, then SPF should
require that any bounces coming back return to his mail server,
thus he wins nothing.

=head2 Cryptographic Systems

The hash in the address is designed to prevent the forging of reverse
addresses by a spammer, who might then use the SRS host as a forwarder.
It may only be constructed or validated by a party who knows the
secret key.

The cryptographic system in the default implementation is not mandated.
Since nobody else ever needs to interpret the hash, it is reasonable
to put any binary data into this field (subject to the possible
constraint of case insensitive encoding).

The SRS maintainers have attempted to provide a good system. It
satisfies a simple set of basic requirements: to provide unforgeability
of SRS addresses given that every MTA for a domain shares a secret key.
We prefer SHA1 over MD5 for political, rather than practical reasons.
(Anyone disputing this statement must include an example of a practical
weakness in their mail. We would love to see it.)

If you find a weakness in our system, or you think you know of a
better system, please tell us. If your requirements are different,
you may override hash_create() and hash_verify() to implement a
different system without adversely impacting the network, as long as
your addresses still behave as SRS addresses.

=head2 Extending Mail::SRS

Write a subclass. You will probably want to override compile() and
parse(). If you are more familiar with the internals of SRS, you might
want to override hash_create(), hash_verify(), timestamp_create()
or timestamp_check().

=head1 CHANGELOG

=head2 MINOR CHANGES since v0.29

=over 4

=item timestamp_check now explicitly smashes case when verifying. This
means that the base used must be base32, NOT base64.

=item hash_create and hash_verify now explicitly smash case when
creating and verifying hashes. This does not have a significant
cryptographic impact.

=back

=head2 MAJOR CHANGES since v0.27

=over 4

=item The SRS1 address format has changed to include cryptographic
information. Existing deployments should consider setting
AllowUnsafeSrs for MaxAge+1 days.

=back

=head2 MINOR CHANGES since v0.26

=over 4

=item parse() and compile() are explicitly specified to die() on error.

=back

=head2 MINOR CHANGES since v0.23

=over 4

=item Update BASE32 according to RFC3548.

=back

=head2 MINOR CHANGES since v0.21

=over 4

=item Dates are now encoded in base32.

=item Case insensitive MAC validation is now allowed, but will issue
a warning.

=back

=head2 MINOR CHANGES since v0.18

=over 4

=item $SRSTAG and $SRSWRAP are deprecated.

=item Mail::SRS::Reversable is now Mail::SRS::Reversible

This should not be a problem since people should not be using it!

=back

You must use $SRS0RE and $SRS1RE to detect SRS addresses.

=head2 MAJOR CHANGES since v0.15

=over 4

=item The separator character is now C<=>.

=item The cryptographic scheme is now HMAC with SHA1.

=item Only a prefix of the MAC is used.

=back

This API is still a release candidate and should remain relatively
stable.

=head1 BUGS

Email address parsing for quoted addresses is not yet done properly.

Case insensitive MAC validation should become an option.

=head1 TODO

Write a testsuite for testing user-defined SRS implementations.

=head1 SEE ALSO

L<Mail::SRS::Guarded>, L<Mail::SRS::DB>, L<Mail::SRS::Reversable>,
"make teach", eg/*, http://www.anarres.org/projects/srs/

=head1 AUTHOR

	Shevek
	CPAN ID: SHEVEK
	cpan@anarres.org
	http://www.anarres.org/projects/

=head1 COPYRIGHT

Copyright (c) 2004 Shevek. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
