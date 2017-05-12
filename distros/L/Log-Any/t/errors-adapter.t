use strict;
use warnings;
use Test::More tests => 3;
use Log::Any::Adapter;

eval { Log::Any::Adapter->set('Blah') };
like( $@, qr{Can't locate Log/Any/Adapter/Blah}, "adapter = Blah" );
eval { Log::Any::Adapter->set('+My::Adapter::Blah') };
like( $@, qr{Can't locate My/Adapter/Blah}, "adapter = +My::Adapter::Blah" );
eval { Log::Any::Adapter->set('') };
like( $@, qr{expected adapter name}, "adapter = ''" );
