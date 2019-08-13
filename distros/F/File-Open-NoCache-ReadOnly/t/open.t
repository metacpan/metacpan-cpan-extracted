#!perl -wT

use strict;
use warnings;
use autodie qw(:all);

use Test::Most tests => 9;

BEGIN {
	use_ok('File::Open::NoCache::ReadOnly');
}

my $calls = 0;

OPEN: {
	diag('Ignore redefine messages');
	my $c = 999;
	if(my $fin = new_ok('File::Open::NoCache::ReadOnly' => [
		filename => 'lib/File/Open/NoCache/ReadOnly.pm'
	])) {
		my $fd = $fin->fd();
		ok(<$fd> =~ /^package File::Open::NoCache::ReadOnly;/);
		$c = $calls;
		$fin->close();
		ok($calls == $c + 1);	# Check flush was called
		$fin->close();
		ok($calls == $c + 1);	# Close, nothing to flush

		ok(!($fin = defined(File::Open::NoCache::ReadOnly->new('/asdasd.not.notthere'))));
		ok(defined($fin = new_ok('File::Open::NoCache::ReadOnly' => [
			filename => 'lib/File/Open/NoCache/ReadOnly.pm'
		])));
		# $c = $calls;
	}
	# Doesn't always happen, which is why the close() method was added
	# ok($calls == $c + 1);	# Check flush was called when $fin goes out of scope

	diag('Ignore usage messages');

	ok(!defined(File::Open::NoCache::ReadOnly->new()));
}

sub IO::AIO::fadvise($$$$)
{
	my($fd, $start, $end, $flags) = @_;
	if($flags == IO::AIO::FADV_DONTNEED) {
		$calls++;
	}
}
