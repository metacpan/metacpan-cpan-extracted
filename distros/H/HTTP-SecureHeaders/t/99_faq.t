use Test2::V0;
use Test2::Require::Module 'Plack::Response';

use Plack::Response;
use HTTP::SecureHeaders;

my $secure_headers = HTTP::SecureHeaders->new(
    content_security_policy => undef,
);

my $res = Plack::Response->new;

$secure_headers->apply($res->headers);

is $res->header('Content-Security-Policy'), undef;

done_testing;
