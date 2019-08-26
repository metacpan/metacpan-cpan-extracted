use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

named_captures

=usage

  my $named_captures = $result->named_captures();

=description


The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

=signature

name() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Search';

my $data = Data::Object::Search->new(['(?^:(?<var1>test))', 'best case', 1, [ '0', '0' ], [ '4', '4' ], {'var1' => [ 'test' ] }, 'test case']);

is_deeply $data->named_captures(), {var1=>['test']};

ok 1 and done_testing;
