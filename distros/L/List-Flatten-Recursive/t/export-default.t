#!perl
use Test::More;
use List::Flatten::Recursive;
no warnings;

ok( defined(&flat),
    "Export `flat' by default" );

ok( !defined(&flatten_to_listref),
    "Avoid exporting `flatten_to_listref' by default." );

done_testing();
