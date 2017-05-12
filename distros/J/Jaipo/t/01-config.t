#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
	use_ok( 'Jaipo' ) || print "Bail out!\n";
	use_ok( 'Jaipo::Config' ) || print "Bail out!\n";
}

diag( "Testing Jaipo $Jaipo::VERSION, Perl $], $^X" );

my $config = Jaipo::Config->new();
ok( $config ) ;

my $hash =$config->load_default_config;

ok( $hash->{user} );
ok( $hash->{application} );
ok( $hash->{application}->{Services} );
is( ref $hash->{application}->{Services} , 'ARRAY' );

$config->stash( $hash );

$config->set_service_option('Twitter', { username => 'ok' });
my $opt = $config->find_service_option_by_name('Twitter');
is( $opt->{username} , 'ok' );
