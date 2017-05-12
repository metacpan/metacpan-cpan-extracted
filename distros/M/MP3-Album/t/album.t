#########################

use Test::More tests => 8;
BEGIN { 
  use_ok('MP3::Album');
  use_ok('MP3::Album::Track');
  use_ok('MP3::Album::Layout');
  use_ok('MP3::Album::Layout::Fetcher');
  use_ok('MP3::Album::Layout::Fetcher::CDDB');
  use_ok('MP3::Album::Layout::Fetcher::Tag');
};

#########################

my $a = MP3::Album->new();

ok(defined($a), "Object creation");
cmp_ok(ref($a), 'eq','MP3::Album', "devem ser parvos");
