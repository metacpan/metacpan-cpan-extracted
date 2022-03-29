use strict;
use warnings;

use Test::More tests => 2;
use ReadonlyX;
use Data::Dumper;

Readonly my $TRUE => 1;

use_ok('File::Process');

my $fh = *DATA;

my ( $lines, %args ) = process_file(
  $fh,
  chomp     => $TRUE,
  keep_open => $TRUE,
);

ok( @{$lines} == 6, 'read all lines' )
  or diag( Dumper [$lines] );

__DATA__
# comment
line2
  line3 

line5
line6
