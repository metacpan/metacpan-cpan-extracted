use warnings;
use strict;

use Devel::Declare ();
use Test::More tests => 10;

sub my_quote($) { $_[0] }

sub my_quote_parser {
  my($declarator, $offset) = @_;
  $offset += Devel::Declare::toke_move_past_token($offset);
  $offset += Devel::Declare::toke_skipspace($offset);
  my $len = Devel::Declare::toke_scan_str($offset);
  my $content = Devel::Declare::get_lex_stuff();
  Devel::Declare::clear_lex_stuff();
  my $linestr = Devel::Declare::get_linestr();
  die "surprising len=undef" if !defined($len);
  die "surprising len=$len" if $len <= 0;
  $content =~ s/(.)/sprintf("\\x{%x}", ord($1))/seg;
  substr $linestr, $offset, $len, "(\"$content\")";
  Devel::Declare::set_linestr($linestr);
}

BEGIN {
  Devel::Declare->setup_for(__PACKAGE__, {
    my_quote => { const => \&my_quote_parser },
  });
}

my $x;

$x = my_quote[foo];
is $x, "foo";

$x = my_quote[foo
];
is $x, "foo\n";

$x = my_quote[foo
x];
is $x, "foo\nx";

$x = my_quote[foo
xy];
is $x, "foo\nxy";

$x = my_quote[foo
xyz];
is $x, "foo\nxyz";

$x = my_quote[foo
bar baz quux];
is $x, "foo\nbar baz quux";

$x = my_quote[foo
bar baz quuux];
is $x, "foo\nbar baz quuux";

$x = my_quote[foo
bar baz quuuux];
is $x, "foo\nbar baz quuuux";

$x = my_quote[foo
bar baz quux wibble];
is $x, "foo\nbar baz quux wibble";

$x = my_quote[foo
quux
womble];
is $x, "foo\nquux\nwomble";

1;
