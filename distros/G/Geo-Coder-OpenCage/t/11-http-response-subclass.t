use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Response;

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# A custom UA can return a subclass of HTTP::Response. The module's content
# vs. is_success branches must use the same isa() check so the two stay
# consistent — otherwise the subclass takes one branch for content and the
# other for success, and a perfectly good response gets discarded.
{
    package My::HTTP::Response;
    our @ISA = ('HTTP::Response');

    package SubclassUA;
    sub new {
        my ($c, $body) = @_;
        my $r = My::HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            $body,
        );
        return bless { response => $r }, $c;
    }
    sub agent { }
    sub get   { return $_[0]->{response} }
}

my $body = q[{"status":{"code":200,"message":"OK"},"results":[{"formatted":"Berlin"}]}];

my $geocoder = Geo::Coder::OpenCage->new(
    api_key => 'dummy',
    ua      => SubclassUA->new($body),
);

my $result = $geocoder->geocode(location => "Berlin");
ok($result, 'subclass of HTTP::Response is accepted as a successful response')
    or diag('content/is_success branches diverged for the subclass');
is($result->{results}[0]{formatted}, 'Berlin', 'response body parsed correctly');

done_testing();
