use strict;
use Test::More;
use File::Compressible;

*c = \&File::Compressible::compressible;

ok( c('application/x-perl') );
ok( c('text/plain') );
ok( !c('image/jpeg') );
ok( !c('audio/mpeg') );
ok( c('message/rfc822') );
ok( !c('application/gzip') );
ok( !c('application/x-rar-compressed') );

done_testing;
