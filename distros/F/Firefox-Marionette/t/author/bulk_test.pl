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
system { $^X } $^X, 'Makefile.PL' and die "Failed to $^X Makefile.PL for $ENV{FIREFOX_BINARY}";
system { 'cover' } 'cover', '-delete' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
my $path = File::Spec->catdir(File::HomeDir::my_home(), 'den');
my $handle = DirHandle->new($path) or die "Failed to find firefox den at $path";
$ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
system { 'make' } 'make', 'test' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
while(my $entry = $handle->read()) {
	next if ($entry eq File::Spec->updir());
	next if ($entry eq File::Spec->curdir());
	$ENV{FIREFOX_BINARY} = File::Spec->catfile($path, $entry, 'firefox');
	if (-e $ENV{FIREFOX_BINARY}) {
		system { 'make' } 'make', 'test' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
		my $bash_command = 'cd ' . Cwd::cwd() . '; FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . '" HARNESS_PERL_SWITCHES="' . $ENV{HARNESS_PERL_SWITCHES} . '" make test';
		warn "Remote Execution of '$bash_command'";
#		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
		$bash_command = 'cd ' . Cwd::cwd() . '; FIREFOX_VISIBLE=1 FIREFOX_BINARY="' . $ENV{FIREFOX_BINARY} . '" HARNESS_PERL_SWITCHES="' . $ENV{HARNESS_PERL_SWITCHES} . '" make test';
		warn "Remote Execution of '$bash_command'";
#		system { 'ssh' } 'ssh', 'localhost', $bash_command and die "Failed to remote cover for $ENV{FIREFOX_BINARY}"; 
	}
}
system { 'cover' } 'cover' and die "Failed to 'cover' for $ENV{FIREFOX_BINARY}";
