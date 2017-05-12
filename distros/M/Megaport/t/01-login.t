use strict;

use Megaport;
use Test::More;

plan skip_all => 'MEGAPORT_TOKEN must be set' unless $ENV{MEGAPORT_TOKEN};

isa_ok my $mp = Megaport->new(
  token => $ENV{MEGAPORT_TOKEN}
), 'Megaport';

done_testing;
