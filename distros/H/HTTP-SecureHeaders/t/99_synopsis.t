use Test2::V0;
use Test2::Require::Module 'Plack::Util';

use HTTP::SecureHeaders;
use Plack::Util;

my $secure_headers = HTTP::SecureHeaders->new(
    'content_security_policy' => "default-src 'self' https:",
);

my $data = [];
my $headers = Plack::Util::headers($data);

$secure_headers->apply($headers);

is +{ @$data }, {
    'Content-Security-Policy'           => "default-src 'self' https:",
    'Strict-Transport-Security'         => 'max-age=631138519',
    'X-Content-Type-Options'            => 'nosniff',
    'X-Download-Options'                => 'noopen',
    'X-Frame-Options'                   => 'SAMEORIGIN',
    'X-Permitted-Cross-Domain-Policies' => 'none',
    'X-XSS-Protection'                  => '1; mode=block',
    'Referrer-Policy'                   => 'strict-origin-when-cross-origin',
};

done_testing;
