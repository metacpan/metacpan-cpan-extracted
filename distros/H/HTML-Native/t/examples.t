#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native" );
    use_ok ( "HTML::Native::Document" );
    use_ok ( "HTML::Native::Literal" );
    use_ok ( "HTML::Native::Comment" );
    use_ok ( "HTML::Native::JavaScript" );
}

{
  my $html = HTML::Native::Document::XHTML10::Strict->new ( "Testing" );
  push @{$html->head}, (
    HTML::Native::JavaScript->new ( { src => "script.js" } ),
  );
  push @{$html->body}, (
    [ div => { class => "error" },
      HTML::Native::Comment->new ( "This is an error" ),
      [ h1 => "Oh dear" ],
      [ img => { src => "error.png" } ],
      "Something went wrong",
    ],
    HTML::Native::Literal->new ( "<hr />" ),
    HTML::Native::JavaScript->new ( "\$(function() { alert ( \"boo!\" ); });" ),
  );
  is ( $html."\n", <<'EOF' );
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Testing</title><script src="script.js" type="text/javascript"></script></head>
<body><div class="error"><!-- This is an error --><h1>Oh dear</h1><img src="error.png" />Something went wrong</div><hr /><script type="text/javascript">//<![CDATA[
$(function() { alert ( "boo!" ); });
//]]></script></body>
</html>
EOF
}

{
  my $elem = HTML::Native->new (
    div => { class => [ qw ( error fatal ) ] },
    "Something happened",
  );
  is ( $elem, "<div class=\"error fatal\">Something happened</div>" );
  $$elem = "p";
  $elem->{class}->{fatal} = 0;
  is ( $elem, "<p class=\"error\">Something happened</p>" );
}

done_testing();
