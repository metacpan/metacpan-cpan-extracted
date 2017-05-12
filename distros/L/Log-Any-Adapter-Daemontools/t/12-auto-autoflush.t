#! /usr/bin/perl

use strict;
use warnings;
use Test::More;

# Note that in order to execute under Win32 shell, we have to use double-quotes around the command,
# which means that these code snippets need to both avoid using double-quotes, and also avoid
# $variables that would get interpreted by the Unix shell.

# This could all be avoided by writing script files for each test, but this is more fun.

my $out= _run(q/ use Log::Any; use Log::Any::Adapter q{Daemontools}; Log::Any->get_logger->info(q{stdout}); print STDERR qq{stderr\n} /);
is( $out, "stdout\nstderr\n", 'default stdout gets autoflush' );

$out= _run(q/ use IO::File; use Log::Any; use Log::Any::Adapter q{Daemontools}, -init => { output => \*STDOUT }; Log::Any->get_logger->info(q{stdout}); print STDERR qq{stderr\n} /);
is( $out, "stdout\nstderr\n", 'default stdout gets autoflush when IO::File loaded' );

$out= _run(q/ use IO::File; use Log::Any; use Log::Any::Adapter q{Daemontools}, -init => { output => IO::File->new->fdopen(\*STDOUT, q{w}) }; Log::Any->get_logger->info(q{stdout}); print STDERR qq{stderr\n} /);
is( $out, "stdout\nstderr\n", 'autoflush IO::File' );

$out= _run(q/ use Log::Any; use Log::Any::Adapter q{Daemontools}, -init => { output => sub { print @_ } }; Log::Any->get_logger->info(q{stdout}); print STDERR qq{stderr\n} /);
is( $out, "stderr\nstdout\n", 'coderef can\'t be autoflushed' );

sub _run {
	my $script= shift;
	my $out= `$^X -e "$script" 2>&1`;
	diag "command exited ".($? >> 8).": $^X -e \"$script\"\n"
		if $?;
	return $out;
}

done_testing;
