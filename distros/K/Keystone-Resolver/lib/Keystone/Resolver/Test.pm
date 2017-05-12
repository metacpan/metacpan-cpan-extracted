# $Id: Test.pm,v 1.4 2008-04-11 12:03:30 mike Exp $

package Keystone::Resolver::Test;

use strict;
use warnings;
use IO::File;
use CGI;
use Keystone::Resolver;


=head1 NAME

Keystone::Resolver::Test - run tests for the Keystone Resolver library

=head1 SYNOPSIS

 my %opts = ( loglevel => 0x600 );
 Keystone::Resolver::Test::run_test(\%opts, "path/to/test");

=head1 DESCRIPTION

This module is not part of the resolver I<per se>, but is used to test
it.  It exists to provide a single function, C<run_test()>, described
below.

=head1 METHODS

=head2 run_test()

 Keystone::Resolver::Test::run_test(\%opts, "path/to/test");
 # -- or --
 $status = Keystone::Resolver::Test::run_test(\%opts, "path/to/test", 1);

Runs the indicated test, using a resolver created with the specified
options.  If the optional third parameter is absent or false, then
output is written describing the outcome of the test.  If it is
provided and true, then no output is generated.  In any case, an
integer status is returned as follows:

=over 4

=item 0

Success.

=item 1

The test was run without errors, but the generated XML was different
from what the test-file said to expect.

=item 2

The test could not be run because of a fatal error in the resolver.

=item 3

The test could not be run because the test-case was malformed.

=item 4

The test could not be run because of a system error.

=back

=cut

sub run_test   { return _do_test(0, @_) }

=head2 write_test()

 $status = Keystone::Resolver::Test::write_test(\%opts, "another/test", 1);

Like C<run_test()>, but instead of testing the results of running the
test against a known-good regression output, it writes the results to
that output for the use of subsequent regression testing.

=cut

sub write_test { return _do_test(1, @_) }

sub _do_test {
    my($write, $optsref, $filename, $quiet) = @_;

    my $params;
    my $fh = new IO::File("<$filename.in")
	or return fail(4, $quiet, "can't open test input '$filename.in': $!");
    while (my $line = <$fh>) {
	chomp($line);
	$line =~ s/^\s+//;
	next if $line =~ /^#/;
	next if $line =~ /^\s*$/;
	$params = $line;
	last;
    }
    $fh->close();
    return fail(3, $quiet, $filename, "malformed: no OpenURL params")
	if !defined $params;

    my $xml;
    if (!$write) {
	$fh = new IO::File("<$filename.out")
	    or return fail(4, $quiet,
			   "can't open test output '$filename.out': $!");
	$xml = join("", <$fh>);
	$fh->close();
    }

    my $cgi = new CGI($params);
    my $resolver = new Keystone::Resolver();
    my $openURL = Keystone::Resolver::OpenURL->newFromCGI($resolver, $cgi, undef,
	{ baseURL => "http://example.com/resolve", %$optsref });
    my($__UNUSED_type, $result) = $openURL->resolve();

    if ($result !~ /\n$/s) {
	# Diff has problems dealing with files that don't end in
	# newlines, so we always include a newline at the end of the
	# test-files, and append one to the generated content here if
	# necessary to make them compare equal.
	$result .= "\n";
    }

    if ($write) {
	my $res = write_file($quiet, "$filename.out", $result);
	return $res if $res != 0;
    } elsif ($result ne $xml) {
	fail(1, $quiet, $filename, "XML output differs:");
	if (!$quiet) {
	    print STDERR "---\n";
	    my $expected = "/tmp/resolver-$$.expected";
	    my $res = write_file($quiet, $expected, $xml);
	    return $res if $res != 0;
	    my $got = "/tmp/resolver-$$.got";
	    $res = write_file($quiet, $got, $result);
	    return $res if $res != 0;
	    system("diff $expected $got >&2");
	    unlink($expected);
	    unlink($got);
	    print STDERR "---\n";
	    print "Generated document:\n$result"
		if $cgi->param("opt_show_xml");
	}
	return 1;
    }

    print STDERR "test-case '$filename' ok\n"
	if !$quiet;
    return 0;
}


sub write_file {
    my($quiet, $filename, $content) = @_;

    my $fh = new IO::File(">$filename")
	or return fail(4, $quiet, "can't write file '$filename': $!");
    $fh->print($content);
    $fh->close();
    return 0;
}


sub fail {
    my($retval, $quiet, $filename, @text) = @_;

    print STDERR "*** test-case '$filename': ", @text, "\n"
	if !$quiet;

    return $retval;
}


1;
