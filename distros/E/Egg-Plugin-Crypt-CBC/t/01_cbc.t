use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

test();

sub test {

my $ciper= Crypt::Blowfish->require ? 'Blowfish'
         : Crypt::DES->require      ? 'DES'
         : Crypt::Camellia->require ? 'Camellia'
         : Crypt::Rabbit->require   ? 'Rabbit'
         : Crypt::Twofish2->require ? 'Twofish2'
         : return do {
	plan skip_all=> "The Ciper module is not installed.";
  };

plan tests=> 10;

ok my $e= Egg::Helper->run( Vtest => {
  vtest_plugins=> [qw/ Crypt::CBC /],
  vtest_config=> {
    plugin_crypt_cbc=> {
      cipher => $ciper,
      key    => '(abcdef)',
      },
    },
  });

my $plain_text= 'secret text';

ok my $cbc= $e->cbc, q{my $cbc= $e->cbc};
ok my $secret= $cbc->encrypt($plain_text), q{my $secret= $cbc->encrypt($plain_text)};
ok $secret ne $plain_text, q{$secret ne $plain_text};
ok my $decrypt= $cbc->decrypt($secret), q{my $decrypt= $cbc->decrypt($secret)};
ok $plain_text eq $decrypt, q{$plain_text eq $decrypt};
ok $secret= $e->cbc->encode($plain_text), q{$secret= $e->cbc->encode($plain_text)};
ok $secret ne $plain_text, q{$secret ne $plain_text};
ok $decrypt= $e->cbc->decode($secret), q{$decrypt= $e->cbc->decode($secret)};
ok $plain_text eq $decrypt, q{$plain_text eq $decrypt};

}

