use strict;

use Megaport;
use Test::More;

plan skip_all => 'MEGAPORT_TOKEN must be set' unless $ENV{MEGAPORT_TOKEN};

my $mp = Megaport->new(token => $ENV{MEGAPORT_TOKEN});

my @list = $mp->session->locations->list;
ok @list > 0, 'Locations->list returned more than one entry';
isa_ok $list[0], 'Megaport::Internal::_Obj';

my $eq1 = $mp->session->locations->get(id => 2);
is $eq1->name, 'Equinix SY1/SY2', 'Location->name';

my @equinix = $mp->session->locations->list(name => qr/^Equinix/);
ok($_->name =~ /^Equinix/, 'Equinix search all results matched') foreach @equinix;

done_testing;
