#! perl
use Test::More 'no_plan';

BEGIN { use_ok('File::Finder') }

isa_ok(my $f = File::Finder->new, "File::Finder");

{
  my $r;
  $f->eval(sub {$r += 2})->as_wanted->();
  is($r, 2, 'core eval');
}

{
  my $r;
  $f
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'core true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'core false');
}

{
  my $r;
  $f->or
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'core skipping');
}

{
  my $r;
  $f->true
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'explicit true');
}

{
  my $r;
  $f->false
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'explicit false');
}

{
  my $r;
  $f->not->true
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'not true = false');
}

{
  my $r;
  $f->not->false
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'not false = true');
}

{
  my $r;
  $f->not->not->true
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'not not true = true');
}

{
  my $r;
  $f->not->not->false
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'not not false = false');
}

{
  my $r;
  $f->or
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'true OR ... = skipping');
}

{
  my $r;
  $f->false->or
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'false OR ... = true');
}

{
  my $r;
  $f->or->or
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'skipping OR ... = skipping');
}

{
  my $r;
  $f
    ->left->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'true () = true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->left->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'false () = false');
}

{
  my $r;
  $f->or
    ->left->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'skipping () = skipping');
}

{
  my $r;
  $f
    ->left
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, 2, 'true ( ... = true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->left
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'false ( ...  = skipping');
}

{
  my $r;
  $f->or
    ->left
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'skipping ( ... = skipping');
}

{
  my $r;
  $f
    ->left->true->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'true ( true ) = true');
}

{
  my $r;
  $f
    ->left->false->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'true ( false ) = false');
}

{
  my $r;
  $f
    ->left->or->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'true ( skipping ) = true');
}

{
  my $r;
  $f->false
    ->left->true->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'false ( true ) = false');
}

{
  my $r;
  $f->false
    ->left->false->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'false ( false ) = false');
}

{
  my $r;
  $f->false
    ->left->or->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'false ( skipping ) = false');
}

{
  my $r;
  $f->or
    ->left->true->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'skipping ( true ) = skipping');
}

{
  my $r;
  $f->or
    ->left->false->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'skipping ( false ) = skipping');
}

{
  my $r;
  $f->or
    ->left->or->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, undef, 'skipping ( skipping ) = skipping');
}

{
  my $r;
  $f->not
    ->left->true->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'not ( true ) = false');
}

{
  my $r;
  $f->not
    ->left->false->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'not ( false ) = true');
}

{
  my $r;
  $f->not
    ->left->or->right
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 1, 'not ( skipping ) = false');
}

{
  my $r;
  $f->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'true , = true');
}

{
  my $r;
  $f->false
    ->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'false , = true');
}

{
  my $r;
  $f->or->true
    ->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->as_wanted->();
  is($r, 2, 'skipping , = true');
}

{
  my $r;
  $f
    ->left
    ->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, 2, 'true ( true , ... = true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->left
    ->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'false ( true , ...  = skipping');
}

{
  my $r;
  $f->or
    ->left
    ->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'skipping ( true , ... = skipping');
}

{
  my $r;
  $f
    ->left
    ->false->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, 2, 'true ( false , ... = true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->left
    ->false->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'false ( false , ...  = skipping');
}

{
  my $r;
  $f->or
    ->left
    ->false->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'skipping ( false , ... = skipping');
}

{
  my $r;
  $f
    ->left
    ->or->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, 2, 'true ( skipping , ... = true');
}

{
  my $r;
  $f->eval(sub { 0 })
    ->left
    ->or->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'false ( skipping , ...  = skipping');
}

{
  my $r;
  $f->or
    ->left
    ->or->comma
    ->eval(sub {$r += 2})->or->eval(sub {$r += 1})
      ->right
      ->as_wanted->();
  is($r, undef, 'skipping ( skipping , ... = skipping');
}
