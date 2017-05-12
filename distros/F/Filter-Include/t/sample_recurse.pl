#include 't/sample.pl'

$::sample_recurse = 'I am a string';
{
  ok(1 => "test worked in sample recurse file");
}
