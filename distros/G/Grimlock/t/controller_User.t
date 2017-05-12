use strict;
use warnings;
use Test::More;
use HTTP::Request::Common qw(DELETE);
use Test::WWW::Mechanize::PSGI;
use FindBin qw( $Bin );
use lib "$Bin/../t/lib";
use Data::Dumper;
use Test::DBIx::Class qw(:resultsets);


BEGIN { 
  $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' 
}

BEGIN { 
  $ENV{DBIC_TRACE} = 1;
  $ENV{CATALYST_CONFIG} = "t/grimlock_web_test.conf"
}

use Grimlock::Web;
# create role records
fixtures_ok 'basic'
  => 'installed the basic fixtures from configuration files';

my $mech = Test::WWW::Mechanize::PSGI->new( 
  app =>  Grimlock::Web->psgi_app(@_),
  cookie_jar => {}
);

# create a user
my $res = $mech->post('/user', 
  Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    name => 'herpy',
    password => 'derp',
    email   => 'herp@derp.com'
  }
);
ok $res->is_success;

# retrieve created user
$mech->get_ok('/user/herpy');

# retrieve user listing
$mech->get_ok('/users' );

# logout since creating a user logs us in
$mech->get_ok('user/logout');

# attempt to update a user without authing
ok !($mech->put( '/user/herpy',
  Content_Type => 'application/x-www-form-urlencoded',
  Content => 'name=fartnuts'  
)->is_success), "should fail since we aren't logged in";

# login
$mech->post('/user/login',
  Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    name => 'herpy',
    password => 'derp',
  }
);

ok $mech->success, "login works";

# update a user (authenticated)
ok $mech->put( '/user/herpy',
  Content_Type => 'application/x-www-form-urlencoded',
  Content => 'name=fartnuts'  
)->is_success;

# get updated user, verify content is correct
$mech->get_ok('/user/fartnuts');
diag $mech->content;
$mech->content_contains("fartnuts");

# delete user, unauthenticated
$mech->get_ok('/user/logout');
ok !( $mech->request ( DELETE "/user/fartnuts" )->is_success ), "deleted user doesn't work without auth";

# delete, now authed
$mech->post('/user/login',
  Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    name => 'fartnuts',
    password => 'derp'
  }
);
ok $mech->success;


$mech->post('/forgot_password', 
   Content_Type => 'application/x-www-form-urlencoded',
   Content => {
     email => 'herp@derp.com'
   }
);

ok $mech->success, "post to forgot password action works";
my @deliveries = Email::Sender::Simple->default_transport->deliveries;
ok scalar @deliveries > 0, "there was an actual delivery";

ok $mech->request ( DELETE "/user/fartnuts" )->is_success, "deleting works"; 
done_testing();
