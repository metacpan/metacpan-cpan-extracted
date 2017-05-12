# ===========================================================================
# Gpg.pm
# $Id$
#
# Object methods for gpg-ezmlm mailing lists
#
# Copyright (C) 2006, Lars Kruse, All Rights Reserved.
# Please send bug reports and comments to devel@sumpfralle.de
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# ==========================================================================

package Mail::Ezmlm::GpgKeyRing;

use strict;
use vars qw($GPG_BIN $VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
use Crypt::GPG;

$VERSION = '0.1';

require 5.005;

=head1 NAME

Mail::Ezmlm::GpgKeyRing - Object Methods for gnupg keyring management

=head1 SYNOPSIS

 use Mail::Ezmlm::GpgKeyRing;
 $keyring = new Mail::Ezmlm::GpgKeyRing(DIRNAME);

The rest is a bit complicated for a Synopsis, see the description.

=head1 DESCRIPTION

Mail::Ezmlm::GpgKeyRing is a Perl module that is designed to provide an object
interface to GnuPG keyrings for encrypted mailing lists.

=cut

# == Begin site dependant variables ==
$GPG_BIN = '/usr/bin/gpg';	# Autoinserted by Makefile.PL


# == check the gpg path ==
$GPG_BIN = '/usr/local/bin/gpg'
	unless (-x "$GPG_BIN");
$GPG_BIN = '/usr/bin/gpg'
	unless (-x "$GPG_BIN");
$GPG_BIN = '/bin/gpg'
	unless (-x "$GPG_BIN");
$GPG_BIN = '/usr/local/bin/gpg2'
	unless (-x "$GPG_BIN");
$GPG_BIN = '/usr/bin/gpg2'
	unless (-x "$GPG_BIN");
$GPG_BIN = '/bin/gpg2'
	unless (-x "$GPG_BIN");

# == clean up the path ==
local $ENV{'PATH'} = "/bin";

# check, if gpg is installed
unless (-x "$GPG_BIN") {
	die("Warning: gnupg does not seem to be installed - none of the "
			. "executables 'gpg' or 'gpg2' were found at the usual locations!");
}


# == Initialiser - Returns a reference to the object ==

=head2 Setting up a new Mail::Ezmlm::GpgKeyRing object:

   use Mail::Ezmlm::GpgKeyRing;
   $keyring = new Mail::Ezmlm::GpgKeyRing('/home/user/lists/foolist/.gnupg');

new() returns the new instance for success, undefined if there was a problem.

=cut

sub new { 
	my($class, $keyring_dir) = @_;
	my $self = {};
	bless $self, ref $class || $class || 'Mail::Ezmlm::GpgKeyRing';
	if ($self->set_location($keyring_dir)) {
		return $self;
	} else {
		return undef;
	}
}


# == Return the directory of the gnupg keyring ==

=head2 Determining the location of the configured keyring.

   $whichkeyring = $keyring->get_location();
   print $keyring->get_location();

=cut

sub get_location {
	my($self) = shift;
	return $self->{'KEYRING_DIR'};
}


# == Set the current keyring directory ==

=head2 Changing which keyring the Mail::Ezmlm::GpgKeyRing object points at:
 
   $keyring->set_location('/home/user/lists/foolist/.gnupg');

=cut

sub set_location {
	my($self, $keyring_dir) = @_;
	if (-e "$keyring_dir") {
		if (-x "$keyring_dir") {
			# at least it is a directory - so it looks ok
			$self->{'KEYRING_DIR'} = $keyring_dir;
		} else {
			# it seems to be a file or something else - we complain
			warn "GPG keyring location must be a directory: $keyring_dir";
			$self->{'KEYRING_DIR'} = undef;
		}
	} else {
		# probably the keyring directory does not exist, yet
		# a warning should not be necessary
		$self->{'KEYRING_DIR'} = $keyring_dir;
	}
	return $self->{'KEYRING_DIR'}
}


# == export a key ==

=head2 Export a key:

You may export public keys of the keyring.

The key can be identified by its id or other (unique) patterns (like the
gnupg program).

	$keyring->export_key($key_id);
	$keyring->export_key($email_address);

The return value is a string containing the ascii armored key data.

=cut

sub export_key {
	my ($self, $keyid) = @_;
	my ($gpg, $gpgoption, $gpgcommand, $output);

	# return immediately - this avoids creating an empty keyring unintentionally
	return () unless (-e $self->{'KEYRING_DIR'});
	$gpg = $self->_get_gpg_object();
	$gpgoption = "--armor --export $keyid";
	$gpgcommand = $gpg->gpgbin() . " " . $gpg->gpgopts() . " $gpgoption";
	$output = `$gpgcommand 2>/dev/null`;
	if ($output) {
		return $output;
	} else {
		return undef;
	}
}


# == import a new key ==

=head2 Import a key:

You can import public or secret keys into the keyring.

The key should be ascii armored.

	$keyring->import_key($ascii_armored_key_data);

=cut

sub import_key {
	my ($self, $key) = @_;
	my $gpg = $self->_get_gpg_object();
	if ($gpg->addkey($key)) {
		return (0==0);
	} else {
		return (1==0);
	}
}


# == delete a key ==

=head2 Delete a key:

Remove a public key (and the matching secret key if it exists) from the keyring.

The argument is the id of the key or any other unique pattern.

	$keyring->delete_key($keyid);

=cut

sub delete_key {
	my ($self, $keyid) = @_;
	my $gpg = $self->_get_gpg_object();
	my $fprint = $self->_get_fingerprint($keyid);
	return (1==0) unless (defined($fprint));
	my $gpgoption = "--delete-secret-and-public-key $fprint";
	my $gpgcommand = $gpg->gpgbin() . " " . $gpg->gpgopts() . " $gpgoption";
	if (system($gpgcommand)) {
		return (1==0);
	} else {
		return (0==0);
	}
}


# == generate new private key ==

=head2 Generate a new key:

	$keyring->generate_key($name, $comment, $email_address, $keysize, $expire);

Refer to the documentation of gnupg for the format of the arguments.

=cut

sub generate_private_key {
	my ($self, $name, $comment, $email, $keysize, $expire) = @_;
	my $gpg = $self->_get_gpg_object();
	my $gpgoption = "--gen-key";
	my $gpgcommand = $gpg->gpgbin() . " " . $gpg->gpgopts() . " $gpgoption";
	my $pid = open(INPUT, "| $gpgcommand");
	print INPUT "Key-Type: DSA\n";
	print INPUT "Key-Length: 1024\n";
	print INPUT "Subkey-Type: ELG-E\n";
	print INPUT "Subkey-Length: $keysize\n";
	print INPUT "Name-Real: $name\n";
	print INPUT "Name-Comment: $comment\n" if ($comment);
	print INPUT "Name-Email: $email\n";
	print INPUT "Expire-Date: $expire\n";
	return close INPUT;
}


# == get_public_keys ==

=head2 Getting public keys:

Return an array of key hashes each containing the following elements:

=over

=item *
name

=item *
email

=item *
id

=item *
expires

=back

	$keyring->get_public_keys();
	$keyring->get_secret_keys();

=cut

sub get_public_keys {
	my ($self) = @_;
	my @keys = $self->_get_keys("pub");
	return @keys;
}


# == get_private_keys ==
# see above for POD (get_public_keys)
sub get_secret_keys {
	my ($self) = @_;
	my @keys = $self->_get_keys("sec");
	return @keys;
}


############ some internal functions ##############

# == internal function for creating a gpg object ==
sub _get_gpg_object() {
	my ($self) = @_;
	my $gpg = new Crypt::GPG();
	my $dirname = $self->get_location();
	# replace whitespace characters in the keyring directory name
	$dirname =~ s/(\s)/\\$1/g;
	$gpg->gpgbin($GPG_BIN);
	$gpg->gpgopts("--lock-multiple --no-tty --no-secmem-warning --batch --quiet --homedir $dirname");
	return $gpg;
}


# == internal function to list keys ==
sub _get_keys() {
	# type can be "pub" or "sec"
	my ($self, $keyType) = @_;
	my ($gpg, $flag, $gpgoption, @keys, $key);

	# return immediately - this avoids creating an empty keyring unintentionally
	return () unless (-r $self->{'KEYRING_DIR'});
	$gpg = $self->_get_gpg_object();
	if ($keyType eq "pub") {
		$flag = "pub";
		$gpgoption = "--list-keys";
	} elsif ($keyType eq "sec") {
		$flag = "sec";
		$gpgoption = "--list-secret-keys";
	} else {
		warn "wrong keyType: $keyType";
		return undef;
	}
	my $gpgcommand = $gpg->gpgbin() . " " . $gpg->gpgopts() . " --with-colons $gpgoption";
	my @read_keys = grep /^$flag/, `$gpgcommand`;
	foreach $key (@read_keys) {
		my ($type, $trust, $size, $algorithm, $id, $created,
			$expires, $u2, $ownertrust, $uid) = split ":", $key;
			# stupid way of "decoding" utf8 (at least it works for ":")
			$uid =~ s/\\x3a/:/g;
			$uid =~ /^(.*) <([^<]*)>/;
			my $name = $1;
			my $email = $2;
		push @keys, {name => $name, email => $email, id => $id, expires => $expires};
	}
	return @keys;
}


# == internal function to retrieve the fingerprint of a key ==
sub _get_fingerprint()
{
	my ($self, $key_id) = @_;
	my $gpg = $self->_get_gpg_object();
	$key_id =~ /^([0-9A-Z]*)$/;
	$key_id = $1;
	return undef unless ($key_id);
	my $gpgoption = "--fingerprint $key_id";

	my $gpgcommand = $gpg->gpgbin() . " " . $gpg->gpgopts() . " --with-colons $gpgoption";
	
	my @fingerprints = grep /^fpr:/, `$gpgcommand`;
	if (@fingerprints > 1) {
		warn "[Mail::Ezmlm::GpgKeyRing] more than one key matched ($key_id)!";
		return undef;
	}
	return undef if (@fingerprints < 1);
	my $fpr = $fingerprints[0];
	$fpr =~ /^fpr:*([0-9A-Z]*):*$/;
	$fpr = $1;
	return undef unless $1;
	return $1;
}


=head1 AUTHOR

 Lars Kruse <devel@sumpfralle.de>

=head1 BUGS

 There are no known bugs.

 Please report bugs to the author or use the bug tracking system at
 https://systemausfall.org/trac/ezmlm-web.

=head1 SEE ALSO

 gnupg(7), gpg(1), gpg2(1), Crypt::GPG(3pm)

 https://systemausfall.org/toolforge/ezmlm-web/
 http://www.ezmlm.org/

=cut

