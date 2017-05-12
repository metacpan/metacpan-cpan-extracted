#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use HTML::Template::Compiled::Filter::Whitespace qw(get_whitespace_filter);

my $template = <<'EOT';
<html>
<title>title</title>
<body>
    Something
             written
                    inside
                          of
                            the
                               template.
    <%= param%>
</body>
</html>
EOT

my $htc;
{
    local $HTML::Template::Compiled::Filter::Whitespace::DEBUG = 1;
    $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        filter    => get_whitespace_filter,
        scalarref => \$template,
    );
}
$htc->param(param => "parameter \n \n         param");
() = print "Filter swichted temporary off.\n",
      "------------------------------\n",
      $htc->output,
      "\n";

$htc = HTML::Template::Compiled->new(
    tagstyle  => [ qw( -classic -comment +asp ) ],
    filter    => get_whitespace_filter,
    scalarref => \$template,
);

$htc->param(param => "parameter \n \n         param");
() = print "filtered\n",
      "--------\n",
      $htc->output,
      "\n";

# $Id$
