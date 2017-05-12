use strict;
use warnings;
use Test::Needs qw(MetaPOD::Format::JSON);
use Test::More tests => 7 * 3;
use Test::Fatal;
use FindBin;
use Path::Tiny qw(path);
use Path::Iterator::Rule;
use MetaPOD::Assembler;

my $root = path($FindBin::Bin)->parent()->child('lib');

my $rule = Path::Iterator::Rule->new()->name(qr/^.*.pm/);
my $it   = $rule->iter("$root");

my $assembler = MetaPOD::Assembler->new();

while ( my $file = $it->() ) {
  my $rpath  = path($file)->relative($root);
  my $module = $rpath;
  $module =~ s/.pm//;
  $module =~ s{/}{::}g;
  my $result;

  is(
    exception {
      $result = $assembler->assemble_file($file);
    },
    undef,
    'Can assemble ' . $rpath
  );
  isa_ok( $result, 'MetaPOD::Result', "$rpath yeilds a MetaPOD::Result" );
  is( $result->namespace, $module, "MetaPOD.namespace == $module from $rpath" );
}
