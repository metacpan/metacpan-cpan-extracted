# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Mail::Builder::Simple' ); }

my $object = Mail::Builder::Simple->new();
isa_ok ($object, 'Mail::Builder::Simple');
