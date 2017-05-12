#
# $Id$
#

package Gtk2::TestHelper;
use strict;
use warnings;
use Test::More;
use Carp;

our $VERSION = '0.02';

sub import
{
	shift;
	my %opts = (@_);

	plan skip_all => $opts{skip_all} if ($opts{skip_all});

	croak "tests must be provided at import" unless (exists ($opts{tests}));

	if ($opts{nowin32} && $^O eq 'MSWin32')
	{
		plan skip_all => "not appliciable on win32";
	}

	if ($opts{at_least_version})
	{
		my ($rmajor, $rminor, $rmicro, $text) = 
						@{$opts{at_least_version}};
		unless (Gtk2->CHECK_VERSION ($rmajor, $rminor, $rmicro))
		{
			plan skip_all => $text;
		}
	}

	# gtk+ 2.0.x can use X fonts, and requires a connection to the
	# display at all times; so, ignore noinit for those versions.
	delete $opts{noinit} unless Gtk2->CHECK_VERSION (2, 2, 0);

	if( $opts{noinit} || Gtk2->init_check )
	{
		plan tests => $opts{tests};
	}	
	else
	{	
		plan skip_all => 'Gtk2->init_check failed, probably '
				.'unable to open DISPLAY';
	}

	# ignore keyboard
	Gtk2->key_snooper_install (sub { 1; });

	# turn on strict and warnings in caller
	$^W = 1;
	@_ = ();
	goto &strict::import;
}

package main;

# go ahead and use Gtk2 for them.
use Gtk2;
# and obviously they'll need Test::More
use Test::More;

# encourage use of these constants in tests
use Glib qw(TRUE FALSE);


# useful wrappers
sub run_main (;&) {
	my $callback = shift;
	Glib::Idle->add (sub {
		if ($callback) {
			#print "# Entering run_main shutdown callback\n";
			$callback->();
			#print "# Leaving run_main shutdown callback\n";
		}
		Gtk2->main_quit;
		FALSE;
	});
	#print "# Entering main loop (run_main)\n";
	Gtk2->main;
	#print "# Leaving main loop (run_main)\n";
}
sub ok_idle ($;$) {
	my ($testsub, $test_name) = @_;
	run_main sub {
		# 0 Test::More::ok
		# 1 this block's ok() call
		# 2 idle callback in run_main
		# 3 Gtk2::main call in run_main
		# 4 Gtk2::main call in run_main (again)
		# 5 ok_idle
		# 6 the caller we want to print
		local $Test::Builder::Level = 6;
		ok ($testsub->(), $test_name);
	}
}
sub is_idle ($$;$) {
	my ($asub, $b, $test_name) = @_;
	run_main sub {
		local $Test::Builder::Level = 6; # see ok_idle()
		is ($asub->(), $b, $test_name);
	}
}


sub ginterfaces_ok {
	my ($object_or_package) = @_;
	my $type = ref $object_or_package || $object_or_package;
	my $i = 0;
	my @ifaces = Glib::Type->list_interfaces ($type);
	foreach my $iface (@ifaces) {
		if ($object_or_package->isa ($iface)) {
			$i++;
		} else {
			warn "GType $type is supposed to implement $iface, "
			   . "but \@type\::ISA doesn't contain $iface!\n";
		}
	}
	is ($i, scalar(@ifaces), "GInterface versus \@ISA for $type");
}


# Inspired by Test::Number::Delta
sub delta_ok ($$;$) {
	my ($a, $b, $msg) = @_;
	ok (abs ($a - $b) < 1e-6, $msg);
}


1;
__END__

=head1 NAME

Gtk2::TestHelper - Code to make testing Gtk2 and friends simpler.

=head1 SYNOPSIS

  use Gtk2::TestHelper tests => 10;

=head1 DESCRIPTION

A simplistic module that brings together code that would otherwise have to be
copied into each and every test. The magic happens during the importing process
and therefore all options are passed to the use call. The module also use's
strict, warnings, Gtk2, and Test::More so that the individual tests will not
have to. The only required option is the number of tests. The module installs a
key snooper that causes all keyboard input to be ignored.

=head1 OPTIONS

=over

=item tests

The number of tests to be completed.

=item noinit

Do not call Gtk2->init_check, assume that it is not necessary.

=item nowin32

Set to true if all tests are to be skipped on the win32 platform.

=item at_least_version

A reference to a list that is checked with Gtk2->CHECK_VERSION.

=item skip_all

Simply skip all tests with the reason provided.

=back

=head1 "EXPORTED" FUNCTIONS

This module also defines a few utility functions for use in tests; since
we already override import and pull the dirty trick of calling use in
the package main, these are defined in the package main rather than exported
by Exporter.

=over

=item run_main

=item run_main (CODEREF)

=item run_main BLOCK

Run a main loop, and stop when all pending events are handled.  This is
useful if you have a test that needs a main loop to run properly, because
it allows your program to remain noninteractive.  Important for a test
suite.

If the optional I<CODEREF> is supplied, it will be run right before killing
the mainloop.  The function is prototyped to allow two styles of invocation:

  run_main (\&some_sub);    # explicit code reference
  run_main { print "hi" };  # callback as a block

=item ok_idle (TEST_SUB [, TEST_NAME])

Run Test::Simple's ok() on the return value of I<TEST_SUB> after handling
pending events.  Implemented with C<run_main> and other special trickery.

=item is_idle (THIS_SUB, THAT [, NAME])

Like ok_idle(), but compares the return value of I<THIS_SUB> with I<THAT>
using Test::More's is().

=item ginterfaces_ok (GOBJECT_OR_PACKAGE)

Verify that the GObject subclass I<GOBJECT_OR_PACKAGE>'s @ISA is set up properly
with all of the GInterfaces that the type system claims it supports.  Something
like an isa_ok() in steroids.

=item delta_ok (A, B [, NAME])

Checks that the absolute difference of the numbers A and B is smaller than
1e-6.

=back

=head1 SEE ALSO

L<perl>(1), L<Gtk2>(3pm).

=head1 AUTHORS

The Gtk2-Perl Team.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005, 2012 by the gtk2-perl team.

LGPL, See LICENSE file for more information.
