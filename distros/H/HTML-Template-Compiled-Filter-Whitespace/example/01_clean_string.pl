#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled::Filter::Whitespace qw(whitespace_filter);

my $unclean_html = <<'EOT';
<html>
    <title>Title</title>
    <body>
        top body text
        <span>
            in

            span
        </span>
        <pre>
P
  R
    E
        </pre>
        <textarea>
text
     area
         </textarea>
     </body>
</html>
EOT

{
    local $HTML::Template::Compiled::Filter::Whitespace::DEBUG = 1;
    () = print "Filter swichted temporary off.\n",
          "------------------------------\n",
          whitespace_filter($unclean_html),
          "\n";
}
() = print "filtered\n",
      "--------\n",
      whitespace_filter($unclean_html),
      "\n";

# $Id$
