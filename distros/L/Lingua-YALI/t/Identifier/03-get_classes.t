use strict;
use warnings;

use Test::More tests => 23;
use Test::Exception;
use File::Basename;

BEGIN { use_ok('Lingua::YALI::Identifier') };
my $identifier = Lingua::YALI::Identifier->new();

my $l1 = $identifier->get_classes();
ok(scalar @$l1 == 0, "nothing was added ");

is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
is($identifier->add_class("b", dirname(__FILE__) . "/model.b1.gz"), 1, "new class was added");

my $l2 = $identifier->get_classes();
is( (scalar grep { /a/ } @$l2), 1, "a was added");
is( (scalar grep { /b/ } @$l2), 1, "b was added");
is( (scalar grep { /c/ } @$l2), 0, "c wasn't added");

is($identifier->remove_class("a"), 1, "removing added class");
my $l3 = $identifier->get_classes();
is( (scalar grep { /a/ } @$l3), 0, "a was removed");
is( (scalar grep { /b/ } @$l3), 1, "b was added");
is( (scalar grep { /c/ } @$l3), 0, "c wasn't added");

is($identifier->remove_class("a"), 0, "removing added class");
my $l4 = $identifier->get_classes();
is( (scalar grep { /a/ } @$l4), 0, "a was removed");
is( (scalar grep { /b/ } @$l4), 1, "b was added");
is( (scalar grep { /c/ } @$l4), 0, "c wasn't added");

is($identifier->remove_class("b"), 1, "removing added class");
my $l5 = $identifier->get_classes();
is( (scalar grep { /a/ } @$l5), 0, "a was removed");
is( (scalar grep { /b/ } @$l5), 0, "b was removed");
is( (scalar grep { /c/ } @$l5), 0, "c wasn't added");


is($identifier->add_class("a", dirname(__FILE__) . "/model.a1.gz"), 1, "new class was added");
my $l6 = $identifier->get_classes();
is( (scalar grep { /a/ } @$l6), 1, "a was added");
is( (scalar grep { /b/ } @$l6), 0, "b was added");
is( (scalar grep { /c/ } @$l6), 0, "c wasn't added");