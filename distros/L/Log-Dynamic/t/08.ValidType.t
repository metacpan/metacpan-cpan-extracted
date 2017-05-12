#!perl

use strict;
use warnings;

use Test::More tests => 3;
use Log::Dynamic;

my $file  = 'test.log';
my $log   = Log::Dynamic->open (
	file  => $file,
	types => ['foo'],
);

# Valid
eval { $log->foo };
is($@, '', 'Using valid type');

# Invalid with default error
eval { $log->bar };
isnt($@, '', 'Using Invalid type with default error');

$log->close;

# Invalid with user defined error
$log = Log::Dynamic->open (
	file         => $file,
	types        => ['foo'],
	invalid_type => sub { die "USER DEFINED ERROR: ".(shift) },
);

eval { $log->baz };
like($@, qr/^USER DEFINED ERROR:/, 'Invalid type with user defined error');

$log->close;
unlink $file;

__END__
vim:set syntax=perl:
