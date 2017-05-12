# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 10;
use IO::NestedCapture 'CAPTURE_OUT_ERR';

SKIP: {
	eval "use IO::String";
	skip "IO::String is not installed.", 10 if $@;

	my $io = IO::String->new;

	IO::NestedCapture->set_next_out($io);
	IO::NestedCapture->set_next_err($io);

	IO::NestedCapture->start(CAPTURE_OUT_ERR);
	print "agrippa\n";
	print STDERR "grunnion\n";
	print "ptolemy\n";
	print STDERR "circe\n";
	print "dumbledore\n";
	print STDERR "paracelsus\n";
	print "morgana\n";
	print STDERR "merlin\n";
	print "hengist\n";
	print STDERR "cliodna\n";
	IO::NestedCapture->stop(CAPTURE_OUT_ERR);

	$io->seek(0, 0);
	ok(<$io>, "agrippa\n");
	ok(<$io>, "ptolemy\n");
	ok(<$io>, "circe\n");
	ok(<$io>, "dumbledore\n");
	ok(<$io>, "paracelsus\n");
	ok(<$io>, "morgana\n");
	ok(<$io>, "merlin\n");
	ok(<$io>, "hengist\n");
	ok(<$io>, "cliodna\n");
	ok(<$io>, undef);
}
