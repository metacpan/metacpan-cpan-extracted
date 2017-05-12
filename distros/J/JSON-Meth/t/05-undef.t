#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

use JSON::Meth;

ok !defined(undef->$j), 'undefs do not cause warnings';

done_testing();

__END__