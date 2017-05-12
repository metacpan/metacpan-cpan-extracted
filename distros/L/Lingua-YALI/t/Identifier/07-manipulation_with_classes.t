use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;
use File::Basename;

BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

my $l1 = $identifier->get_classes();
ok(scalar @$l1 == 0, "nothing was added ");

is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
is($identifier->add_class("b", dirname(__FILE__) . "/model.b1.gz"), 1, "new class was added");

is($identifier->add_class("b", dirname(__FILE__) . "/model.b2.gz"), 0, "class b is already added");

is($identifier->remove_class("b"), 1, "removing added class");
dies_ok { $identifier->add_class("b", dirname(__FILE__) . "/model.b2.gz") } "class b is incompatible";
is($identifier->remove_class("a"), 1, "removing added class");

# now it is empty => we can add bigram model
is($identifier->add_class("a", dirname(__FILE__) . "/model.a2.gz"), 1, "new class was added");
