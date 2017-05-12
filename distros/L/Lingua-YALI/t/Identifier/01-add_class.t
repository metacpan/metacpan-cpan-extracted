use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use File::Basename;

BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

dies_ok { $identifier->add_class("a") } "model is missing";
dies_ok { $identifier->add_class("a", "nonexisting_file") } "nonexisting file";

is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 0, "already added class was added");