#! perl
use Test::More;

BEGIN {
  eval { require File::Find::Rule };
  plan 'skip_all' => 'No File::Find::Rule installed' if $@;
}

plan 'no_plan';

BEGIN { use_ok('File::Finder') }
isa_ok(my $f = File::Finder->new, 'File::Finder');
isa_ok(my $ffr = File::Find::Rule->new, 'File::Find::Rule');
isa_ok(my $combined = $f->ffr($ffr), 'File::Finder');

{
  my $r;
  isa_ok(my $ffr = File::Find::Rule->exec(sub { $r = 1 }), "File::Find::Rule");
  isa_ok(my $combined = $f->ffr($ffr), "File::Finder");
  ## have to simulate being called in File::Find::find;
  local $File::Find::name = "/DUM/MY";
  local $_ = "MY";
  local $File::Find::dir = "/DUM";
  $combined->as_wanted->();
  is($r, 1, "simple ffr rule ran");
}

{
  my $r;
  isa_ok(my $ffr = File::Find::Rule->exec(sub { 1 }), "File::Find::Rule");
  isa_ok(my $combined = $f->ffr($ffr), "File::Finder");
  ## have to simulate being called in File::Find::find;
  local $File::Find::name = "/DUM/MY";
  local $_ = "MY";
  local $File::Find::dir = "/DUM";
  $combined->eval(sub { $r = 1 })->as_wanted->();
  is($r, 1, "simple ffr rule returned true");
}

{
  my $r;
  isa_ok(my $ffr = File::Find::Rule->exec(sub { 0 }), "File::Find::Rule");
  isa_ok(my $combined = $f->ffr($ffr), "File::Finder");
  ## have to simulate being called in File::Find::find;
  local $File::Find::name = "/DUM/MY";
  local $_ = "MY";
  local $File::Find::dir = "/DUM";
  $combined->eval(sub { $r = 1 })->as_wanted->();
  is($r, undef, "simple ffr rule returned false");
}
