use strict;
use warnings;

use Test::More tests => 17;

use Expect;

my $e = Expect->new;
eval { $e->_trim_length };
like $@, qr/^No string passed/;
is $e->_trim_length('a' x 999), 'a' x 999;
is $e->_trim_length('a' x 1021), 'a' x 1021;
is $e->_trim_length('a' x 1023), '...' . 'a' x 1021;
is $e->_trim_length('a' x 1024), '...' . 'a' x 1021;
is $e->_trim_length('a' x 1025), '...' . 'a' x 1021;
is $e->_trim_length('a' x 1025, 2000), 'a' x 1025;
is $e->_trim_length('a' x 2001, 2000), 'a' x 2000;

eval { Expect::_trim_length() };
like $@, qr/^No string passed/;
is Expect::_trim_length(undef, "z" x 1020), 'z' x 1020;
is Expect::_trim_length(undef, "z" x 1021), 'z' x 1021;
is Expect::_trim_length(undef, "z" x 1022), '...' . 'z' x 1021;
is Expect::_trim_length(undef, "z" x 1024), '...' . 'z' x 1021;
is Expect::_trim_length(undef, "z" x 2000), '...' . 'z' x 1021;

is Expect::_trim_length(undef, "z" x 2000, 2000), 'z' x 2000;
is Expect::_trim_length(undef, "z" x 2000, 1999), 'z' x 1999;
is Expect::_trim_length(undef, "z" x 2000, 2001), 'z' x 2000;



