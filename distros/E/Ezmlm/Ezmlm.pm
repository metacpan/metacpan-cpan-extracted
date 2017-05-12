# ===========================================================================
# Ezmlm.pm - version 0.08.2 - 10/15/2008
# $Id: Ezmlm.pm 453 2008-10-16 01:22:44Z lars $
#
# Object methods for ezmlm mailing lists
#
# Copyright (C) 1999-2005, Guy Antony Halse, All Rights Reserved.
# Copyright (C) 2005-2008, Lars Kruse, All Rights Reserved.
# Please send bug reports and comments to ezmlm-web@sumpfralle.de.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: 
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither name Guy Antony Halse nor the names of any contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# ==========================================================================
# POD is at the end of this file. Search for '=head' to find it
package Mail::Ezmlm;

use strict;
use vars qw($QMAIL_BASE $EZMLM_BASE $MYSQL_BASE $VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
use Text::ParseWords;

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
   
);
$VERSION = '0.08.2';

require 5.005;

# == Begin site dependant variables ==
$EZMLM_BASE = '/usr/local/bin'; #Autoinserted by Makefile.PL
$QMAIL_BASE = '/var/qmail'; #Autoinserted by Makefile.PL
$MYSQL_BASE = ''; #Autoinserted by Makefile.PL
# == End site dependant variables ==

# == check the ezmlm-make path ==
$EZMLM_BASE = '/usr/local/bin/ezmlm' unless (-e "$EZMLM_BASE/ezmlm-make");
$EZMLM_BASE = '/usr/local/bin/ezmlm-idx' unless (-e "$EZMLM_BASE/ezmlm-make");
$EZMLM_BASE = '/usr/local/bin' unless (-e "$EZMLM_BASE/ezmlm-make");
$EZMLM_BASE = '/usr/bin/ezmlm' unless (-e "$EZMLM_BASE/ezmlm-make");
$EZMLM_BASE = '/usr/bin/ezmlm-idx' unless (-e "$EZMLM_BASE/ezmlm-make");
$EZMLM_BASE = '/usr/bin' unless (-e "$EZMLM_BASE/ezmlm-make");

# == clean up the path for taint checking ==
local $ENV{'PATH'} = $EZMLM_BASE;

# == Initialiser - Returns a reference to the object ==
sub new { 
	my($class, $list) = @_;
	my $self = {};
	bless $self, ref $class || $class || 'Mail::Ezmlm';
	$self->setlist($list) if(defined($list) && $list);      
	return $self;
}

# == Make a new mailing list and set it to current ==
sub make {
	my($self, %list) = @_;
	my($VHOST, $comandline, $hostname);

	# Do we want to use command line switches
	my $commandline = '';
	$commandline = '-' . $list{'-switches'} if(defined($list{'-switches'}));
	my @commandline;
	foreach (&quotewords('\s+', 1, $commandline)) {
		next if (!defined($_));
		# untaint input
		$_ =~ s/['"]//g;
		$_ =~ m/^([\w _\/,\.\@:'"-]*)$/;
		if ($_ =~ /^\s*$/) {
			push @commandline, "";
		} else {
			push @commandline, $1;
		}
	}

	# These three variables are essential
	($self->_seterror(-1, 'must define -dir in a make()') && return 0) unless(defined($list{'-dir'}));
	($self->_seterror(-1, 'must define -qmail in a make()') && return 0) unless(defined($list{'-qmail'})); 
	($self->_seterror(-1, 'must define -name in a make()') && return 0) unless(defined($list{'-name'}));

	# Determine hostname if it is not supplied
	$hostname = $self->_getdefaultdomain;
	if(defined($list{'-host'})) {
		$VHOST = 1 unless ($list{'-host'} eq $hostname);
	} else {
		$list{'-host'} = $hostname;
	}

	# does the mailing list directory already exist?
	if (-e $list{'-dir'}) {
		$self->_seterror(-1,
			'-the mailing list directory already exists: ' . $list{'-dir'});
		return undef;
	}

	# Attempt to make the list if we can.
	if (system("$EZMLM_BASE/ezmlm-make", @commandline, $list{'-dir'}, $list{'-qmail'}, $list{'-name'}, $list{'-host'}) != 0) {
		$self->_seterror($?, '-failed to create mailing list - check your webserver\'s log file for details');
		return undef;
	}   

	# Sort out the DIR/inlocal problem if necessary
	if(defined($VHOST)) {
		unless(defined($list{'-user'})) {
			($self->_seterror(-1, '-user must match virtual host user in make()') && return 0) unless($list{'-user'} = $self->_getvhostuser($list{'-host'}));
		}

		open(INLOCAL, ">$list{'-dir'}/inlocal") || ($self->_seterror(-1, 'unable to read inlocal in make()') && return 0);
		print INLOCAL $list{'-user'} . '-' . $list{'-name'} . "\n";
		close INLOCAL;
	}   

	$self->_seterror(undef);
	return $self->setlist($list{'-dir'});
}

# == Update the current list ==
sub update {
	my($self, $switches) = @_;
	my($outhost, $inlocal);

	# Do we have the command line switches
	($self->_seterror(-1, 'nothing to update()') && return 0) unless(defined($switches));
	$switches = '-e' . $switches;
	my @switch_list;

	foreach (&quotewords('\s+', 1, $switches)) {
		next if (!defined($_));
		# untaint input
		$_ =~ s/['"]//g;
		$_ =~ m/^([\w _\/,\.\@:'"-]*)$/;
		if ($_ =~ /^\s*$/) {
			push @switch_list, "";
		} else {
			push @switch_list, $1;
		}
	}

	# can we actually alter this list;
	($self->_seterror(-1, 'must setlist() before you update()') && return 0) unless(defined($self->{'LIST_NAME'}));
	# check for important files: 'config' (idx < v5.0) or 'flags' (idx >= 5.0)
	($self->_seterror(-1, "$self->{'LIST_NAME'} does not appear to be a valid list in update()") && return 0) unless((-e "$self->{'LIST_NAME'}/config") || (-e "$self->{'LIST_NAME'}/flags"));

	# Work out if this is a vhost.
	open(OUTHOST, "<$self->{'LIST_NAME'}/outhost") || ($self->_seterror(-1, 'unable to read outhost in update()') && return 0);
	chomp($outhost = <OUTHOST>);
	close(OUTHOST);

	# Save the contents of inlocal if it is a vhost
	unless($outhost eq $self->_getdefaultdomain) {
		open(INLOCAL, "<$self->{'LIST_NAME'}/inlocal") || ($self->_seterror(-1, 'unable to read inlocal in update()') && return 0);
		chomp($inlocal = <INLOCAL>);
		close(INLOCAL);
	}

	# Attempt to update the list if we can.
	system("$EZMLM_BASE/ezmlm-make", @switch_list, $self->{'LIST_NAME'}) == 0
		|| ($self->_seterror($?) && return undef);
	
	# Sort out the DIR/inlocal problem if necessary
	if(defined($inlocal)) {
		open(INLOCAL, ">$self->{'LIST_NAME'}/inlocal") || ($self->_seterror(-1, 'unable to write inlocal in update()') && return 0);
		print INLOCAL "$inlocal\n";
		close INLOCAL;
	}   

	$self->_seterror(undef);
	return $self->{'LIST_NAME'};
}

# == Get a list of options for the current list ==
sub getconfig {
	my($self) = @_;
	my($options);

	# Read the config file
	if(-e $self->{LIST_NAME} . "/flags") { 
		# this file exists since ezmlm-idx-5.0.0
		# 'config' is not authorative anymore since that version
		$options = $self->_getconfig_idx5();
	} elsif(open(CONFIG, "<" . $self->{LIST_NAME} . "/config")) { 
		# 'config' contains the authorative information
		while(<CONFIG>) {
			if (/^F:-(\w+)/) {
				$options = $1;
			} elsif (/^(\d):(.+)$/) {
				my $opt_num = $1;
				my $value = $2;
				$options .= " -$opt_num '$value'" if ($value =~ /\S/);
			}
		}
		close CONFIG;
	} else {
		# Try manually - this will ignore all string settings, that can only be found
		# in the config file
		$options = $self->_getconfigmanual(); 
	}

	($self->_seterror(-1, 'unable to read configuration in getconfig()') && return undef) unless (defined($options));   

	$self->_seterror(undef);
	return $options;
}

# == Return the name of the current list ==
sub thislist {
	my($self) = shift;
	$self->_seterror(undef);
	return $self->{'LIST_NAME'};
}

# == Set the current mailing list ==
sub setlist {
	my($self, $list) = @_;
	if ($list =~ m/^([\w\d\_\-\.\/\@]+)$/) {
		$list = $1;
		if (-e "$list/lock") {
			$self->_seterror(undef);
			return $self->{'LIST_NAME'} = $list;
		} else {
			$self->_seterror(-1, "$list does not appear to be a valid list in setlist()");
			return undef;
		}
	} else {
		$self->_seterror(-1, "$list contains tainted data in setlist()");
		return undef;
	}
}

# == Output the subscribers to $stream ==
sub list {
	my($self, $stream, $part) = @_;
	$stream = *STDOUT unless (defined($stream));
	if(defined($part)) {
		print $stream $self->subscribers($part); 
	} else {
		print $stream $self->subscribers;
	}
}

# == Return an array of subscribers ==
sub subscribers {
	my($self, $part) = @_;
	my(@subscribers);
	($self->_seterror(-1, 'must setlist() before returning subscribers()') && return undef) unless(defined($self->{'LIST_NAME'}));
	if(defined($part) && $part) {
		($self->_seterror(-1, "$part part of $self->{'LIST_NAME'} does not appear to exist in subscribers()") && return undef) unless(-e "$self->{'LIST_NAME'}/$part");
		@subscribers = map { s/[\r\n]// && $_ } sort `$EZMLM_BASE/ezmlm-list $self->{'LIST_NAME'}/$part`;
	} else {
		@subscribers = map { s/[\r\n]// && $_ } sort `$EZMLM_BASE/ezmlm-list $self->{'LIST_NAME'}`;
	}

	if($?) {
		$self->_seterror($?, 'error during ezmlm-list in subscribers()'); 
		return (scalar @subscribers ? @subscribers : undef);
	} else {
		$self->_seterror(undef);
		return @subscribers;   
	}
}

# == Subscribe users to the current list ==
sub sub {
	my($self, @addresses) = @_;
	($self->_seterror(-1, 'sub() must be called with at least one address') && return 0) unless @addresses;
	my($part) = pop @addresses unless ($#addresses < 1 or $addresses[$#addresses] =~ /\@/);
	my($address); 
	($self->_seterror(-1, 'must setlist() before sub()') && return 0) unless(defined($self->{'LIST_NAME'}));

	if(defined($part) && $part) {
		($self->_seterror(-1, "$part of $self->{'LIST_NAME'} does not appear to exist in sub()") && return 0) unless(-e "$self->{'LIST_NAME'}/$part");
		foreach $address (@addresses) {
			next unless $self->_checkaddress($address);
			system("$EZMLM_BASE/ezmlm-sub", "$self->{'LIST_NAME'}/$part", $address) == 0 || 
            ($self->_seterror($?) && return undef);
		}
	} else {
		foreach $address (@addresses) {
			next unless $self->_checkaddress($address);
			system("$EZMLM_BASE/ezmlm-sub", $self->{'LIST_NAME'}, $address) == 0 ||
            ($self->_seterror($?) && return undef);
		}
	}
	$self->_seterror(undef);
	return 1;
}

# == Unsubscribe users from a list == 
sub unsub {
	my($self, @addresses) = @_;
	($self->_seterror(-1, 'unsub() must be called with at least one address') && return 0) unless @addresses;
	my($part) = pop @addresses unless ($#addresses < 1 or $addresses[$#addresses] =~ /\@/);
	my($address); 
	($self->_seterror(-1, 'must setlist() before unsub()') && return 0) unless(defined($self->{'LIST_NAME'}));

	if(defined($part) && $part) {
		($self->_seterror(-1, "$part of $self->{'LIST_NAME'} does not appear to exist in unsub()") && return 0) unless(-e "$self->{'LIST_NAME'}/$part");
		foreach $address (@addresses) {
			next unless $self->_checkaddress($address);
			system("$EZMLM_BASE/ezmlm-unsub", "$self->{'LIST_NAME'}/$part", $address) == 0 || 
            ($self->_seterror($?) && return undef);
		}   
	} else {
		foreach $address (@addresses) {
			next unless $self->_checkaddress($address);
			system("$EZMLM_BASE/ezmlm-unsub", $self->{'LIST_NAME'}, $address) == 0 || 
            ($self->_seterror($?) && return undef);
		}   
	}
	$self->_seterror(undef);
	return 1;
}

# == Test whether people are subscribed to the list ==
sub issub {
	my($self, @addresses) = @_;
	my($part) = pop @addresses unless ($#addresses < 1 or $addresses[$#addresses] =~ /\@/);
	my($address, $issub); $issub = 1; 
	($self->_seterror(-1, 'must setlist() before issub()') && return 0) unless(defined($self->{'LIST_NAME'}));

	local $ENV{'SENDER'};

	if(defined($part) && $part) {
		($self->_seterror(-1, "$part of $self->{'LIST_NAME'} does not appear to exist in issub()") && return 0) unless(-e "$self->{'LIST_NAME'}/$part");
		foreach $address (@addresses) {
			$ENV{'SENDER'} = $address;
			undef($issub) if ((system("$EZMLM_BASE/ezmlm-issubn", "$self->{'LIST_NAME'}/$part") / 256) != 0)
		}   
	} else {
		foreach $address (@addresses) {
			$ENV{'SENDER'} = $address;
			undef($issub) if ((system("$EZMLM_BASE/ezmlm-issubn", $self->{'LIST_NAME'}) / 256) != 0)
		}   
	}

	$self->_seterror(undef);
	return $issub;
}

# == Is the list posting moderated ==
# DEPRECATED: useless - you should better check the appropriate config flag
sub ismodpost {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before ismodpost()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/modpost"; 
}

# == Is the list subscriber moderated ==
# DEPRECATED: useless - you should better check the appropriate config flag
sub ismodsub {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before ismodsub()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/modsub"; 
}

# == Is the list remote adminable ==
# DEPRECATED: useless - you should better check the appropriate config flag
sub isremote {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before isremote()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/remote"; 
}

# == Does the list have a kill list ==
# DEPRECATED: useless - you should better check the appropriate config flag
sub isdeny {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before isdeny()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/deny"; 
}

# == Does the list have an allow list ==
# DEPRECATED: useless - the allow list is always created automatically
sub isallow {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before isallow()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/allow"; 
}

# == Is this a digested list ==
# DEPRECATED: useless - you should better check the appropriate config flag
sub isdigest {
	my($self) = @_;
	($self->_seterror(-1, 'must setlist() before isdigest()') && return 0) unless(defined($self->{'LIST_NAME'}));
	$self->_seterror(undef);
	return -e "$self->{'LIST_NAME'}/digest"; 
}

# == retrieve file contents ==
sub getpart {
	my($self, $part) = @_;
	my(@contents, $content);
	# check for the file in the list directory first
	my $filename = $self->{'LIST_NAME'} . "/$part";
	# check for default file in config directory, if necessary
	# BEWARE: get_config_dir and get_lang may _not_ cause an eternal loop :)
	$filename = $self->get_config_dir() . '/' . $self->get_lang() . "/$part"
		if (!(-e "$filename") && (get_version() >= 5) &&
			($part ne 'conf-etc') && ($part ne 'conf-lang'));
	if (open(PART, "<$filename")) {
		while(<PART>) {
			unless ( /^#/ ) {
				chomp($contents[$#contents++] = $_);
				$content .= $_;
			}
		}
		close PART;
		if(wantarray) {
			return @contents;
		} else {
			return $content;
		}
	} ($self->_seterror($?) && return undef);
}

# == set files contents ==
sub setpart {
	my($self, $part, @content) = @_;
	my($line);
	if(open(PART, ">$self->{'LIST_NAME'}/$part")) {
		foreach $line (@content) {
			$line =~ s/[\r]//g; $line =~ s/\n$//;
			print PART "$line\n";
		}
		close PART;
		return 1;
	} ($self->_seterror($?) && return undef);
}

# == get the configuration directory for this list (idx >= 5.0) ==
# return '/etc/ezmlm' for idx < 5.0
sub get_config_dir {
	my $self = shift;
	my $conf_dir;
	if ((get_version() >= 5) && (ref $self) && (-e "$self->{'LIST_NAME'}/conf-etc")) {
		chomp($conf_dir = $self->getpart('conf-etc'));
	} else {
		$conf_dir = '/etc/ezmlm';
	}
	return $conf_dir;
}

# == set the configuration directory for this list (idx >= 5.0) ==
# return without error for idx < 5.0
sub set_config_dir {
	my ($self, $conf_dir) = @_;
	return (0==0) if (get_version() < 5);
	$self->setpart('conf-etc', "$conf_dir");
}


# == get list of available languages (for idx >= 5.0) ==
# return empty list for idx < 5.0
sub get_available_languages {
	my $self = shift;
	my @langs = ();
	return @langs if (get_version() < 5);

	$self->_seterror(undef) if (ref $self);

	# check for language directories
	my $conf_dir;
	if (ref $self) {
		($self->_seterror(-1, 'could not retrieve configuration directory') && return 0)
			unless ($conf_dir = $self->get_config_dir());
	} else {
		$conf_dir = get_config_dir();
	}
	if (opendir DIR, "$conf_dir") {
		my @dirs;
		@dirs = grep !/^\./, readdir DIR;
		closedir DIR;
		my $item;
		foreach $item (@dirs) {
			push (@langs, $item) if (-e "$conf_dir/$item/text");
		}
		return @langs;
	} else {
		$self->_seterror(-1, 'could not access configuration directory') if (ref $self);
		return undef;
	}
}


# == get the selected language of the list (idx >= 5.0) ==
# return empty string for idx < 5.0
sub get_lang {
	my ($self) = shift;
	my $lang;
	return '' if (get_version() < 5);
	if (-e "$self->{'LIST_NAME'}/conf-lang") {
		chomp($lang = $self->getpart('conf-lang'));
	} else {
		$lang = 'default';
	}
	return $lang;
}


# == set the selected language of the list (idx >= 5.0) ==
# return without error for idx < 5.0
sub set_lang {
	my ($self, $lang) = @_;
	return (0==0) if (get_version() < 5);
	if (($lang eq 'default') || ($lang eq '')) {
		return 1 if (unlink "$self->{'LIST_NAME'}/conf-lang");
	} else {
		return 1 if ($self->setpart('conf-lang', "$lang"));
	}
	return 0;
}


# == get the selected charset of the list ==
# return default value (us-ascii) if no charset is specified
sub get_charset {
	my ($self) = shift;
	my $charset;
	$charset = $self->getpart('charset');
	$charset = '' unless defined($charset);
	# default if no 'charset' file exists
	$charset = 'us-ascii' if ($charset eq '');
	return $charset;
}


# == set the selected charset of the list (idx >= 5.0) ==
# remove list' specific charset file, if the default charset of the current language
# was chosen
sub set_charset {
	my ($self, $charset) = @_;
	# first: remove current charset
	unlink "$self->{'LIST_NAME'}/charset";
	# second: get default value of the current language
	my $default_charset = $self->getpart('charset');
	# last: create new charset file only if the selected charset is not the default anyway
	if (($charset eq $default_charset) || ($charset !~ /\S/)) {
		# do not write the specific charset, as the default charset of the language is
		# sufficient
		return 1;
	} else {
		return 1 if ($self->setpart('charset', "$charset"));
	}
	return 0;
}


# == get list of available text files ==
sub get_available_text_files {
	my ($self) = shift;
	my @files;
	my $item;
	my %seen = ();
	
	# customized text files of this list (idx >= 5.0)
	# OR text files of this list (idx < 5.0)
	if (opendir DIR, "$self->{'LIST_NAME'}/text") {
		my @local_files = grep !/^\./, readdir DIR;
		closedir DIR;
		foreach $item (@local_files) {
			unless ($seen{$item}) {
				push (@files, $item);
				$seen{$item} = 1;
			}
		}
	}

	# default text files (only idx >= 5.0)
	if (get_version() >= 5) {
		my $dirname = $self->get_config_dir . '/' . $self->get_lang() . '/text';
		$dirname = $self->get_config_dir . '/default/text' unless (-e $dirname);
		if (opendir GLOBDIR, $dirname) {
			my @global_files = grep !/^\./, readdir GLOBDIR;
			closedir GLOBDIR;
			foreach $item (@global_files) {
				unless ($seen{$item}) {
					push (@files, $item);
					$seen{$item} = 1;
				}
			}
		}
	}

	if ($#files > 0) {
		return @files;
	} else {
		$self->_seterror(-1, 'no textfiles found');
		return undef;
	}
}

# == get text file content ==
sub get_text_content {
	my ($self, $textfile) = @_;

	if (-e "$self->{'LIST_NAME'}/text/$textfile") {
		return $self->getpart("text/$textfile");
	} elsif (get_version() >= 5) {
		my $filename = $self->get_config_dir() . '/' . $self->get_lang() . "/text/$textfile";
		$filename = "/etc/ezmlm/default/$textfile" unless (-e "$filename");
		my @contents;
		my $content;
		if (open(PART, "<$filename")) {
			while(<PART>) {
				chomp($contents[$#contents++] = $_);
				$content .= $_;
			}
			close PART;
			if(wantarray) {
				return @contents;
			} else {
				return $content;
			}
		} else {
			$self->_seterror($?, "could not open $filename");
			return undef;
		}
	} else {
		$self->_seterror(-1, "could not get the text file ($textfile)");
		return undef;
	}
}


# == set text file content ==
sub set_text_content {
	my ($self, $textfile, @content) = @_;
	mkdir "$self->{'LIST_NAME'}/text" unless (-e "$self->{'LIST_NAME'}/text");
	return 1 if ($self->setpart("text/$textfile", @content));
	return 0;
}


# == check if specified text file is customized or default (for idx >= 5.0) ==
# return whether the text file exists in the list's directory (false) or not (true)
# empty filename returns false
sub is_text_default {
	my ($self, $textfile) = @_;
	return (0==1) if ($textfile eq '');
	if (-e "$self->{'LIST_NAME'}/text/$textfile") {
		return (1==0);
	} else {
		return (0==0);
	}
}


# == remove non-default text file (for idx >= 5.0) ==
# return without error for idx < 5
# otherwise: remove customized text file from the list's directory
sub reset_text {
	my ($self, $textfile) = @_;
	return if (get_version() < 5);
	return if ($textfile eq '');
	return if ($textfile =~ /[^\w_\.-]/);
	return if ($self->is_text_default($textfile));
	($self->_seterror(-1, "could not remove customized text file ($textfile)") && return 0)
		unless unlink("$self->{'LIST_NAME'}/text/$textfile");
	return 1;
}


# == return an error message if appropriate ==
sub errmsg {
	my($self) = @_;
	return $self->{'ERRMSG'};
}

sub errno {
	my($self) = @_;
	return $self->{'ERRNO'};
}

# == Test the compatiblity of the module ==
# return 0 for a valid version
# return the version string for an invalid version
sub check_version {
	my $self = shift;
	my $version = `$EZMLM_BASE/ezmlm-make -V 2>&1`;
	$self->_seterror(undef) if (ref $self);

	# ezmlm-idx is necessary
	if (get_version() >= 4) {
		return 0;
	} else {
		return $version;
	}
}

# == get the major ezmlm version ==
# return values:
#	0	=> unknown version
# 	3	=> ezmlm v0.53
# 	4	=> ezmlm-idx v0.4*
# 	5	=> ezmlm-idx v5.0
# 	5.1	=> ezmlm-idx v5.1
# 	6	=> ezmlm-idx v6.*
# 	7	=> ezmlm-idx v7.*
sub get_version {
	my ($ezmlm, $idx);
	my $version = `$EZMLM_BASE/ezmlm-make -V 2>&1`;

	$version = $1 if ($version =~ m/^[^:]*:\s+(.*)$/);
	$ezmlm = $1 if ($version =~ m/ezmlm-([\d\.]+)$/);
	$idx = $1 if ($version =~ m/ezmlm-idx-([\d\.]+)$/);

	if (defined($ezmlm)) {
		return 3;
	} elsif (defined($idx)) {
		if (($idx =~ m/^(\d)/) && ($1 >= 7)) {
			# version 6.0 or higher
			return 7;
		} elsif (($idx =~ m/^(\d)/) && ($1 == 6)){
		    return 6;
		} elsif (($idx =~ m/^(\d)\.(\d)/) && ($1 >= 5) && ($2 == 1)) {
			# version 5.1
			return 5.1;
		} elsif (($idx =~ m/^(\d)/) && ($1 >= 5)) {
			# version 5.0
			return 5;
		} elsif (($idx =~ m/^0\.(\d)/) && ($1 >= 0)) {
			# version 0.4xx
			return 4;
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

# == Create SQL Database tables if defined for a list ==
sub createsql {
	my($self) = @_;

	($self->_seterror(-1, 'MySQL must be compiled into Ezmlm for createsql() to work') && return 0)  unless(defined($MYSQL_BASE) && $MYSQL_BASE);
	($self->_seterror(-1, 'must setlist() before isdigest()') && return 0) unless(defined($self->{'LIST_NAME'}));
	my($config) = $self->getconfig();

	if($config =~ m/-6\s+'(.+?)'\s*/){
		my($sqlsettings) = $1;
		my($host, $port, $user, $password, $database, $table) = split(':', $sqlsettings, 6);

		($self->_seterror(-1, 'error in list configuration while trying createsql()') && return 0) 
			unless (defined($host) && defined($port) && defined($user) 
            && defined($password) && defined($database) && defined($table));

		system("$EZMLM_BASE/ezmlm-mktab -d $table | $MYSQL_BASE/mysql -h$host -P$port -u$user -p$password -f $database") == 0 ||
		($self->_seterror($?) && return undef);

	} else {
		$self->_seterror(-1, 'config for thislist() must include SQL options');
		return 0;
	}

	($self->_seterror(undef) && return 1);

}


# == Internal function to set the error to return ==
sub _seterror {
	my($self, $no, $mesg) = @_;

	if(defined($no) && $no) {
		if($no < 0) {
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

# == Internal function to test for valid email addresses ==
sub _checkaddress {
	my($self, $address) = @_;
	return 1 unless defined($address);
	return 0 unless ($address =~ m/^(\S+\@\S+\.\S+)$/);
	$_[1] = $1;
	return 1;
}

# == Internal function to work out a list configuration (idx >= v5.0) ==
sub _getconfig_idx5 {
	my($self) = @_;
	my ($options, %optionfiles);
	my ($file, $opt_num, $temp);

	# read flag file (available since ezmlm-idx 5.0.0)
	chomp($options = $self->getpart('flags'));
	# remove prefixed '-'
	$options =~ s/^-//;

	# since ezmlm-idx v5, we have to read the config
	# values from different files
	# first: preset a array with "filename" and "option_number"
	%optionfiles = (
		'sublist', 0,
		'fromheader', 3,
		'tstdigopts', 4,
		'owner', 5,
		'sql', 6,
		'modpost', 7,
		'modsub', 8,
		'remote', 9);
	while (($file, $opt_num) = each(%optionfiles)) {
		if (-e "$self->{'LIST_NAME'}/$file") {
			chomp($temp = $self->getpart($file));
			$temp =~ m/^(.*)$/m;	# take only the first line
			$temp = $1;
			# the 'owner' setting can be ignored if it is a path (starts with '/')
			unless (($opt_num == 5) && ($temp =~ m#^/#)) {
				$options .= " -$opt_num '$temp'" if ($temp =~ /\S/);
			}
		}
	}

	return $options;
}

# == Internal function to work out a list configuration manually (idx < v5.0.0 ) ==
sub _getconfigmanual {
	# use this function for strange lists without
	# 'config' (idx < v5.0) and 'flags' (idx >= v5.0)
	my($self) = @_;
	my ($savedollarslash, $options, $manager, $editor, $i);

	# Read the whole of DIR/editor and DIR/manager in
	$savedollarslash = $/;
	undef $/;
	# $/ = \0777;

	open (EDITOR, "<$self->{'LIST_NAME'}/editor") || ($self->_seterror($?) && return undef);
	open (MANAGER, "<$self->{'LIST_NAME'}/manager") || ($self->_seterror($?) && return undef);
	$editor = <EDITOR>; $manager = <MANAGER>;
	close(EDITOR), close(MANAGER);

	$/ = $savedollarslash;
   
	$options = '';
	$options .= 'a' if (-e "$self->{'LIST_NAME'}/archived");
	$options .= 'd' if (-e "$self->{'LIST_NAME'}/digest");
	$options .= 'f' if (-e "$self->{'LIST_NAME'}/prefix");
	$options .= 'g' if ($manager =~ /ezmlm-get -\w*s/ );
	$options .= 'i' if (-e "$self->{'LIST_NAME'}/indexed");
	$options .= 'k' if (-e "$self->{'LIST_NAME'}/blacklist" || -e "$self->{'LIST_NAME'}/deny");
	$options .= 'l' if ($manager =~ /ezmlm-manage -\w*l/ );
	$options .= 'm' if (-e "$self->{'LIST_NAME'}/modpost");
	$options .= 'n' if ($manager =~ /ezmlm-manage -\w*e/ );
	$options .= 'p' if (-e "$self->{'LIST_NAME'}/public");
	$options .= 'q' if ($manager =~ /ezmlm-request/ );
	$options .= 'r' if (-e "$self->{'LIST_NAME'}/remote");
	$options .= 's' if (-e "$self->{'LIST_NAME'}/modsub");
	$options .= 't' if (-e "$self->{'LIST_NAME'}/text/trailer");
	$options .= 'u' if (($options !~ /m/ && $editor =~ /ezmlm-issubn \'/ )
                      || $editor =~ /ezmlm-gate/ );
	$options .= 'x' if (-e "$self->{'LIST_NAME'}/extra" || -e "$self->{'LIST_NAME'}/allow");

	# Add the unselected options too
	# but we will skip invalid options (any of 'cevz')
	foreach $i ('a' .. 'z') {
		$options .= uc($i) unless (('cevz' =~ /$i/) || ($options =~ /$i/i))
	}
   
	# there is no way to get the other string settings, that are only
	# defined in 'config' - sorry ...
   
	return $options;
}

# == Internal Function to try to determine the vhost user ==
sub _getvhostuser {
	my($self, $hostname) = @_;
	my($username);

	open(VD, "<$QMAIL_BASE/control/virtualdomains") || ($self->_seterror($?) && return undef);
	while(<VD>) {
		last if(($username) = /^\s*$hostname:(\w+)$/);
	}
	close VD;

	return $username;
}

# == Internal function to work out default host name ==
sub _getdefaultdomain {
	my($self) = @_;
	my($hostname);

	open (GETHOST, "<$QMAIL_BASE/control/defaultdomain") 
		|| open (GETHOST, "<$QMAIL_BASE/control/me") 
		|| ($self->_seterror($?) && return undef);
	chomp($hostname = <GETHOST>);
	close GETHOST;

	return $hostname;
}

1;
__END__

=head1 NAME

Ezmlm - Object Methods for Ezmlm Mailing Lists

=head1 SYNOPSIS

 use Mail::Ezmlm;
 $list = new Mail::Ezmlm;
 
The rest is a bit complicated for a Synopsis, see the description.

=head1 ABSTRACT

Ezmlm is a Perl module that is designed to provide an object interface to
the ezmlm mailing list manager software. See the ezmlm web page
(http://www.ezmlm.org/) for a complete description of the software.

This version of the module is designed to work with ezmlm version 0.53.
It is fully compatible with ezmlm's IDX extensions (version 0.4xx and 5.0 ). Both
of these can be obtained via anon ftp from ftp://ftp.ezmlm.org/pub/patches/

=head1 DESCRIPTION

=head2 Setting up a new Ezmlm object:

   use Mail::Ezmlm;
   $list = new Mail::Ezmlm;
   $list = new Mail::Ezmlm('/home/user/lists/moolist');

=head2 Changing which list the Ezmlm object points at:
 

   $list->setlist('/home/user/lists/moolist');

=head2 Getting a list of current subscribers:

=item Two methods of listing subscribers is provided. The first prints a list
of subscribers, one per line, to the supplied FILEHANDLE. If no filehandle is
given, this defaults to STDOUT. An optional second argument specifies the
part of the list to display (mod, digest, allow, deny). If the part is
specified, then the FILEHANDLE must be specified.

   $list->list;
   $list->list(\*STDERR);
   $list->list(\*STDERR, 'deny');

=item The second method returns an array containing the subscribers. The
optional argument specifies which part of the list to display (mod, digest,
allow, deny).

   @subscribers = $list->subscribers;
   @subscribers = $list->subscribers('allow');

=head2 Testing for subscription:

   $list->issub('nobody@on.web.za');
   $list->issub(@addresses);
   $list->issub(@addresses, 'mod');

issub() returns 1 if all the addresses supplied are found as subscribers 
of the current mailing list, otherwise it returns undefined. The optional
argument specifies which part of the list to check (mod, digest, allow,
deny).

=head2 Subscribing to a list:

   $list->sub('nobody@on.web.za');
   $list->sub(@addresses);
   $list->sub(@addresses, 'digest');

sub() takes a LIST of addresses and subscribes them to the current mailing list.
The optional argument specifies which part of the list to subscribe to (mod,
digest, allow, deny).


=head2 Unsubscribing from a list:

   $list->unsub('nobody@on.web.za');
   $list->unsub(@addresses);
   $list->unsub(@addresses, 'mod');

unsub() takes a LIST of addresses and unsubscribes them (if they exist) from the
current mailing list. The optional argument specifies which part of the list
to unsubscribe from (mod, digest, allow, deny).


=head2 Creating a new list:

   $list->make(-dir=>'/home/user/list/moo',
         -qmail=>'/home/user/.qmail-moo',
         -name=>'user-moo',
         -host=>'on.web.za',
         -user=>'onwebza',
         -switches=>'mPz');

make() creates the list as defined and sets it to the current list. There are
three variables which must be defined in order for this to occur; -dir, -qmail and -name.

=over 6

=item -dir is the full path of the directory in which the mailing list is to
be created.

=item -qmail is the full path and name of the .qmail file to create.

=item -name is the local part of the mailing list address (eg if your list
was user-moo@on.web.za, -name is 'user-moo').

=item -host is the name of the host that this list is being created on. If
this item is omitted, make() will try to determine your hostname. If -host is
not the same as your hostname, then make() will attempt to fix DIR/inlocal for
a virtual host.

=item -user is the name of the user who owns this list. This item only needs to
be defined for virtual domains. If it exists, it is prepended to -name in DIR/inlocal.
If it is not defined, the make() will attempt to work out what it should be from
the qmail control files.

=item -switches is a list of command line switches to pass to ezmlm-make(1).
Note that the leading dash ('-') should be ommitted from the string.

=back

make() returns the value of thislist() for success, undefined if there was a
problem with the ezmlm-make system call and 0 if there was some other problem.

See the ezmlm-make(1) man page for more details

=head2 Determining which list we are currently altering:

   $whichlist = $list->thislist;
   print $list->thislist;

=head2 Getting the current configuration of the current list:

   $list->getconfig;

getconfig() returns a string that contains the command line switches that
would be necessary to re-create the current list. It does this by reading the
DIR/config file (idx < v5.0) or DIR/flags (idx >= v5.0) if one of them exists.
If it can't find these files it attempts to work things out for itself (with
varying degrees of success). If both these methods fail, then getconfig()
returns undefined.

   $list->ismodpost;
   $list->ismodsub;
   $list->isremote;
   $list->isdeny;
   $list->isallow;

The above five functions test various features of the list, and return a 1
if the list has that feature, or a 0 if it doesn't. These functions are
considered DEPRECATED as their result is not reliable. Use "getconfig" instead.

=head2 Updating the configuration of the current list:

   $list->update('msPd');

update() can be used to rebuild the current mailing list with new command line
options. These options can be supplied as a string argument to the procedure.
Note that you do not need to supply the '-' or the 'e' command line switch.

   @part = $list->getpart('headeradd');
   $part = $list->getpart('headeradd');
   $list->setpart('headerremove', @part);

getpart() and setpart() can be used to retrieve and set the contents of
various text files such as headeradd, headerremove, mimeremove, etc.

=head2 Manage language dependent text files

   $list->get_available_text_files;
   $list->get_text_content('sub-ok');
   $list->set_text_content('sub-ok', @content);

These functions allow you to manipulate the text files, that are used for
automatic replies by ezmlm.

   $list->is_text_default('sub-ok');
   $list->reset_text('sub-ok');

These two functions are available if you are using ezmlm-idx v5.0 or higher.
is_text_default() checks, if there is a customized text file defined for this list.
reset_text() removes the customized text file from this list. Ezmlm-idx will use
system-wide default text file, if there is no customized text file for this list.

=head2 Change the list's settings (for ezmlm-idx >= 5.0)

   Mail::Ezmlm->get_config_dir;
   $list->get_config_dir;
   $list->set_config_dir('/etc/ezmlm-local');

These functions access the file 'conf-etc' in the mailing list's directory. The
static function (first example) always returns the default configuration directory
of ezmlm-idx (/etc/ezmlm).

   $list->get_available_languages;
   $list->get_lang;
   $list->set_lang('de');
   $list->get_charset;
   $list->set_charset('iso-8859-1:Q');

These functions allow you to change the language of the text files, that are used
for automatic replies of ezmlm-idx (since v5.0 the configured language is stored
in 'conf-lang' within the mailing list's directory). Customized files (in the 'text'
directory of a mailing list directory) override the default language files.
Empty strings for set_lang() and set_charset() reset the setting to its default value.

=head2 Get the installed version of ezmlm

   Mail::Ezmlm->get_version;

The result is one of the following:
 0   - unknown
 3   - ezmlm 0.53
 4   - ezmlm-idx 0.4xx
 5   - ezmlm-idx 5.x
 5.1 - ezmlm-idx 5.1
 6   - ezmlm-idx 6.x
 7   - ezmlm-idx 7.x

=head2 Creating MySQL tables:

   $list->createsql();

Currently only works for MySQL.

createsql() will attempt to create the table specified in the SQL connect
options of the current mailing list. It will return an error if the current
mailing list was not configured to use SQL, or is Ezmlm was not compiled
with MySQL support. See the MySQL info pages for more information.

=head2 Checking the Mail::Ezmlm and ezmlm version numbers

The version number of the Mail::Ezmlm module is stored in the variable
$Mail::Ezmlm::VERSION. The compatibility of this version of Mail::Ezmlm
with your system installed version of ezmlm can be checked with

   $list->check_version();

This returns 0 for compatible, or the version string of ezmlm-make(2) if
the module is incompatible with your set up.

=head1 RETURN VALUES

All of the routines described above have return values. 0 or undefined are
used to indicate that an error of some form has occoured, while anything
>0 (including strings, etc) are used to indicate success.

If an error is encountered, the functions

   $list->errno();
   $list->errmsg();

can be used to determine what the error was. 

errno() returns;  0  or undef if there was no error.
                 -1  for an error relating to this module.
                 >0  exit value of the last system() call.

errmsg() returns a string containing a description of the error ($! if it
was from a system() call). If there is no error, it returns undef.

For those who are interested, in those sub routines that have to make system
calls to perform their function, an undefined value indicates that the
system call failed, while 0 indicates some other error. Things that you would
expect to return a string (such as thislist()) return undefined to indicate 
that they haven't a clue ... as opposed to the empty string which would mean
that they know about nothing :)

=head1 AUTHOR

 Guy Antony Halse <guy-ezmlm@rucus.net>
 Lars Kruse <devel@sumpfralle.de>

=head1 BUGS

 There are no known bugs.

 Please report bugs to the author or use the bug tracking system at
 https://systemausfall.org/trac/ezmlm-web.

=head1 SEE ALSO

 ezmlm(5), ezmlm-make(2), ezmlm-sub(1), 
 ezmlm-unsub(1), ezmlm-list(1), ezmlm-issub(1)

 http://rucus.ru.ac.za/~guy/ezmlm/
 https://systemausfall.org/toolforge/ezmlm-web
 http://www.ezmlm.org/
 http://www.qmail.org/

=cut
