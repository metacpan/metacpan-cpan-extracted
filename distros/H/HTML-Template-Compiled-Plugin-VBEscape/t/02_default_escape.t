#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::VBEscape');
}

my $htc = HTML::Template::Compiled->new(
    tagstyle       => [qw(-classic -comment +asp)],
    plugin         => [qw(HTML::Template::Compiled::Plugin::VBEscape)],
    default_escape => 'VB',
    scalarref      => \<<'EOT');
<script language="VBScript"><!--
    string1 = "<%= attribute ESCAPE=0%>"
    string2 = "<%= cdata%>"
    string3 = "<%= undef%>"
'--></script>
EOT
$htc->param(
    attribute => 'foo "bar"',
    cdata     => 'text "with" double quotes',
    undef     => undef,
);
is $htc->output(), <<'EOT', 'escape VB script';
<script language="VBScript"><!--
    string1 = "foo "bar""
    string2 = "text ""with"" double quotes"
    string3 = ""
'--></script>
EOT
;