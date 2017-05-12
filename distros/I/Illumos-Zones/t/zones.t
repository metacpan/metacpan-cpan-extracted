#!/usr/bin/env perl

use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Test::More tests => 3;

use_ok 'Illumos::Zones';

my $t = Illumos::Zones->new();

is (ref $t, 'Illumos::Zones', 'Instantiation');

require Data::Processor;
my $dp = Data::Processor->new($t->schema);

is (ref $dp, 'Data::Processor', 'Schema valid');

exit 0;

1;

