use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;
use URI::Escape;

require 't/test-psgi-lib.pm';

init(
    'Lemonldap::NG::Handler::PSGI',
    {
        locationRules   => {},
        exportedHeaders => {},
        https           => undef,
        port            => undef,
        maintenance     => undef,
    }
);

my $res;

ok( $res = $client->_get('/'), 'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 302,     'Code is 302' )          or explain( $res->[0], 302 );

my $conf;
eval {
    local $/ = undef;
    open my $file, 't/lmConf-1.json' or die $!;
    $conf = JSON::from_json(<$file>);
    close $file;
};
fail $@ if $@;
$conf->{vhostOptions} = {
    'test1.example.com' => {
        vhostHttps => 1,
        vhostPort  => 443,
    },
};
Lemonldap::NG::Handler::Main->configReload($conf);
fail $@ if $@;
ok( $res = $client->_get('/'), 'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 302,     'Code is 302' )          or explain( $res->[0], 302 );
my %h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com/?url='
      . uri_escape( encode_base64( 'https://test1.example.com/', '' ) ),
    'Redirection points to portal and site is https'
  )
  or explain(
    \%h,
    'Location => http://auth.example.com/?url='
      . uri_escape( encode_base64( 'https://test1.example.com/', '' ) )
  );

count(7);
done_testing( count() );
clean();
