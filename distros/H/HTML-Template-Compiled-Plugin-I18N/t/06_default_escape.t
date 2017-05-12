#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;
BEGIN {
    eval 'use HTML::Entities';
    plan skip_all => "HTML::Entities required for testing ESCAPE=HTML; $EVAL_ERROR" if $EVAL_ERROR;
    eval 'use URI::Escape';
    plan skip_all => "URI::Escape required for testing ESCAPE=URI; $EVAL_ERROR" if $EVAL_ERROR;
    plan tests => 9 + 1;
}
use Test::NoWarnings;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init();

my @data = (
    {
        test           => 'default escape HTML',
        default_escape => 'HTML',
        template       => '<%TEXT VALUE="text<1>"%>',
        result         => 'text=text&lt;1&gt;',
    },
    {
        test           => 'escape 0',
        default_escape => 'HTML',
        template       => '<%TEXT VALUE="text<2>" ESCAPE=0%>',
        result         => 'text=text<2>',
    },
    {
        test           => 'escape URI',
        default_escape => 'HTML',
        template       => '<%TEXT VALUE="text<3>" ESCAPE=UrI%>',
        result         => 'text=text%3C3%3E',
    },
    {
        test           => 'escape DUMP',
        default_escape => 'HTML',
        template       => '<%TEXT VALUE="text<4>" ESCAPE=DuMp%>',
        result         => "text=\$VAR1 = 'text<4>';\n",
    },
    {
        test           => 'escape DUMP|HTML',
        default_escape => 'HTML',
        template       => '<%TEXT VALUE="text<5>" ESCAPE=DuMp|HtMl%>',
        result         => "text=\$VAR1 = &#39;text&lt;5&gt;&#39;;\n",
    },
    {
        test           => 'default escape JS|HTML',
        default_escape => 'Js|HtMl',
        template       => q{<%TEXT VALUE="text<'6'>"%>},
        result         => q{text=text&lt;\&#39;6\&#39;&gt;},
    },
    {
        test           => 'escape URI',
        default_escape => 'Js|HtMl',
        template       => q{<%TEXT VALUE="text<7>" ESCAPE=UrI%>},
        result         => q{text=text%3C7%3E},
    },
);

for my $data (@data) {
    my $htc = HTML::Template::Compiled->new(
        tagstyle       => [qw(-classic -comment +asp)],
        plugin         => [qw(HTML::Template::Compiled::Plugin::I18N)],
        default_escape => $data->{default_escape},
        scalarref      => \$data->{template},
    );
    if ( exists $data->{params} ) {
        $htc->param( %{ $data->{params} } );
    }
    is(
        $htc->output(),
        $data->{result},
        $data->{test},
    );
}