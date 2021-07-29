use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;

tie my %h, 'IPC::Shareable', {key => 'hash', create => 1, destroy => 1};

$h{a} = {z => 26, y => {1 => 2}};
$h{b} = 12;
$h{c} = {m => {3 => 3}};
$h{c}->{n} = 3;
<>;

print Dumper \%h;

IPC::Shareable->clean_up_all;
