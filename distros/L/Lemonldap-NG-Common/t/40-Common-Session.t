# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Lemonldap::NG::Common::Session') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Temp;
my $dir = File::Temp::tempdir();

my $sessionModule  = "Apache::Session::File";
my $sessionOptions = {
    Directory     => $dir,
    LockDirectory => $dir,
};

my $session = Lemonldap::NG::Common::Session->new(
    {
        storageModule        => $sessionModule,
        storageModuleOptions => $sessionOptions,
        kind                 => "TEST",
    }

);

ok( defined $session->id, "Creation of session" );

ok( $session->kind eq "TEST", "Store session kind" );

use_ok('Lemonldap::NG::Common::Apache::Session::Generate::SHA256');

$sessionOptions->{generateModule} =
  "Lemonldap::NG::Common::Apache::Session::Generate::SHA256";

my $session2 = Lemonldap::NG::Common::Session->new(
    {
        storageModule        => $sessionModule,
        storageModuleOptions => $sessionOptions,
        kind                 => "TEST",
    }
);

ok( length $session2->id == 64, "Use SHA256 generate module" );

