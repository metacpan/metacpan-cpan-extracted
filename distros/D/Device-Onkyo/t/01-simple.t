#!/usr/bin/perl
#
# Copyright (C) 2012 by Mark Hindess

use strict;
use Test::More tests => 6;

use_ok 'Device::Onkyo';

my $log = 't/log/simple.log';
open my $fh, $log or die "Failed to open $log: $!\n";

my $onkyo = Device::Onkyo->new(filehandle => $fh, type => 'ISCP');
ok $onkyo, 'object created';

my $msg = $onkyo->read;
is $msg, 'PWR01', '... read power on';

$msg = $onkyo->read;
is $msg, 'PWR00', '... read power off';

eval { $onkyo->read };
like $@, qr/^closed /, '... closed';

$onkyo->{type} = 'eISCP';
$onkyo->{_buf} =
  pack 'A4 N N C4 A*', 'ISCP', 0x10, 0x08, 0x1, 0x0, 0x0, 0x0, "!1PWR01\n";

$msg = $onkyo->read;
is $msg, 'PWR01', '... read eISCP';
