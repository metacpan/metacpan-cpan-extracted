#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::Comment" );
}

# new() with string

{
  my $raw = "Hello";
  my $comment = HTML::Native::Comment->new ( $raw );
  isa_ok ( $comment, "HTML::Native::Comment" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $comment, "<!-- Hello -->" );
  $raw .= " world!";
  is ( $comment, "<!-- Hello -->" );
}

# new() with reference

{
  my $raw = "Hello";
  my $comment = HTML::Native::Comment->new ( \$raw );
  isa_ok ( $comment, "HTML::Native::Comment" );
  isa_ok ( \$raw, "SCALAR" );
  is ( $comment, "<!-- Hello -->" );
  $raw .= " world!";
  is ( $comment, "<!-- Hello world! -->" );
}

# Embedding

{
  my $elem = HTML::Native->new (
    div =>
    HTML::Native::Comment->new ( "Hello" ),
    "world",
  );
  isa_ok ( $elem, "HTML::Native" );
  isa_ok ( $elem->[0], "HTML::Native::Comment" );
  is ( $elem, "<div><!-- Hello -->world</div>" );
}

# Comment escaping

{
  my $comment = HTML::Native::Comment->new ( "-- bad -->" );
  isa_ok ( $comment, "HTML::Native::Comment" );
  is ( $comment, "<!-- -\\- bad -\\-&gt; -->" );
}

done_testing();
