#!perl

use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/lib';
use My::Manager;
eval {
  My::Manager->schema_class('My::Schema');
};
is $@, "", "no error from adding plugins";

my $dir = "/tmp";
my $mgr = eval { My::Manager->new({
  root => $dir,
}) };
is $@, "", "no error (schema auto-supplied)";
isa_ok $mgr, "My::Manager";

is $mgr->schema, "My::Schema",
  "correct schema class";

$mgr = My::Manager->new({
  root => $dir,
  schema => 'My::Other::Schema',
});
is $mgr->schema, 'My::Other::Schema',
  "explicit schema overrides default";
