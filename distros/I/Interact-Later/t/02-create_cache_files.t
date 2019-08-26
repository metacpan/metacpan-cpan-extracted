use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More tests => 2;
use Test::Mojo;
use Data::Printer;
use feature 'say';
use Mojo::UserAgent;
use Mojo::JSON qw/encode_json true false/;
use Interact::Later;
use Data::UUID;
use Path::Class;

my $conf = {
  amount         => 10,
  cache_path     => 't/cache',
  file_extension => '.dmp'
};

my $delayer = Interact::Later->new($conf);

for ( 1 .. $conf->{ amount } ) {
  $delayer->write_data_to_disk( get_mock_json() );
}

my $path_and_pattern = $delayer->cache_path . '*.dmp';

my @files = glob $path_and_pattern;
is scalar @files, $conf->{ amount }, "We created $conf->{amount} cache files";

$delayer->clean_cache;

my $uuid = $delayer->write_data_to_disk( get_mock_json() );
ok $uuid, 'A UUID has been returned';

$delayer->clean_cache;

sub get_mock_json {
  my $mock_json = encode_json(
    [
      {
        lots   => 'stuff',
        more   => 'things',
        active => true,
        uuid   => Data::UUID->new->create_str()
      },
      {
        lots   => 'stuff',
        more   => 'things',
        active => false,
        uuid   => Data::UUID->new->create_str()
      },
      {
        lots   => 'stuff',
        more   => 'things',
        active => true,
        uuid   => Data::UUID->new->create_str()
      },
      {
        lots   => 'stuff',
        more   => 'things',
        active => false,
        uuid   => Data::UUID->new->create_str()
      }
    ],
  );

  return $mock_json;
}
