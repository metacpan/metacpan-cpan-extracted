#! /usr/bin/perl

use strict;
use warnings;
use DirHandle();
use File::HomeDir();
use File::Spec();
use File::Temp();
use Cwd();

if (exists $ENV{COUNT}) {
	$0 = "Test run number $ENV{COUNT}";
}
$ENV{RELEASE_TESTING} = 1;
my $cwd = Cwd::cwd();
system { 'cover' } 'cover', '-delete' and die "Failed to 'cover' for " . ($ENV{FIREFOX_BINARY} || 'firefox');
system { $^X } $^X, '-MDevel::Cover', '-Ilib', 't/01-marionette.t' and die "Failed to 'make'";
{
	local $ENV{FIREFOX_HOST} = 'localhost';
	warn "Remote Firefox for " . ($ENV{FIREFOX_BINARY} || 'firefox');
	system { $^X } $^X, '-MDevel::Cover', '-Ilib', 't/01-marionette.t' and die "Failed to 'make'";
}
my $path = File::Spec->catdir(File::HomeDir::my_home(), 'den');
my $handle = DirHandle->new($path) or die "Failed to find firefox den at $path";
my @entries;
while(my $entry = $handle->read()) {
	next if ($entry eq File::Spec->updir());
	next if ($entry eq File::Spec->curdir());
	next if ($entry =~ /[.]tar[.]bz2$/smx);
	push @entries, $entry;
}
foreach my $entry (reverse sort { $a cmp $b } @entries) {
	my $entry_version;
	if ($entry =~ /^firefox\-([\d.]+)(?:esr|a\d+)?$/smx) {
		($entry_version) = ($1);
	} else {
		die "Unrecognised entry '$entry' in $path";
	}
	my $path_to_firefox = File::Spec->catfile($path, $entry, 'firefox');
	my $old_version;
	my $old_output = `$path_to_firefox --version 2>/dev/null`;
	if ($old_output =~ /^Mozilla[ ]Firefox[ ]([\d.]+)/smx) {
		($old_version) = ($1);
	} else {
		die "$path_to_firefox old '$old_output' could not be parsed";
	}
	if ($old_version ne $entry_version) {
		die "$old_version does not equal $entry_version for $path_to_firefox";
	}
}
warn "Den is correct";
foreach my $entry (reverse sort { $a cmp $b } @entries) {
	my $entry_version;
	if ($entry =~ /^firefox\-([\d.]+)(?:esr|a\d+)?$/smx) {
		($entry_version) = ($1);
	} else {
		die "Unrecognised entry '$entry' in $path";
	}
	my $path_to_firefox = File::Spec->catfile($path, $entry, 'firefox');
	my $old_version;
	my $old_output = `$path_to_firefox --version 2>/dev/null`;
	if ($old_output =~ /^Mozilla[ ]Firefox[ ]([\d.]+)/smx) {
		($old_version) = ($1);
	} else {
		die "$path_to_firefox old '$old_output' could not be parsed";
	}
	if ($old_version ne $entry_version) {
		die "$old_version does not equal $entry_version for $path_to_firefox";
	}
	$ENV{FIREFOX_BINARY} = $path_to_firefox;
	if (-e $ENV{FIREFOX_BINARY}) {
		system { $^X } $^X, '-MDevel::Cover', '-Ilib', 't/01-marionette.t' and die "Failed to 'make'";
		my $bash_command = 'cd ' . Cwd::cwd() . '; RELEASE_TESTING=1 FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . "\" $^X -MDevel::Cover -Ilib t/01-marionette.t";
		warn "Remote Execution of '$bash_command'";
		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
		$bash_command = 'cd ' . Cwd::cwd() . '; RELEASE_TESTING=1 FIREFOX_VISIBLE=1 FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . "\" $^X -MDevel::Cover -Ilib t/01-marionette.t";
		warn "Remote Execution of '$bash_command'";
		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
	}
	my $new_version;
	my $new_output = `$path_to_firefox --version 2>/dev/null`;
	if ($new_output =~ /^Mozilla[ ]Firefox[ ]([\d.]+)/smx) {
		($new_version) = ($1);
	} else {
		die "$path_to_firefox new '$new_output' could not be parsed";
	}
	if ($old_version ne $new_version) {
		die "$old_version changed to $new_version for $path_to_firefox";
	}
}
chdir $cwd or die "Failed to chdir to '$cwd':$!";
system { 'cover' } 'cover' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
