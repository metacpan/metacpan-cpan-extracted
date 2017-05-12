use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use File::Basename;


BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "adding a class");
is($identifier->add_class("b", dirname(__FILE__) . "/model.b1.gz"), 1, "adding b class");

my $result_a = $identifier->identify_file(dirname(__FILE__) . '/aaa01.txt');
is($result_a->[0]->[0], 'a', 'Czech must be detected');
is($result_a->[1]->[0], 'b', 'Czech must be detected');

my $result_b = $identifier->identify_file(dirname(__FILE__) . '/bbb01.txt');
is($result_b->[0]->[0], 'b', 'blish must be detected');
is($result_b->[1]->[0], 'a', 'blish must be detected');
