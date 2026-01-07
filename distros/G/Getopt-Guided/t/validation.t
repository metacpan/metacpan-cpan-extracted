use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT like ok plan subtest use_ok ) ], tests => 5;
use Test::Fatal qw( exception );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( getopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

like exception { $module->can( 'croakf' )->( 'message only' ) }, qr/message only/, 'croakf() without "f"';

like exception { $module->import( '_private' ) }, qr/not exported/, 'Export error';

subtest 'Validate $spec parameter' => sub {
  plan tests => 6;

  local @ARGV = ();
  my %opts;
  like exception { getopts undef, %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    'Undefined value is not allowed';
  like exception { getopts '', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    'Empty value is not allowed';
  like exception { getopts 'a:-b', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    "'-' character is not allowed";
  like exception { getopts ':a:b', %opts }, qr/\A\$spec parameter isn't a non-empty string of alphanumeric/,
    "Leading ':' character is not allowed";
  like exception { getopts 'aba:', %opts }, qr/\A\$spec parameter contains option 'a' multiple times/,
    'Same option character is not allowed';
  ok getopts( 'a:b', %opts ), 'Succeeded'
};

subtest 'Validate $opts parameter' => sub {
  plan tests => 1;

  local @ARGV = ();
  my %opts = ( a => 'foo' );
  like exception { getopts 'a:b', %opts }, qr/\A\%\$opts parameter isn't an empty hash/,
    'Result %opts hash has to be empty'
}
