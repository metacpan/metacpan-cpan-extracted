#!perl
package IPC_Run3_Shell_Testlib;
use warnings;
use strict;

=head1 Synopsis

Supporting library for IPC::Run3::Shell tests.

=head1 Author, Copyright, and License

Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use base 'Exporter';
our @EXPORT = qw/ $AUTHOR_TESTS $DEVEL_COVER output_is warns /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{IPC_RUN3_SHELL_AUTHOR_TESTS};
our $DEVEL_COVER = exists $INC{'Devel/Cover.pm'};

$IPC::Run3::Shell::DEBUG = Test::More->builder->output if $AUTHOR_TESTS;

use Test::More import=>[qw/ ok diag /];

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1,@_);
	return;
}

# Test::Output doesn't work for us, so here's a quick replacement
use Capture::Tiny 'capture';
sub output_is (&$$;$) {  ## no critic (ProhibitSubroutinePrototypes)
	my ($code, $exp_out, $exp_err, $name) = @_;
	my ($got_out, $got_err) = capture \&$code;
	my $rv = ok $got_out eq $exp_out && $got_err eq $exp_err, $name;
	unless ($rv) {
		diag "STDOUT: expected '$exp_out', got '$got_out'" unless $got_out eq $exp_out;
		diag "STDERR: expected '$exp_err', got '$got_err'" unless $got_err eq $exp_err;
	}
	return $rv;
}

# capture warnings
sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return wantarray ? @warns : scalar @warns;
}


1;
