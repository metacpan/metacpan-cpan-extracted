use strict;
use warnings;
use FFI::TinyCC;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
my $say = $ffi->closure(sub { print $_[0], "\n" });
my $ptr = $ffi->cast('(string)->void' => 'opaque' => $say);

my $tcc = FFI::TinyCC->new;
$tcc->add_symbol(say => $ptr);

$tcc->compile_string(<<EOF);
extern void say(const char *);

int
main(int argc, char *argv[])
{
  int i;
  for(i=0; i<argc; i++)
  {
    say(argv[i]);
  }
}
EOF

my $r = $tcc->run($0, @ARGV);

exit $r;
