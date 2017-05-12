#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ( "HTML::Native", qw ( :all ) );
}

# new()

{
  my $elem = HTML::Native->new ( hr => );
  isa_ok ( $elem, "HTML::Native" );
  isa_ok ( \$$elem, "SCALAR" );
  isa_ok ( \%$elem, "HTML::Native::Attributes" );
  isa_ok ( \@$elem, "HTML::Native::List" );
}

{
  my $elem = HTML::Native->new ( hr => );
  is ( $elem, "<hr />" );
}

{
  my $elem = HTML::Native->new ( img => { src => "logo.png", alt => "Logo" } );
  is ( $elem, "<img alt=\"Logo\" src=\"logo.png\" />" );
}

{
  my $elem = HTML::Native->new ( p => "Hello world" );
  is ( $elem, "<p>Hello world</p>" );
}

{
  my $elem = HTML::Native->new ( div => { class => "error" },
				 "Something", " ", "happened" );
  is ( $elem, "<div class=\"error\">Something happened</div>" );
}

{
  my $elem = HTML::Native->new ( div => { class => "error" },
				 "Something", " ", "happened" );
  is ( $$elem, "div" );
  is ( $elem->{class}, "error" );
  is ( @$elem, 3 );
  is ( $elem->[0], "Something" );
}

# Entity encoding

{
  my $elem = HTML::Native->new ( div => { class => "\"" },
				 "<b>Bold</b>" );
  is ( $elem, "<div class=\"&quot;\">&lt;b&gt;Bold&lt;/b&gt;</div>" );
}

# Bookmarks

{
  my $elem = HTML::Native->new (
    div =>
    [ h1 => "Welcome" ],
    "Hello world",
  );
  isa_ok ( $elem, "HTML::Native" );
  isa_ok ( $elem->[0], "HTML::Native" );
  $elem->bookmark ( "heading", $elem->[0] );
  {
    my $heading = $elem->bookmark ( "heading" );
    isa_ok ( $heading, "HTML::Native" );
    is ( $$heading, "h1" );
    is ( $heading, "<h1>Welcome</h1>" );
    @$heading = ( qw ( Hi ) );
    is ( $elem, "<div><h1>Hi</h1>Hello world</div>" );
  }
  delete $elem->[0];
  {
    my $heading = $elem->bookmark ( "heading" );
    is ( $heading, undef );
  }
}

# is_html_element()

{
  my $elem = HTML::Native->new (
    div => { class => "error" },
    [ img => { src => "logo.png" } ],
    "Something happened",
  );
  ok ( is_html_element ( $elem ) );
  ok ( is_html_element ( $elem->[0] ) );
  ok ( is_html_element ( $elem->[0], "img" ) );
  ok ( ! is_html_element ( \%$elem ) );
  ok ( ! is_html_element ( \@$elem ) );
  ok ( ! is_html_element ( $elem->[0], "div" ) );
  ok ( ! is_html_element ( $elem->[1] ) );
}

# is_html_attributes()

{
  my $elem = HTML::Native->new ( div => { class => "error" },
				 "Something happened" );
  ok ( is_html_attributes ( \%$elem ) );
  ok ( ! is_html_attributes ( $elem ) );
  ok ( ! is_html_attributes ( \@$elem ) );
  ok ( ! is_html_attributes ( $elem->[0] ) );
  ok ( ! is_html_attributes ( $elem->{class} ) );
}

# is_html_list()

{
  my $elem = HTML::Native->new ( div => { class => "error" },
				 "Something happened" );
  ok ( is_html_list ( \@$elem ) );
  ok ( ! is_html_list ( $elem ) );
  ok ( ! is_html_list ( \%$elem ) );
  ok ( ! is_html_list ( $elem->[0] ) );
  ok ( ! is_html_list ( $elem->{class} ) );
}

done_testing();
