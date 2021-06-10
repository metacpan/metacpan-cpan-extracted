use warnings;
use strict;

use Data::Dumper;
use Test::More;

BEGIN { use_ok('IPC::Shareable') };

my $a = tie my $x, 'IPC::Shareable';
my $b = tie my $y, 'IPC::Shareable', {create => 1, destroy => 1};

is $a->{_key}, 0, "tie with no glue or options is IPC_PRIVATE ok";
is $b->{_key}, 0, "tie with no glue but with options is IPC_PRIVATE ok";

done_testing();
