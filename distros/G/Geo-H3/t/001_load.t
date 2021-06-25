use strict;
use warnings;
use Test::More tests => 4;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 4 unless $lib;

  require_ok 'Geo::H3';
  require_ok 'Geo::H3::Base';
  require_ok 'Geo::H3::Geo';
  require_ok 'Geo::H3::Index';

}
