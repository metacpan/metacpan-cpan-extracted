use Test2::V0 -no_srand => 1;
use FFI::C::FFI qw( malloc memset memcpy_addr );

imported_ok 'malloc';
imported_ok 'memset';
imported_ok 'memcpy_addr';

my $ptr = malloc(100);
is $ptr, match qr/^[0-9]+$/, 'malloc';

done_testing;
