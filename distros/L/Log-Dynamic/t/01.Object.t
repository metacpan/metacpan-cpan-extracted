#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Log::Dynamic;

my $file = 'test.log';

# Instantiate using open()
my $log_1 = Log::Dynamic->open (file => $file);
is(ref $log_1, 'Log::Dynamic', 'Valid instantiation with open()');

# Instantiate using new()
my $log_2 = Log::Dynamic->new (file => $file);
is(ref $log_2, 'Log::Dynamic', 'Valid instantiation with new()');

# Invalid instantiation
eval { my $log = Log::Dynamic->open };
isnt($@, undef, 'Invalid instantiation');

unlink $file;

__END__
vim:set syntax=perl:
