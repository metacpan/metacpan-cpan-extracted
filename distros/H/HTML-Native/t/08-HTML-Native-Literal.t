#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::Literal" );
}

# new() with string

{
  my $raw = "<b>Hello</b>";
  my $lit = HTML::Native::Literal->new ( $raw );
  isa_ok ( $lit, "HTML::Native::Literal" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $lit, "<b>Hello</b>" );
  $raw .= " world!";
  is ( $lit, "<b>Hello</b>" );
}

# new() with reference

{
  my $raw = "<b>Hello</b>";
  my $lit = HTML::Native::Literal->new ( \$raw );
  isa_ok ( $lit, "HTML::Native::Literal" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $lit, "<b>Hello</b>" );
  $raw .= " world!";
  is ( $lit, "<b>Hello</b> world!" );
}

# Embedding

{
  my $elem = HTML::Native->new (
    div =>
    "<b>Hello</b>",
    HTML::Native::Literal->new ( "<b>Hello</b>" ),
  );
  isa_ok ( $elem, "HTML::Native" );
  isa_ok ( $elem->[1], "HTML::Native::Literal" );
  is ( $elem, "<div>&lt;b&gt;Hello&lt;/b&gt;<b>Hello</b></div>" );
}

done_testing();
