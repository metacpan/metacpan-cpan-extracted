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
  $ENV{DBIC_TRACE} = 1;
  $ENV{CATALYST_CONFIG} = "t/grimlock_web_test.conf"
}
# must be AFTER this begin statement so that these env vars take root properly
use Grimlock::Web;

# create role records
fixtures_ok 'user'
  => 'installed the basic fixtures from configuration files';

my $mech = Test::WWW::Mechanize::PSGI->new( 
  app =>  Grimlock::Web->psgi_app(@_),
  cookie_jar => {}
);

# try to create draft without auth
$mech->post('/entry', 
  Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    title => 'test',
    body => 'derp'
  }
);

ok !$mech->success, "doesn't work for unauthed users";

# create a post authed now
$mech->post('/user/login',
  Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    name => 'herp',
    password => 'derp'
  }
);

BAIL_OUT "can't log in" unless $mech->success;

ok $mech->success, "logged in ok";

$mech->post('/entry',
 Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    title => 'test title with spaces! <script>alert("and javascript!")</script>',
    body => 'derp'
  }
);

ok $mech->success, "POST worked";
$mech->get_ok('/test-title-with-spaces-');
ok $mech->content_lacks('<script>alert("and javascript!")</script>'), "no scripts here";
ok $mech->content_contains("derp"), "content is correct";

$mech->post('/test-title-with-spaces-/reply',
 Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    title => 'reply test',
    body => 'derpen'
  }
);

$mech->post('/test-title-with-spaces-/reply',
 Content_Type => 'application/x-www-form-urlencoded',
  Content => {
    title => 'reply test another test',
    body => 'derpen'
  }
);

ok $mech->success, "reply post works ok";

$mech->request( DELETE '/test-title-with-spaces-' );
ok $mech->success, "draft deletion works";

done_testing();
