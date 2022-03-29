use strict;
use warnings;

use Data::Dumper;
use JSON::PP;
use ReadonlyX;
use Test::More tests => 3;

Readonly my $TRUE  => 1;
Readonly my $EMPTY => q{};

use_ok('File::Process');

my $fh    = *DATA;
my $start = tell $fh;

my ($obj) = process_file(
  $fh,
  chomp => $TRUE,
  post  => sub {

    return decode_json( join $EMPTY, @{ $_[1] } );
  }
);

ok( ref $obj, 'process - post' )
  or diag( Dumper [$obj] );

seek $fh, $start, 0;

$obj = decode_json( process_file( $fh, merge_lines => 1, chomp => 1 ) );

ok( ref $obj, 'process - merge_lines' )
  or diag( Dumper [$obj] );

__DATA__
{
  "foo" : "bar",
  "baz" : "buz"
}
