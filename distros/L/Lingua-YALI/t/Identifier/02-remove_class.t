use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use File::Basename;

BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
is($identifier->add_class("b", dirname(__FILE__) . "/model.b1.gz"), 1, "new class was added");

is($identifier->remove_class("a"), 1, "removing added class");
is($identifier->remove_class("a"), 0, "removing already removed class");
