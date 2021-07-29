use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;

tie my %h, 'IPC::Shareable', {key => 'hash'};

print Dumper \%h;

$h{adsf} = {a => [0, 1]};

print Dumper \%h;
