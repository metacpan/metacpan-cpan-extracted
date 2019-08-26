use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

count

=usage

  my $count = $result->count();

=description

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation.

=signature

count() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Search';

my $data = Data::Object::Search->new(['(?^:(test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {}, 'test case']);

is_deeply $data->count(), 1;

ok 1 and done_testing;
