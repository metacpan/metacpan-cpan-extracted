# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More;
BEGIN { use_ok('Lemonldap::NG::Common::Conf') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h;
use File::Temp;
my $dir = File::Temp::tempdir( CLEANUP => 1 );

ok(
    $h = new Lemonldap::NG::Common::Conf( {
            type    => 'File',
            dirName => $dir,
        }
    ),
    'type => file',
);
my $count = 2;

my @test = (

    #  simple ascii
    { cfgNum => 1, test => 'ascii' },

    #  utf-8
    { cfgNum => 1, test => 'Русский' },

    #  compatible utf8/latin-1 char but with different codes
    { cfgNum => 1, test => 'éà' }
);

for ( my $i = 0 ; $i < @test ; $i++ ) {
    ok( $h->store( $test[$i] ) == 1, "Test $i is stored" )
      or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
    $count++;
    my $cfg;
    ok( $cfg = $h->load(1), "Test $i can be read" )
      or print STDERR $Lemonldap::NG::Common::Conf::msg;
    ok( $cfg->{test} eq $test[$i]->{test}, "Test $i is restored" )
      or print STDERR "Expect $cfg->{test} eq $test[$i]->{test}\n";
    $count += 2;
}

done_testing($count);
