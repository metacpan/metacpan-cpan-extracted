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
my $cwd = Cwd::cwd();
system { $^X } $^X, 'Makefile.PL' and die "Failed to $^X Makefile.PL for $ENV{FIREFOX_BINARY}";
system { 'cover' } 'cover', '-delete' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
system { $^X } $^X, '-MDevel::Cover', '-Ilib', 't/01-marionette.t' and die "Failed to 'make'";
my $path = File::Spec->catdir(File::HomeDir::my_home(), 'den');
my $handle = DirHandle->new($path) or die "Failed to find firefox den at $path";
my @entries;
while(my $entry = $handle->read()) {
	next if ($entry eq File::Spec->updir());
	next if ($entry eq File::Spec->curdir());
	next if ($entry =~ /[.]tar[.]bz2$/smx);
	push @entries, $entry;
}
#foreach my $entry (reverse sort { $a cmp $b } @entries) {
foreach my $entry (sort { $a cmp $b } @entries) {
	$ENV{FIREFOX_BINARY} = File::Spec->catfile($path, $entry, 'firefox');
	if (-e $ENV{FIREFOX_BINARY}) {
		system { $^X } $^X, '-MDevel::Cover', '-Ilib', 't/01-marionette.t' and die "Failed to 'make'";
		my $bash_command = 'cd ' . Cwd::cwd() . '; FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . "\" $^X -MDevel::Cover -Ilib t/01-marionette.t";
		warn "Remote Execution of '$bash_command'";
		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
		$bash_command = 'cd ' . Cwd::cwd() . '; FIREFOX_VISIBLE=1 FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . "\" $^X -MDevel::Cover -Ilib t/01-marionette.t";
		warn "Remote Execution of '$bash_command'";
		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
	}
}
chdir $cwd or die "Failed to chdir to '$cwd':$!";
system { 'cover' } 'cover' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
