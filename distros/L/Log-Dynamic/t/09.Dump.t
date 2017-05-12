#!perl

use strict;
use warnings;

use Carp;
use Test::More tests => 1;
use Log::Dynamic;

my $file  = 'test.log';
my $log   = Log::Dynamic->open (
	file  => $file,
	mode => 'append',
);

my $data = {
	foo => "O'RLY?",
	bar => [qw/I can has cheezburger ?/],
};

$log->dump({data => $data});
$log->close;

open FH, '<', $file or croak "$0: $!";
(my $dump = join '', <FH>) =~ s/\s+//g;
close FH;

like($dump, qr/DUMP.*Begin.*dump.*cheezburger.*RLY\?.*END.*dump/ixms, 'Valid data dump');

unlink $file;

__END__
vim:set syntax=perl:
