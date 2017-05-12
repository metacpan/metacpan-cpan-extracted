use strict;
use warnings;
use Test::More tests => 1;
use File::Basename;
use File::Spec::Functions;
use ESPPlus::Storage;

my $handle;
my $db = '';
open $handle, ">", \ $db or die "Couldn't open \$db for writing: $!";

my $o = ESPPlus::Storage::Writer->new
  ( { compress_function => sub { "Nothing here" },
      handle            => $handle } );
is( ref $o,
    'ESPPlus::Storage::Writer',
    '::Write->new() isa ::Writer' );
