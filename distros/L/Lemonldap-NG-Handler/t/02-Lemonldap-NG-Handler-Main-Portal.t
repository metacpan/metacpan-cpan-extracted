## Before `make install' is performed this script should be runnable with
## `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler.t'
#
##########################
#
## change 'tests => 1' to 'tests => last_test_to_print';
no warnings;
use Test::More;    #qw(no_plan)

my $numTests = 1;
plan tests => $numTests;

# get a standard basic configuration in $args hashref
use Cwd 'abs_path';
use File::Basename;
use lib dirname( abs_path $0 );

open STDERR, '>/dev/null';

##########################
#
## Insert your test code below, the Test::More module is use()ed here so read
## its man page ( perldoc Test::More ) for help writing this test script.
use_ok( 'Lemonldap::NG::Handler::Main', ':all' );

#if ( $numTests == 2 ) {
#    my $h;
#    $h = bless {}, 'Lemonldap::NG::Handler::Main';
#
#    # Portal value with $vhost
#    # $vhost -> test.example.com
#
#    # Create a fake Apache2::RequestRec
#    my $mock = Test::MockObject->new();
#    $mock->fake_module(
#        'Apache2::RequestRec' => new =>
#          sub { return bless {}, 'Apache2::RequestRec' },
#        hostname => sub { 'test.example.com' },
#    );
#    our $apacheRequest = Apache2::RequestRec->new();
#
#    my $portal = '"http://".$vhost."/portal"';
#
#    my $args = {
#         'portal' => "$portal",
#         'globalStorage' => 'Apache::Session::File',
#         'post' => {},
#    };
#    $h->globalInit($args);
#
#    ok( ( $h->portal() eq 'http://test.example.com/portal' ),
#        'Portal value with $vhost' );
#}
