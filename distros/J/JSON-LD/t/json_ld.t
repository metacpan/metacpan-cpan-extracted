use Test2::V0 -no_srand => 1;
use JSON::LD;
use Path::Tiny ();

my $temp = Path::Tiny->tempdir;
my $file = $temp->child('foo.json')->stringify;

is(
  DumpFile($file, { a => 1 }),
  U(),
  'Dump',
);

note(Path::Tiny->new($file)->slurp_raw);

is(
  LoadFile($file),
  { a => 1 },
  'Load',
);

done_testing;


