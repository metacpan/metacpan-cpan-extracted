#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Etcd3' ) || print "Bail out!
";
}

diag( "Testing Etcd3 $Etcd3::VERSION, Perl $], $^X" );
