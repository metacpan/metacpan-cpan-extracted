#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use HTML::Template::Compiled::Filter::Whitespace qw(whitespace_filter);

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

my $htc = HTML::Template::Compiled->new(
    tagstyle  => [ qw( -classic -comment +asp ) ],
    scalarref => \$template,
);
$htc->param(param => "parameter \n \n         param");
() = print whitespace_filter( $htc->output );

# $Id$
