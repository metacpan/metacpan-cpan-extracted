use strict;
use warnings;
use Test::More;
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
  my $rpath = path($file)->relative($root);
  $rpath =~ s/.pm//;
  $rpath =~ s{/}{::}g;
  my $result;

  subtest "$rpath" => sub {
    is(
      exception {
        $result = $assembler->assemble_file($file);
      },
      undef,
      'Can assemble ' . path($file)->relative($root)
    );
    isa_ok( $result, 'MetaPOD::Result' );
    is( $result->namespace, $rpath, "MetaPOD.namespace == $rpath" );
  };
}

done_testing;
