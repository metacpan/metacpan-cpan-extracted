#!perl

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use My::Manager;
eval { 
  My::Manager->add_plugins(
    Partition => { key => 'type' },
    Partition => { key => 'id' },
  );
};
is $@, "", "no error from adding plugins";

my $dir = "/tmp";
my $mgr = My::Manager->new({
  root   => $dir,
  schema => 'My::Schema',
  context => my $arg = {},
});

eval { $mgr->path };
like $@, qr/missing partition key: type/, "error from missing key";

%$arg = (type => 'apple');
eval { $mgr->path };
like $@, qr/missing partition key: id/, "error from missing key";

%$arg = (type => 'apple', id => 17, extra => 'flavor');
is $mgr->path, "$dir/apple/17", "correct partitioned path";
