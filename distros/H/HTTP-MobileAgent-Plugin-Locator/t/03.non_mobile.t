use Test::More tests => 1;

use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Locator;

{
    local $ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.8.1.11) Gecko/20071127 Firefox/2.0.0.11';
    my $agent = HTTP::MobileAgent->new;
    eval { $agent->locator };
    like $@, qr/^Invalid mobile user agent:/;
}
