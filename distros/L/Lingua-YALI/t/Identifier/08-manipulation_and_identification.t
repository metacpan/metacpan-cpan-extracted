use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;
use File::Basename;

BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

my $l1 = $identifier->get_classes();
ok(scalar @$l1 == 0, "nothing was added ");

# only one class
is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
my $result1 = $identifier->identify_file(dirname(__FILE__) . '/mix01.txt');
is($result1->[0]->[0], 'a', 'Czech must be detected');

# added second class
is($identifier->add_class("b", dirname(__FILE__) . "/model.b1.gz"), 1, "new class was added");
my $result2 = $identifier->identify_file(dirname(__FILE__) . '/mix01.txt');
is($result2->[0]->[0], 'b', 'Czech must be detected');
is($result2->[1]->[0], 'a', 'Czech must be detected');

# removing second class
is($identifier->remove_class("b"), 1, "removing added class");
# now it must be identified as a class
my $result3 = $identifier->identify_file(dirname(__FILE__) . '/mix01.txt');
is($result3->[0]->[0], 'a', 'Czech must be detected');

# removing remaining class
is($identifier->remove_class("a"), 1, "removing added class");
dies_ok {$identifier->identify_file(dirname(__FILE__) . '/mix01.txt')} "no classifier is specified";


# now it is empty => we can add bigram model
is($identifier->add_class("a", dirname(__FILE__) . "/model.a2.gz"), 1, "new class was added");
my $result5 = $identifier->identify_file(dirname(__FILE__) . '/mix01.txt');
is($result5->[0]->[0], 'a', 'Czech must be detected');

is($identifier->add_class("b", dirname(__FILE__) . "/model.b2.gz"), 1, "new class was added");
my $result6 = $identifier->identify_file(dirname(__FILE__) . '/mix01.txt');
is($result6->[0]->[0], 'b', 'Czech must be detected');
is($result6->[1]->[0], 'a', 'Czech must be detected');
