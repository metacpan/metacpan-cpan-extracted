use strict;
use warnings;
use utf8;
use Test::More;
use Test::Warn;

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# Non-JSON response (e.g. proxy error page) must warn + return undef, not die
{
    package BadJSONUA;
    sub new   { bless {}, shift }
    sub agent { }
    sub get   { return { success => 0, content => '<html>502 Bad Gateway</html>' } }
}

# long-enough recognizable key so we can verify it gets masked in warnings
my $api_key  = 'abcdef1234567890fedcba0987654321';
my $geocoder = Geo::Coder::OpenCage->new(
    api_key => $api_key,
    ua      => BadJSONUA->new,
);

my $result;
my @warnings;
warnings_like {
    $result = $geocoder->geocode(location => "Berlin");
}
[qr/failed to decode response/], 'non-JSON response triggers warning';

is($result, undef, 'non-JSON response returns undef');

# API key must not appear in warning output; only the masked prefix should
@warnings = ();
{
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $geocoder->geocode(location => "Berlin");
}
my $combined = join('', @warnings);
unlike($combined, qr/\Q$api_key\E/, 'full API key is not in warning output');
like($combined,   qr/key=abcdef\.\.\./, 'masked key prefix appears in warning output');

done_testing();
