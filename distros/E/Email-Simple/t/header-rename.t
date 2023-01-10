use v5.12.0;
use warnings;

use Test::More tests => 3;

use Email::Simple::Header;

sub header ($) { Email::Simple::Header->new($_[0]); }
sub normal ($) { my $s = $_[0]; $s =~ s/\x0d\x0a/\n/g; $s }

subtest "basic renaming" => sub {
  my $head = header <<'END_HEADER';
Foo: F1
fOO: F2
bar: B1
FoO: F3
Baz: Z1
BAR: B2
END_HEADER

  $head->header_raw_set('Bar', qw( B1A B2A ));
  $head->header_rename('Foo', 'XYZ');
  $head->header_rename('XYZ', 'ZZZ');
  $head->header_rename('Bar', 'AAA');

  my $want = <<'END_HEADER';
ZZZ: F1
ZZZ: F2
AAA: B1A
ZZZ: F3
Baz: Z1
AAA: B2A
END_HEADER

  my $have = normal $head->as_string;

  is($have, $want, "header has been updated as expected");
};

subtest "nth header renaming" => sub {
  my $head = header <<'END_HEADER';
Foo: F1
fOO: F2
bar: B1
FoO: F3
Baz: Z1
BAR: B2
END_HEADER

  {
    my $ok = eval { $head->header_rename('Foo', 'XYZ', -1) };
    my $error = $@;
    like($error, qr/negative header index/, "can't use negative index");
  }

  {
    my $ok = eval { $head->header_rename('Foo', 'XYZ', 3) };
    my $error = $@;
    like($error, qr/3 exceeds/, "can't use too-large");
  }

  $head->header_rename('Foo', 'Two', 2);
  $head->header_rename('Foo', 'One', 1);
  $head->header_rename('Foo', 'Zero', 0);

  my $want = <<'END_HEADER';
Zero: F1
One: F2
bar: B1
Two: F3
Baz: Z1
BAR: B2
END_HEADER

  my $have = normal $head->as_string;

  is($have, $want, "header has been updated as expected");
};

subtest "wrapping-related things" => sub {
  my $input = <<'END_HEADER';
Foo: Wrapped
  Needlessly
Foo: Not wrapped, but may need wrapping if the field name becomes long.
Foo: Wrapped, and will generally need to be wrapped again, if the field
  name stays long.
END_HEADER

  my $head = header $input;

  is(normal $head->as_string, $input, 'round-trip works as expected');

  $head->header_rename('Foo', 'The-Field-Formerly-Known-As-Foo');

my $expect = <<'END_HEADER';
The-Field-Formerly-Known-As-Foo: Wrapped Needlessly
The-Field-Formerly-Known-As-Foo: Not wrapped, but may need wrapping if the
 field name becomes long.
The-Field-Formerly-Known-As-Foo: Wrapped, and will generally need to be
 wrapped again, if the field name stays long.
END_HEADER

  is(normal $head->as_string, $expect, 'rewrapping occurred as expected');
};

done_testing;
