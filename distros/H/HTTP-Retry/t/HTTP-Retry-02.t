use warnings;

use Test::More tests => 4;

use HTTP::Retry qw(http);

my $resp1 = http('url' => "http://www.cpan.org/");
is($resp1->{status} , 200);

my $resp2 = http('url' => "http://www.cpan.org/", 'timeout' => 5, 'retry' => 3, 'sleep' => 1);
like($resp2->{content}, qr/Comprehensive Perl Archive Network/);

my $resp3 = http("http://www.cpan.org/");
is($resp3->{status} , 200);
like($resp3->{content}, qr/Comprehensive Perl Archive Network/);
