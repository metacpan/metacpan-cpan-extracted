use strict;
use warnings;

use CGI::Test;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => "CGI tests not required for installation" );
}

my $FAKE_URL   = 'http://server:80/cgi';
my $CGI_DIR    = 'cgi';
my $CGI_SCRIPT = 'url-checker-service.cgi';

my $ct = CGI::Test->new(
  -base_url => $FAKE_URL,
  -cgi_dir  => $CGI_DIR,
);

my $page = $ct->GET("$FAKE_URL/$CGI_SCRIPT");
like($page->content_type, qr|application/json|, 'Content type');
is($page->header('status'), '400 Bad Request', 'headers status');
like($page->raw_content, qr/error/, 'Content');

$page = $ct->GET("$FAKE_URL/$CGI_SCRIPT?url=http://www.apple.com");
like($page->content_type, qr|application/json|, 'Content type');
is($page->header('status'), '200 OK', 'headers status');

done_testing();
