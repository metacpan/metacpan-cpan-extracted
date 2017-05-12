#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::MockObject;

use lib 't/lib';
use My::Manager;
eval { 
  My::Manager->add_plugins(
    Partition => { method => 'type' },
    Partition => { method => 'id' },
  );
};
is $@, "", "no error from adding plugins";

my $dir = "/tmp";
my $mgr = My::Manager->new({
  root   => $dir,
  schema => 'My::Schema',
  context => my $obj = Test::MockObject->new,
});

eval { $mgr->path };
like $@, qr/missing partition method: type/, "error from missing key";

$obj->set_always(type => 'apple');

eval { $mgr->path };
like $@, qr/missing partition method: id/, "error from missing key";

$obj->set_always(id => 17);
$obj->set_always(extra => 'flavor');

is $mgr->path, "$dir/apple/17", "correct partitioned path";
