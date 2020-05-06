use Test2::V0 -no_srand => 1;
use Awesome::FFI qw( Add Cosine Log );
use Capture::Tiny qw( capture );
use FFI::Go::String;

is( Add(1,2), 3 );
is( Cosine(0), 1.0 );

is(
  [capture { Log("Hello Perl!") }],
  ["Hello Perl!\n", '', 1]
);

done_testing;
