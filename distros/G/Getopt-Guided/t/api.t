use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT like use_ok ) ], tests => 3;
use Test::Fatal qw( exception );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  no strict 'refs'; ## no critic ( ProhibitNoStrict )
  use_ok $module, @{ "$module\::EXPORT_OK" } or BAIL_OUT "Cannot loade module '$module'!"
}

like exception { $module->can( 'croakf' )->( 'message only' ) }, qr/message only/, 'croakf() without "f"';

like exception { $module->import( 'private' ) }, qr/not exported/, 'Export error'
