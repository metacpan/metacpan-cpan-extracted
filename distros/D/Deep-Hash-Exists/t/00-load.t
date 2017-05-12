#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'Deep::Hash::Exists' ) || print "'Deep::Hash::Exists' isn't ok!\n"; }
BEGIN { use_ok( 'Scalar::Util' ) || print "'Scalar::Util' isn't ok\n"; }

# diag( "Testing Deep::Hash::Exists $Deep::Hash::Exists::VERSION, Perl $], $^X" );
# diag( "Testing Scalar::Util $Scalar::Util::VERSION, Perl $], $^X" );
