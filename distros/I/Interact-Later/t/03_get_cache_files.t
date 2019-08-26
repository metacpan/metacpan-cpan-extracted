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

my @files = $delayer->get_all_cache_files_ordered_by_date;

is scalar @files, $conf->{ amount }, "We created $conf->{amount} cache files";

$delayer->clean_cache;

my @deleted_files = $delayer->get_all_cache_files_ordered_by_date;

is scalar @deleted_files, 0, 'The cache got deleted';

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
