use strict;
use warnings;

use Data::Dumper;
use JSON qw(decode_json);
use Test::More tests => 3;

use lib qw(.);

use_ok('File::Process');

my $fh    = *DATA;
my $start = tell $fh;

########################################################################
subtest 'post' => sub {
########################################################################
  my ($obj) = process_file(
    $fh,
    chomp     => 1,
    keep_open => 1,
    post      => sub {

      return decode_json( join q{}, @{ $_[1] } );
    }
  );

  ok( ref $obj, 'process - post' )
    or diag( Dumper [$obj] );
};

########################################################################
subtest 'merge_lines => 1' => sub {
########################################################################
  seek $fh, $start, 0;

  my ($merged_lines) = process_file(
    $fh,
    merge_lines => 1,
    chomp       => 1
  );

  my $obj = decode_json($merged_lines);

  ok( ref $obj, 'process - merge_lines' )
    or diag( Dumper [ 'merged lines', $merged_lines, 'obj', $obj ] );
};

1;

__DATA__
{
  "foo" : "bar",
  "baz" : "buz"
}
