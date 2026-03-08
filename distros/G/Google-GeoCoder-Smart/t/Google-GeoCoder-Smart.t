use strict;
use warnings;

use Test2::V0;
use Google::GeoCoder::Smart ();

sub _read_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "Unable to read ${path}: $!";
  local $/;
  return <$fh>;
}

my $ok_payload = _read_file('t/fixtures/geocode-ok.json');

subtest 'geocode_addr builds modern request and parses response' => sub {
  my $geo = Google::GeoCoder::Smart->new(
    key => 'test-key',
  );

  my $captured_url;
  {
    no warnings 'redefine';
    local *Google::GeoCoder::Smart::_fetch_content = sub {
      my ($self, $url) = @_;
      $captured_url = $url;
      return ($ok_payload, undef);
    };

    my $response = $geo->geocode_addr({
      address => '1600 Amphitheatre Parkway',
      city    => 'Mountain View',
      state   => 'CA',
      zip     => '94043',
      language => 'en',
    });

    is($response->{status}, 'OK', 'status is OK');
    is(scalar @{ $response->{results} }, 1, 'one result returned');
    is($response->{results}[0]{geometry}{location}{lat}, 37.422, 'latitude parsed');
    like($captured_url, qr{/maps/api/geocode/json\?}, 'uses geocode endpoint');
    like($captured_url, qr/key=test-key/, 'includes key');
    unlike($captured_url, qr/sensor=/, 'does not use deprecated sensor parameter');
  }
};

subtest 'legacy geocode wrapper still works' => sub {
  my $geo = Google::GeoCoder::Smart->new();

  {
    no warnings 'redefine';
    local *Google::GeoCoder::Smart::_fetch_content = sub {
      return ($ok_payload, undef);
    };

    my ($count, $status, @rest) = $geo->geocode(
      address => '1600 Amphitheatre Parkway',
      city    => 'Mountain View',
      state   => 'CA',
      zip     => '94043',
    );

    is($count, 1, 'legacy count returned');
    is($status, 'OK', 'legacy status returned');
    ok(@rest >= 2, 'legacy list return includes result payload and raw JSON');
  }
};

subtest 'network failures are handled without dying' => sub {
  my $geo = Google::GeoCoder::Smart->new();

  {
    no warnings 'redefine';
    local *Google::GeoCoder::Smart::_fetch_content = sub {
      return (undef, 'mock connection failure');
    };

    my $response = $geo->geocode_addr({ address => 'anywhere' });
    is($response->{status}, 'CONNECTION_ERROR', 'connection failure status returned');
    like($response->{error_message}, qr/mock connection failure/, 'error message propagated');
  }
};

subtest 'invalid request handling' => sub {
  my $geo = Google::GeoCoder::Smart->new();
  my $response = $geo->geocode_addr({});
  is($response->{status}, 'INVALID_REQUEST', 'missing input rejected');
};

done_testing();
