#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";


plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
plan tests => 2;

pod_coverage_ok( 'Mail::SimpleList' => {
	also_private => [ qr/address_field/, qr/^command_/, qr/^reply$/, qr/^storage_class/ ],
	});
pod_coverage_ok( 'Mail::SimpleList::Alias' => { also_private => [ qr/^is_true$/] } );
