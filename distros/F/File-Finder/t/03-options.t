#! perl
use Test::More 'no_plan';

BEGIN { use_ok('File::Finder') }

isa_ok(my $f = File::Finder->new, "File::Finder");

## also tests cloning
{
  isa_ok(my $f1 = $f->depth, "File::Finder");
  ok($f1->as_options->{bydepth}, "setting bydepth");
  ok(!$f1->as_options->{follow}, "setting bydepth, follow not set");
}

{
  isa_ok(my $f1 = $f->follow, "File::Finder");
  ok($f1->as_options->{follow}, "setting follow");
  ok(!$f1->as_options->{bydepth}, "setting follow, bydepth not set");
}
