#!perl -T

use strict;
use warnings;

use Test::More;
use LWP::UserAgent;

sub get_url {
  my $url = shift;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);
  $ua->env_proxy;
  my $response = $ua->get($url);
  return $response;
}

my $api_url = 'http://testwiki.exotica.org.uk/mediawiki/api.php';

my $response = get_url($api_url);

if ($response->is_success) {
  plan tests => 11;
} else {
  plan skip_all => "Can't access $api_url to run tests";
}

use_ok( 'MediaWiki::API' );
my $mw = MediaWiki::API->new( { api_url => $api_url }  );
isa_ok( $mw, 'MediaWiki::API' );
$mw->{config}->{upload_url} = 'http://testwiki.exotica.org.uk/wiki/Special:Upload';

my $ref;
ok ( $ref = $mw->api( {
  action => 'query',
  meta => 'siteinfo'
  } ),
  '->api siteinfo call'
  );

is ( $ref->{query}->{general}->{server}, 'http://testwiki.exotica.org.uk', '->api siteinfo server' );

ok ( $mw->api( {
  action => 'query',
  list => 'allcategories'
  } ),
  '->list allcategories'
  );

my $time = time;
my $title = 'apitest/' . $time;
my $content = "* Version: $MediaWiki::API::VERSION\n\nthe quick brown fox jumps over the lazy dog";
ok ( $mw->edit( {
  action => 'edit',
  title => $title,
  text => $content,
  summary => 'MediaWiki::API Test suite - edit page',
  bot => 1
  } ),
  '->edit ' . $title
  );

ok ( $ref = $mw->get_page( { title => $title } ), "->get_page $title call" );

is ( $ref->{'*'}, $content, "->get_page $title content" );

ok ( $mw->edit( {
  action => 'move',
  from => $title,
  to  => $title . '-moved',
  summary => 'MediaWiki::API Test suite - move page',
  bot => 1
  } ),
  '->edit action=move ' . $title 
  );

$title = $title . '-moved';
ok ( $mw->edit( {
  action => 'delete',
  title => $title,
  summary => 'MediaWiki::API Test suite - delete page',
  bot => 1
  } ),
  '->edit action=delete ' . $title
  );

$title = "apitest - $time.png";
ok ( $mw->edit( {
  action => 'upload',
  filename => $title,
  comment => 'MediaWiki::API Test suite - upload image',
  file => [ 't/testimage.png'],
  ignorewarnings => 1,
  bot => 1
  } ),
  "->edit action=upload $title"
  );

done_testing();

