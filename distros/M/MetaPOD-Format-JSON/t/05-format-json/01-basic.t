use strict;
use warnings;

use Test::More;

use FindBin;
use Path::Tiny qw(path);
use MetaPOD::Assembler;

my $corpus = path($FindBin::Bin)->parent->parent->child('corpus')->child('json');

my ($expected) = {
  '01_format_basic.pm' => {
    namespace => 'Example',
    _inherits => ['Bar'],
  },
  '02_format_inherit_array.pm' => {
    namespace => 'Example',
    _inherits => [ 'Bar', 'Baz' ],
  },
  '03_format_inherit_multi.pm' => {
    namespace => 'Example',
    _inherits => [ 'Bar', 'Baz', 'Quux' ],
  },
};

my $assembler = MetaPOD::Assembler->new();

for my $child ( sort keys %{$expected} ) {
  my $file        = $corpus->child($child);
  my $result      = $assembler->assemble_file($file);
  my $result_hash = {};
  for (qw( namespace _inherits )) {
    $result_hash->{$_} = $result->$_();
  }
  is_deeply( $result_hash, $expected->{$child}, "$child contains expected data" );
}

done_testing;
