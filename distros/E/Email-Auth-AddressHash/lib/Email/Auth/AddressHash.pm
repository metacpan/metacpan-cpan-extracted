##############################################
# Email::Auth::AddressHash
# 
# Copyright 2004, Tara L Andrews <tla@mit.edu>
#
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
##############################################

package Email::Auth::AddressHash;

=head1 NAME

Email::Auth::AddressHash - Authentication based on email address
extension hash

=head1 SYNOPSIS

use Email::Auth::AddressHash;

my $auth = Email::Auth::AddressHash->new('hashlen' => 8,
					 'secret' = 'My Secret');


my $is_valid = $auth->check_hash('myuser@theirdomain.com', '83c3dac5');

my $correct_answer = $auth->generate_hash('myuser@theirdomain.com');

my $parts = $auth->split_address('myaddr+38274dc9@mydomain.com');

my $passedhash = $parts->{'hash'};

=head1 DESCRIPTION

This is a relatively simple module designed for applications which
receive email.  It provides a mechanism for authenticating email
requests, by checking that the To: address, which should be in the
form "username+hash@mydomain.com", contains the correct hash value for
that particular sender.  It uses the sender address and a locally-set
secret string to determine the correct hash for the user.  A single
AddressHash object may be used for multiple authentication checks
within the same system.

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use Digest::MD5 qw(md5_hex);

$VERSION = "1.0";

=over 4

=item Email::Auth::AddressHash->new($secret, $hashlen, $prefix, $hashtype)

Takes four arguments.  They are listed with their defaults.  They
are described more fully in the ACCESSORS section.
    'secret'   - PLEASE set this; the default is stupid on purpose.
    'hashlen'  - Default is 6.
    'prefix'   - Default is no prefix.
    'hashtype' - Default (and only supported type) is md5.

If you do use a hash prefix, you may skip setting the 'prefix'
variable if you wish, just realize that you will have to strip the
prefix yourself before passing your hash to check_auth, instead of
letting the split_address method (see below) do it for you.


=cut

sub new {
    my ($class, $secret, $hashlen, $prefix, $hashtype) = @_;
    $secret = 'swordfish' unless $secret;
    $hashlen = 6 unless $hashlen;
    $hashtype = 'md5' unless $hashtype;

    my $self = {'secret' => $secret,
		'hashlen' => $hashlen,
		'prefix' => $prefix,
		'hashtype' => $hashtype
		};

    bless ($self, $class);
    return($self);
}

=item $authenticator->check_hash($sender_address, $hashstring)

Takes two arguments, the sender's address and the email extension
that the sender sent his/her request to.  Returns true or false,
indicating whether the given hash matches the calculated hash.

=cut

sub check_hash {
    my ($self, $address, $hash) = @_;
    return ($hash eq $self->generate_hash($address, 0)) ? 1 : 0;
}

=item $authenticator->generate_hash($sender_address, $with_prefix)

Takes a single argument, the sender's address.  Returns the correctly
calculated hash for the given sender.  If $with_prefix is set to a
true value, the instance prefix (if any) is prepended.

=cut

sub generate_hash {
    my ($self, $user, $withpre) = @_;
    if ($self->{'hashtype'} eq 'md5') {
	my $key = $user . $self->{'secret'};
	my $md5key = substr(md5_hex($key), 0, $self->{'hashlen'});
	if ($withpre && $self->{'prefix'}) {
	    $md5key = $self->{'prefix'} . $md5key;
	}
	return $md5key;
    } else {
	warn("Hash method " . $self->{'hashtype'} . " not recognized!");
	return '';
    }
}

=item $partsref = $authenticator->split_address($address)

=item $rcvdhash = $authenticator->split_address($address)->{'extension'}

A convenience method.  Takes an email address and returns a reference
to a hash containing the keys 'username', 'extension', and 'domain'.
Returns undef if parsing failed.  This is a fine way to isolate the
hash to test against.

=cut

sub split_address {
    my ($self, $address) = @_;
    my $answer = {};
    my ($lhs, $rhs);
    if ($address =~ /^([\w+-]+)@([\w.-]+)$/) {
	($lhs, $answer->{'domain'}) = ($1, $2);
	if ($lhs =~ /^([\w-]+)\+(\w+)$/) {
	    ($answer->{'user'}, $answer->{'extension'}) = ($1, $2);
	    if ($self->{'prefix'}) {
		$answer->{'extension'} =~ s/^$self->{'prefix'}//;
	    }
	} else {
	    $answer->{'user'} = $lhs;
	}
    } else {
	warn('Could not parse address');
	return undef;
    }
    return $answer;
}

# Accessors.  Don't worry, I won't use gratuitous one-liners
# elsewhere.

=back

=head1 INSTANCE VARIABLES AND THEIR ACCESSORS

=over 4

=item $authenticator->set_secret('My Secret')

=item $authenticator->get_secret()

The authenticator secret is a string that is used in the hashing
algorithm.  It should be set locally in your program.  It should not
change too often, unless you like annoying your users by changing the
email address they should use for your program all the time.

=cut

sub set_secret {
    $_[0]->secret = $_[1];
}

sub get_secret {
    return $_[0]->secret;
}

=item $authenticator->set_prefix('ma')

=item $authenticator->get_prefix()

The prefix is a fixed string that you expect to appear at the
beginning of every email extension received by your application.  You
may not need this, but it is useful if you expect a single email
account to be able to run several different programs, and want to
differentiate the requests via something like procmail.  In the above
example, with the prefix set to 'ma', users should send all requests
to an address like myprog+ma38c319@mydomain.com.

=cut

sub set_prefix {
    $_[0]->prefix = $_[1];
}

sub get_prefix {
    return $_[0]->prefix;
}

=item $authenticator->set_hashlen($length)

=item $authenticator->get_hashlen()

This is the length you expect your authentication hashes to be, not
counting any prefix you have set.  The default length is 6.

=cut

sub set_hashlen {
    $_[0]->hashlen = $_[1];
}

sub get_hashlen {
    return $_[0]->hashlen;
}

=item $authenticator->set_hashtype($type)

=item $authenticator->get_hashtype()

This is the hashing algorithm that the module should use.  Currently
the only supported algorithm is md5.

=cut

sub set_hashtype {
    $_[0]->hashtype = $_[1];
}

sub get_hashtype {
    return $_[0]->hashtype;
}

1;

=back

=head1 AUTHOR

Tara L Andrews <tla@mit.edu>

=head1 SEE ALSO

L<Digest::MD5>

=cut
