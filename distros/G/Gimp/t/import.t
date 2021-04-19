use strict;
use Test::More;
our ($dir, $DEBUG);
BEGIN {
#  $Gimp::verbose = 1;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
}
use Gimp qw(:DEFAULT net_init=spawn/);

eval { Image->new(10,10,RGB); };
ok($@, 'polluting version should fail');

Gimp->import(':pollute');
ok(Image->new(10,10,RGB), 'polluting version should now work');

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
