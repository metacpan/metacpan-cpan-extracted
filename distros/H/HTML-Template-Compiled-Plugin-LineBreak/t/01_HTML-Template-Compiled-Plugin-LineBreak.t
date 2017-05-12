# $Id: 01_HTML-Template-Compiled-Plugin-LineBreak.t 5 2007-07-14 15:28:44Z root $
use Test::More tests => 6;
use blib;
use HTML::Template::Compiled;
BEGIN { use_ok('HTML::Template::Compiled::Plugin::LineBreak') };

#########################

my $htc = HTML::Template::Compiled->new(
    scalarref => \qq{<TMPL_VAR note ESCAPE=BR>},
    plugin    => [qw(HTML::Template::Compiled::Plugin::LineBreak)],
);

$htc->param( note => "foo1\nfoo2\n" );
my $out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{foo1<br />\nfoo2<br />\n},
    "LF test for text on UNIX"
);


$htc->param( note => "foo1\r\nfoo2\r\n" );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{foo1<br />\r\nfoo2<br />\r\n},
    "CRLF test for text on WIN"
);


$htc->param( note => "foo1\rfoo2\r" );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{foo1<br />\rfoo2<br />\r},
    "CR test for text on Mac"
);


$htc->param( note => "foo1\n\n\n" );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{foo1<br />\n<br />\n<br />\n},
    "Continued line-break test"
);


$htc = HTML::Template::Compiled->new(
    scalarref => \qq{<TMPL_VAR note ESCAPE=LINEBREAK>},
    plugin    => [qw(HTML::Template::Compiled::Plugin::LineBreak)],
);

$htc->param( note => "foo1\n" );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{foo1<br />\n},
    "Alias name test"
);
