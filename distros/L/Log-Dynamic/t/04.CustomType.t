#!perl

use strict;
use warnings;

use Test::More;

use Log::Dynamic;

my $file  = 'test.log';
my $log   = Log::Dynamic->open (file => $file);
my @types = qw/ foo bar baz /;

plan tests => scalar @types;

foreach my $type (@types) {
	$log->$type("Got type '$type'");
}

$log->close;
open my $fh, '<', $file or die "$0: $!\n";
my $text = join '', <$fh>;

foreach my $type (@types) {
	isnt($text =~ /$type/s, '', "Custom type '$type'");
}

close $fh;
unlink $file;

__END__
vim:set syntax=perl:
