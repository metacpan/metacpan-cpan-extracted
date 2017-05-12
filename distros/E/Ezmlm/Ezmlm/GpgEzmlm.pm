# ===========================================================================
# GpgEzmlm.pm
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

package Mail::Ezmlm::GpgEzmlm;

use strict;
use warnings;
use diagnostics;
use vars qw($GPG_EZMLM_BASE $GPG_BIN $VERSION @ISA @EXPORT @EXPORT_OK);
use File::Copy;
use Carp;

use Mail::Ezmlm;

# this package inherits object methods from Mail::Ezmlm
@ISA = qw(Mail::Ezmlm);

$VERSION = '0.1';

require 5.005;

=head1 NAME

Mail::Ezmlm::GpgEzmlm - Object Methods for encrypted Ezmlm Mailing Lists

=head1 SYNOPSIS

 use Mail::Ezmlm::GpgEzmlm;
 $list = new Mail::Ezmlm::GpgEzmlm(DIRNAME);

The rest is a bit complicated for a Synopsis, see the description.

=head1 DESCRIPTION

Mail::Ezmlm::GpgEzmlm is a Perl module that is designed to provide an object
interface to encrypted mailing lists based upon gpg-ezmlm.
See the gpg-ezmlm web page (http://www.synacklabs.net/projects/crypt-ml/) for
details about this software.

The Mail::Ezmlm::GpgEzmlm class is inherited from the Mail::Ezmlm class.

=cut

# == Begin site dependant variables ==
$GPG_EZMLM_BASE = '/usr/bin';	# Autoinserted by Makefile.PL
$GPG_BIN = '/usr/bin/gpg';	# Autoinserted by Makefile.PL

# == clean up the path for taint checking ==
local $ENV{PATH};
# the following lines were taken from "man perlrun"
$ENV{PATH} = $GPG_EZMLM_BASE;
$ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};


# check, if gpg-ezmlm is installed
unless (-x "$GPG_EZMLM_BASE/gpg-ezmlm-manage.pl") {
	die("Warning: gpg-ezmlm does not seem to be installed - "
			. "executable '$GPG_EZMLM_BASE/gpg-ezmlm-manage.pl' not found!");
}


# == Initialiser - Returns a reference to the object ==

=head2 Setting up a new Mail::Ezmlm::GpgEzmlm object:

   use Mail::Ezmlm::GpgEzmlm;
   $list = new Mail::Ezmlm::GpgEzmlm('/home/user/lists/moolist');

new() returns undefined if an error occoured.

Use this function to access an existing encrypted mailing list.

=cut

sub new { 
	my ($class, $list_dir) = @_;
	# call the previous initialization function
	my $self = $class->SUPER::new($list_dir);
	bless $self, ref $class || $class || 'Mail::Ezmlm::GpgEzmlm';
	# define the available (supported) options for gpg-ezmlm ==
	@{$self->{SUPPORTED_OPTIONS}} = (
			"GnuPG",
			"KeyDir",
			"RequireSub",
			"RequireSigs",
			"NoKeyNoCrypt",
			"SignMessages",
			"EncryptToAll",
			"VerifiedKeyReq",
			"AllowKeySubmission");
	# check if the mailing is encrypted
	if (_is_encrypted($list_dir)) {
		return $self;
	} else {
		return undef;
	}
}

# == convert an existing list to gpg-ezmlm ==

=head2 Converting a plaintext mailing list to an encrypted list:

You need to have a normal list before you can convert it into an encrypted list.
You can create plaintext mailing list with Mail::Ezmlm.

   $encrypted_list->Mail::Ezmlm::GpgEzmlm->convert_to_encrypted('/lists/foo');

Use this function to convert a plaintext list into an encrypted mailing list.
The function returns a Mail::Ezmlm::GpgEzmlm object if it was successful.
Otherwise it returns undef.

=cut

sub convert_to_encrypted {
	my $class = shift;
	my $list_dir = shift;
	my ($backup_dir);

	# untaint "list_dir"
	$list_dir =~ m/^([\w\d\_\-\.\@ \/]+)$/;
	if (defined($1)) {
		$list_dir = $1;
	} else {
		warn "[GpgEzmlm] list directory contains invalid characters!";
		return undef;
	}

	# the backup directory will contain the old config file and the dotqmails
	$backup_dir = _get_config_backup_dir($list_dir);
	if ((! -e $backup_dir) && (!mkdir($backup_dir))) {
		warn "[GpgEzmlm] failed to create gpg-ezmlm conversion backup dir ("
				. "$backup_dir): $!";
		return undef;
	}

	# check the input
	unless (defined($list_dir)) {
		warn '[GpgEzmlm] must define directory in convert_to_encrypted()';
		return undef;
	}

	# does the list directory exist?
	unless (-d $list_dir) {
		warn '[GpgEzmlm] directory does not exist: ' . $list_dir;
		return undef;
	}

	# the list should currently _not_ be encrypted
	if (_is_encrypted($list_dir)) {
		warn '[GpgEzmlm] list is already encrypted: ' . $list_dir;
		return undef;
	}


	# here starts the real conversion - the code is based on
	# "gpg-ezmlm-convert.pl" - see http://www.synacklabs.net/projects/crypt-ml/

	# update the dotqmail files
	return undef unless (_cleanup_dotqmail_files($list_dir, $backup_dir));

	# create the new config file, if it did not exist before
	unless (-e "$backup_dir/config.gpg-ezmlm") {
		if (open(CONFIG_NEW, ">$backup_dir/config.gpg-ezmlm")) {
			# just create the empty file (default)
			close CONFIG_NEW;
		} else {
			warn "[GpgEzmlm] failed to create new config file ("
					. "$backup_dir/config.gpg-ezmlm): $!";
			return undef;
		}
	}

	return undef unless (&_enable_encryption_config_file($list_dir));

	# create the (empty) gnupg keyring directory - this enables the keyring
	# management interface. Don't create it, if it already exists.
	if ((!-e "$list_dir/.gnupg") && (!mkdir("$list_dir/.gnupg", 0700))) {
		warn "[GpgEzmlm] failed to create the gnupg keyring directory: $!";
		return undef;
	}

	my $result = $class->new($list_dir);
	return $result;
}

# == convert an encrypted list back to plaintext ==

=head2 Converting an encryted mailing list to a plaintext list:

   $list->convert_to_plaintext();

This function returns undef in case of errors. Otherwise the Mail::Ezmlm
object of the plaintext mailing list is returned.

=cut

sub convert_to_plaintext {
	my $self = shift;
	my ($dot_loc, $list_dir, $dot_prefix, $backup_dir);

	$list_dir = $self->thislist();
	# untaint the input
	$list_dir =~ m/^([\w\d\_\-\.\/\@]+)$/;
	unless (defined($1)) {
		# sanitize directory name (it must be safe to put the warn message)
		$list_dir =~ s/\W/_/g;
		warn "[GpgEzmlm] the list directory contains invalid characters: '"
				. $list_dir . "' (special characters are escaped)";
		return undef;
	}
	$list_dir = $1;

	# check if a directory was given
	unless (defined($list_dir)) {
		$self->_seterror(-1, 'must define directory in convert_to_plaintext()');
		return undef;
	}
	# the list directory must exist
	unless (-d $list_dir) {
		$self->_seterror(-1, 'directory does not exist: ' . $list_dir);
		return undef;
	}
	# check if the current object is still encrypted
	unless (_is_encrypted($list_dir)) {
		$self->_seterror(-1, 'list is not encrypted: ' . $list_dir);
		return undef;
	}

	# retrieve location of dotqmail-files
	$dot_loc = _get_dotqmail_location($list_dir);

	# untaint "dot_loc"
	$dot_loc =~ m/^([\w\d\_\-\.\@ \/]+)$/;
	if (defined($1)) {
		$dot_loc = $1;
	} else {
		$dot_loc =~ s/\W/_/g;
		warn "[GpgEzmlm] directory name of dotqmail files contains invalid "
				. "characters: $dot_loc (special characters are escaped)";
		return undef;
	}

	# the backup directory should contain the old config file (if it existed)
	# and the original dotqmail files
	$backup_dir = _get_config_backup_dir($self->thislist());
	unless (-r $backup_dir) {
		warn "[GpgEzmlm] failed to revert conversion - the backup directory "
				. "is missing: $backup_dir";
		return undef;
	}

	# the "dot_prefix" is the basename of the main dotqmail file
	# (e.g. '.qmail-list-foo')
	$dot_loc =~ m/\/([^\/]+)$/;
	if (defined($1)) {
		$dot_prefix = $1;
	} else {
		warn '[GpgEzmlm] invalid location of dotqmail file: ' . $dot_loc;
		return undef;
	}

	# the "dotqmail" location must be valid
	unless (defined($dot_loc) && ($dot_loc ne '') && (-e $dot_loc)) {
		$self->_seterror(-1, 'dotqmail files not found: ' . $dot_loc);
		return undef;
	}

	# start reverting the gpg-ezmlm conversion:
	# - restore old dotqmail files
	# - restore old config file (if it existed before)

	# restore original config file (if it exists)
	&_enable_plaintext_config_file($list_dir);

	# replace the dotqmail files with the ones from the backup
	unless ((File::Copy::copy("$backup_dir/$dot_prefix", "$dot_loc"))
			&& (File::Copy::copy("$backup_dir/$dot_prefix-default",
					"$dot_loc-default",))) {
		warn "[GpgEzmlm] failed to restore dotqmail files: $!";
		return undef;
	}

	$self = Mail::Ezmlm->new($list_dir);
	return $self;
}

# == Update the "normal" settings  of the current list ==

=head2 Updating the common configuration settings of the current list:

   $list->update("moUx");

=cut

# update the "normal" (=not related to encryption) settings of the list
sub update {
	my $self = shift;
	my $options = shift;

	my ($result);

	
	# restore the ususal ezmlm-idx config file (for v0.4xx)
	&_enable_plaintext_config_file($self->thislist());
	# let ezmlm-make do the setup
	$result = $self->SUPER::update($options);
	# restore the gpg-ezmlm config file
	&_enable_encryption_config_file($self->thislist());
	# "repair" the dotqmail files (use "gpg-ezmlm-send" instead of "ezmlm-send")
	&_cleanup_dotqmail_files($self->thislist());

	# return the result of the ezmlm-make run
	return $result;
}

# == Update the encryption settings of the current list ==

=head2 Updating the configuration of the current list:

   $list->update_special({ 'allowKeySubmission' => 1 });

=cut

# update the encryption specific settings
sub update_special {
	my ($self, %switches) = @_;
	my (%ok_switches, $one_key, @delete_switches);

	# check for important files: 'config'
	unless (_is_encrypted($self->thislist())) {
		$self->_seterror(-1, "Update failed: '" . $self->thislist()
				. "' does not appear to be a valid list");
		return undef;
	}

	@delete_switches = ();
	# check if all supplied settings are supported
	# btw we change the case (upper/lower) of the setting to the default one
	foreach $one_key (keys %switches) {
		my $ok_key;
		foreach $ok_key (@{$self->{SUPPORTED_OPTIONS}}) {
			# check the key case-insensitively
			if ($ok_key =~ /^$one_key$/i) {
				$ok_switches{$ok_key} = $switches{$one_key};
				push @delete_switches, $one_key;
			}
		}
	}
	# remove all keys, that were accepted above
	# we could not do it before, since this could cause issues with the current
	# "foreach" looping through the hash
	foreach $one_key (@delete_switches) {
		delete $switches{$one_key};
	}

	# %switches should be empty now
	if (%switches) {
		foreach $one_key (keys %switches) {
			warn "[GpgEzmlm] unsupported setting: $one_key";
		}
	}

	my $errorstring;
	my $config_file_old = $self->thislist() . "/config";
	my $config_file_new = $self->thislist() . "/config.new";
	my $gnupg_setting_found = (0==1);
	if (open(CONFIG_OLD, "<$config_file_old")) { 
		if (open(CONFIG_NEW, ">$config_file_new")) { 
			my ($in_line, $one_opt, $one_val, $new_setting);
			while (<CONFIG_OLD>) {
				$in_line = $_;
				$gnupg_setting_found = (0==0) if ($in_line =~ m/^\s*GnuPG\s+/i);
				if (%ok_switches) {
					my $found = 0;
					while (($one_opt, $one_val) = each(%ok_switches)) {
						# is this the right line (maybe commented out)?
						if ($in_line =~ m/^#?\s*$one_opt\s+/i) {
							print CONFIG_NEW _get_config_line($one_opt, $one_val);
							delete $ok_switches{$one_opt};
							$found = 1;
						}
					}
					print CONFIG_NEW $in_line if ($found == 0);
				} else {
					# just print the remaining config file if no other settings are left
					print CONFIG_NEW $in_line;
				}
			}
			# write the remaining settings to the end of the file
			while (($one_opt, $one_val) = each(%ok_switches)) {
				print CONFIG_NEW _get_config_line($one_opt, $one_val);
			}
			# always set the default value for the "gpg" setting explicitely,
			# if it was not overriden - otherwise gpg-ezmlm breaks on most
			# systems (its default location is /usr/local/bin/gpg)
			unless ($gnupg_setting_found) {
				print CONFIG_NEW _get_config_line("GnuPG", $GPG_BIN);
			}
		} else {
			$errorstring = "failed to write to temporary config file: $config_file_new";
			$self->_seterror(-1, $errorstring);
			warn "[GpgEzmlm] $errorstring";
			close CONFIG_OLD;
			return (1==0);
		}
		close CONFIG_NEW;
	} else {
		$errorstring = "failed to read the config file: $config_file_old";
		$self->_seterror(-1, $errorstring);
		warn "[GpgEzmlm] $errorstring";
		return (1==0);
	}
	close CONFIG_OLD;
	unless (rename($config_file_new, $config_file_old)) {
		$errorstring = "failed to move new config file ($config_file_new) " 
			. "to original config file ($config_file_old)";
		$self->_seterror(-1, $errorstring);
		warn "[GpgEzmlm] $errorstring";
		return (1==0);
	}
	$self->_seterror(undef);
	return (0==0);
}


# return the configuration file string for a key/value combination
sub _get_config_line {
		my $key = shift;
		my $value = shift;

		my $result = "$key ";
		if (($key eq "GnuPG") || ($key eq "keyDir")) {
			# these are the only settings with string values
			# escape special characters
			$value =~ s/[^\w\.\/\-]/_/g;
			$result .= $value;
		} else {
			$result .= ($value)? "yes" : "no";
		}
		$result .= "\n";
		return $result;
}

# == Get a list of options for the current list ==

=head2 Getting the current configuration of the current list:

   $list->getconfig;

getconfig() returns a hash including all available settings
(undefined settings are returned with their default value).

=cut

# call the original 'getconfig' function after restoring the "normal" config
# file (necessary only for ezmlm-idx < 0.4x)
sub getconfig {
	my $self = shift;

	my ($result);

	&_enable_plaintext_config_file($self->thislist());
	$result = $self->SUPER::getconfig();
	&_enable_encryption_config_file($self->thislist());

	return $result;
}

# retrieve the specific configuration of the list
sub getconfig_special {
	my ($self) = @_;
	my (%options, $list_dir);

	# continue with retrieving the encryption configuration

	# define defaults
	$options{KeyDir} = '';
	$options{SignMessages} = 1;
	$options{NoKeyNoCrypt} = 0;
	$options{AllowKeySubmission} = 1;
	$options{EncryptToAll} = 0;
	$options{VerifiedKeyReq} = 0;
	$options{RequireSub} = 0;
	$options{RequireSigs} = 0;


	# Read the config file
	$list_dir = $self->thislist();
	if (open(CONFIG, "<$list_dir/config")) { 
		# 'config' contains the authorative information
		while(<CONFIG>) {
			if (/^(\w+)\s(.*)$/) {
				my $optname = $1;
				my $optvalue = $2;
				my $one_opt;
				foreach $one_opt (@{$self->{SUPPORTED_OPTIONS}}) {
					if ($one_opt =~ m/^$optname$/i) {
						if ($optvalue =~ /^yes$/i) {
							$options{$one_opt} = 1;
						} else {
							$options{$one_opt} = 0;
						}
					}
				}
			}
		}
		close CONFIG;
	} else {
		$self->_seterror(-1, 'unable to read configuration file in getconfig()');
		return undef;
	}

	$self->_seterror(undef);
	return %options;
}


# ********** internal functions ****************

# return the location of the dotqmail files
sub _get_dotqmail_location {
	my $list_dir = shift;
	my ($plain_list, $dot_loc);

	$plain_list = Mail::Ezmlm->new($list_dir);
	if ($plain_list) {
		if (-r "$list_dir/dot") {
			$dot_loc = $plain_list->getpart("dot");
			chomp($dot_loc);
		} elsif (-r "$list_dir/config") {
			# the "config" file was used before ezmlm-idx v5
			$dot_loc = $1 if ($plain_list->getpart("config") =~ /^T:(.*)$/m);
		} else {
			warn '[GpgEzmlm] list configuration file not found: ' . $list_dir;
			$dot_loc = undef;
		}
	} else {
		# return undef for invalid list directories
		$dot_loc = undef;
	}
	return $dot_loc;
}


# return true if the given directory contains a gpg-ezmlm mailing list
sub _is_encrypted {
	my $list_dir = shift;
	my ($result, $plain_list);
	
	# by default we assume, that the list is not encrypted
	$result = 0;

	if (-e "$list_dir/lock") {
		# it is a valid ezmlm-idx mailing list
		$plain_list = Mail::Ezmlm->new($list_dir);
		if ($plain_list) {
			if (-e "$list_dir/config") {
				my $content = $plain_list->getpart("config");
				$content = '' unless defined($content);
				# return false if we encounter the usual ezmlm-idx-v0.4-header
				if ($content =~ /^F:/m) {
					# this is a plaintext ezmlm-idx v0.4 mailing list
					# this is a valid case - no warning necessary
				} else {
					# this is a gpg-ezmlm mailing list
					$result = 1;
				}
			} else {
				# gpg-ezmlm needs a "config" file - thus the list seems to be plain
				# this is a valid case - no warning necessary
			}
		} else {
			# failed to create a plaintext mailing list object
			warn "[GpgEzmlm] failed to create Mail::Ezmlm object for: "
					. $list_dir;
		}
	} else {
		warn "[GpgEzmlm] Directory does not appear to contain a valid list: "
				. $list_dir;
	}

	return $result;
}


# what is done:
# - copy current dotqmail files to the backup directory
# - replace "ezmlm-send" and "ezmlm-manage" with the gpg-ezmlm replacements
#   (in the real dotqmail files)
# This function should be called:
# 1) as part of the plaintext->encryption conversion of a list
# 2) after calling ezmlm-make for an encrypted list (since the dotqmail files
#    are overwritten by ezmlm-make)
sub _cleanup_dotqmail_files {
	my $list_dir = shift;
	my ($backup_dir, $dot_loc, $dot_prefix);

	# where should we store the current dotqmail files?
	$backup_dir = _get_config_backup_dir($list_dir);

	# retrieve location of dotqmail-files
	$dot_loc = _get_dotqmail_location($list_dir);

	# untaint "dot_loc"
	$dot_loc =~ m/^([\w\d\_\-\.\@ \/]+)$/;
	if (defined($1)) {
		$dot_loc = $1;
	} else {
		$dot_loc =~ s/\W/_/g;
		warn "[GpgEzmlm] directory name of dotqmail files contains invalid "
				. "characters: $dot_loc (escaped special characters)";
		return undef;
	}

	# the "dot_prefix" is the basename of the main dotqmail file
	# (e.g. '.qmail-list-foo')
	$dot_loc =~ m/\/([^\/]+)$/;
	if (defined($1)) {
		$dot_prefix = $1;
	} else {
		warn '[GpgEzmlm] invalid location of dotqmail file: ' . $dot_loc;
		return undef;
	}

	# check if the base dotqmail file exists
	unless (defined($dot_loc) && ($dot_loc ne '') && (-e $dot_loc)) {
		warn '[GpgEzmlm] dotqmail files not found: ' . $dot_loc;
		return undef;
	}

	# move the base dotqmail file
	if (open(DOT_NEW, ">$backup_dir/$dot_prefix.new")) {
		if (open(DOT_ORIG, "<$dot_loc")) {
			my $line_found = (0==1);
			while (<DOT_ORIG>) {
				my $line = $_;
				if ($line =~ /ezmlm-send\s+(\S+)/) {
					print DOT_NEW "\|$GPG_EZMLM_BASE/gpg-ezmlm-send.pl $1\n";
					$line_found = (0==0);
				} else {
					print DOT_NEW $line;
				}
			}
			close DOT_ORIG;
			# move the original file to the backup and the new file back
			if ($line_found) {
				unless ((rename($dot_loc, "$backup_dir/$dot_prefix"))
						&& (rename("$backup_dir/$dot_prefix.new", $dot_loc))) {
					warn "[GpgEzmlm] failed to move base dotqmail file: $!";
					return undef;
				}
			} else {
				warn "[GpgEzmlm] Warning: I expected a pristine base "
						. "dotqmail file: $dot_loc";
			}
		} else {
			warn "[GpgEzmlm] failed to open base dotqmail file: $dot_loc";
			return undef;
		}
		close DOT_NEW;
	} else {
		warn "[GpgEzmlm] failed to create new base dotqmail file: "
				. "$backup_dir/$dot_prefix.new";
		return undef;
	}

	# move the "-default" dotqmail file
	if (open(DEFAULT_NEW, ">$backup_dir/$dot_prefix-default.new")) {
		if (open(DEFAULT_ORIG, "<$dot_loc-default")) {
			my $line_found = (0==1);
			while (<DEFAULT_ORIG>) {
				my $line = $_;
				if ($line =~ /ezmlm-manage\s+(\S+)/) {
					print DEFAULT_NEW "\|$GPG_EZMLM_BASE/gpg-ezmlm-manage.pl $1\n";
					$line_found = (0==0);
				} else {
					print DEFAULT_NEW $line;
				}
			}
			close DEFAULT_ORIG;
			# move the original file to the backup and the new file back
			if ($line_found) {
				unless ((rename("$dot_loc-default",
								"$backup_dir/$dot_prefix-default"))
						&& (rename("$backup_dir/$dot_prefix-default.new",
								"$dot_loc-default"))) {
					warn "[GpgEzmlm] failed to move default dotqmail file: $!";
					return undef;
				}
			} else {
				warn "[GpgEzmlm] Warning: I expected a pristine default "
						. "dotqmail file: $dot_loc-default";
			}
		} else {
			warn "[GpgEzmlm] failed to open default dotqmail file: "
					. "$dot_loc-default";
			return undef;
		}
		close DEFAULT_NEW;
	} else {
		warn "[GpgEzmlm] failed to create new default dotqmail file: "
				. "$backup_dir/$dot_prefix-default.new";
		return undef;
	}

	return (0==0);
}


# activate the config file for encryption (gpg-ezmlm)
sub _enable_encryption_config_file {
	my $list_dir = shift;
	my ($backup_dir);

	$backup_dir = _get_config_backup_dir($list_dir);

	# check, if the current config file is for gpg-ezmlm or for ezmlm-idx
	if (_is_encrypted($list_dir)) {
		warn "[GpgEzmlm] I expected a pristine ezmlm-idx config file: "
				. "$list_dir/config";
		return undef;
	}

	# store the current original config file
	if ((-e "$list_dir/config") && (!File::Copy::copy("$list_dir/config",
				"$backup_dir/config.original"))) {
		warn "[GpgEzmlm] failed to save the current ezmlm-idx config file ('"
				. "$list_dir/config') to '$backup_dir/config.original': $!";
		return undef;
	}

	# copy the encryption config file to the list directory
	unless (File::Copy::copy("$backup_dir/config.gpg-ezmlm",
			"$list_dir/config")) {
		warn "[GpgEzmlm] failed to enable the gpg-ezmlm config file (from '"
				. "$backup_dir/config.gpg-ezmlm' to '$list_dir/config'): $!";
		return undef;
	}

	return (0==0);
}


# activate the config file for plain ezmlm-idx lists
sub _enable_plaintext_config_file {
	my $list_dir = shift;
	my ($backup_dir);

	$backup_dir = _get_config_backup_dir($list_dir);

	# check, if the current config file is for gpg-ezmlm or for ezmlm-idx
	unless (_is_encrypted($list_dir)) {
		warn "[GpgEzmlm] I expected a config file for gpg-ezmlm: "
				. "$list_dir/config";
		return undef;
	}

	# store the current gpg-ezmlm config file
	unless (File::Copy::copy("$list_dir/config",
				"$backup_dir/config.gpg-ezmlm")) {
		warn "[GpgEzmlm] failed to save the current gpg-ezmlm config file ('"
				. "$list_dir/config') to '$backup_dir/config.gpg-ezmlm': $!";
		return undef;
	}

	# copy the ezmlm-idx config file to the list directory - or remove the
	# currently active gpg-ezmlm config file
	if (-e "$backup_dir/config.original") {
		unless (File::Copy::copy("$backup_dir/config.original",
				"$list_dir/config")) {
			warn "[GpgEzmlm] failed to enable the originnal config file (from '"
					. "$backup_dir/config.original' to '$list_dir/config': $!";
			return undef;
		}
	} else {
		unless (unlink("$list_dir/config")) {
			warn "[GpgEzmlm] failed to remove the gpg-ezmlm config file ("
					. "$list_dir/config): $!";
			return undef;
		}
	}

	return (0==0);
}


# where should the dotqmail files and the config file be stored?
sub _get_config_backup_dir {
	my $list_dir = shift;
	return $list_dir . '/.gpg-ezmlm.backup';
}


# == check version of gpg-ezmlm ==
sub check_gpg_ezmlm_version {
	my $ret_value = system("'$GPG_EZMLM_BASE/gpg-ezmlm-convert.pl' --version &>/dev/null"); 
	# for now we do not need a specific version of gpg-ezmlm - it just has to
	# know the "--version" argument (available since gpg-ezmlm 0.3.4)
	return ($ret_value == 0);
}

# == check if gpg-ezmlm is installed ==
sub is_available {
	# the existence of the gpg-ezmlm script is sufficient for now
	return -e "$GPG_EZMLM_BASE/gpg-ezmlm-convert.pl";
}

############ some internal functions ##############

# == return an error message if appropriate ==
sub errmsg {
	my ($self) = @_;
	return $self->{'ERRMSG'};
}

sub errno {
	my ($self) = @_;
	return $self->{'ERRNO'};
}


# == Internal function to set the error to return ==
sub _seterror {
	my ($self, $no, $mesg) = @_;

	if (defined($no) && $no) {
		if ($no < 0) {
			$self->{'ERRNO'} = -1;
			$self->{'ERRMSG'} = $mesg || 'An undefined error occoured';
		} else {
			$self->{'ERRNO'} = $no / 256;
			$self->{'ERRMSG'} = $! || $mesg || 'An undefined error occoured in a system() call';
		}
	} else {
		$self->{'ERRNO'} = 0;
		$self->{'ERRMSG'} = undef;
	}
	return 1;
}

1;

=head1 AUTHOR

 Lars Kruse <devel@sumpfralle.de>

=head1 BUGS

 There are no known bugs.

 Please report bugs to the author or use the bug tracking system at
 https://systemausfall.org/trac/ezmlm-web.

=head1 SEE ALSO

 ezmlm(5), ezmlm-make(2), ezmlm-sub(1), 
 ezmlm-unsub(1), ezmlm-list(1), ezmlm-issub(1)

 https://systemausfall.org/toolforge/ezmlm-web/
 http://www.synacklabs.net/projects/crypt-ml/
 http://www.ezmlm.org/
 http://www.qmail.org/

=cut
