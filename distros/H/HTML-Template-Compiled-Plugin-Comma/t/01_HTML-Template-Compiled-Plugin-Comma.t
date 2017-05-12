# $Id: 01_HTML-Template-Compiled-Plugin-Comma.t 2 2007-07-08 06:18:31Z hagy $
use Test::More tests => 4;
use blib;
use HTML::Template::Compiled;
BEGIN { use_ok('HTML::Template::Compiled::Plugin::Comma') };

#########################

my $htc = HTML::Template::Compiled->new(
    scalarref => \qq{<TMPL_VAR costs ESCAPE=COMMA>},
    plugin    => [qw(HTML::Template::Compiled::Plugin::Comma)],
);

$htc->param( costs => 10000 );
my $out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{10,000},
    "Simple commify test"
);


$htc->param( costs => 10000.12345 );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{10,000.12345},
    "commify float number"
);


$htc->param( costs => 1000000000 );
$out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{1,000,000,000},
    "commify large number"
);
