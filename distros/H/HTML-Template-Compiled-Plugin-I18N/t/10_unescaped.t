#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;
BEGIN {
    eval 'use HTML::Entities';
    plan skip_all => "HTML::Entities required for testing ESCAPE=HTML; $EVAL_ERROR" if $EVAL_ERROR;
    plan tests => 6 + 1;
}
use Test::NoWarnings;

use lib qw(./t/lib);

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
    use_ok('HTML::Template::Compiled::Plugin::I18N::TestTranslator');
}

HTML::Template::Compiled::Plugin::I18N->init(
    translator_class => 'HTML::Template::Compiled::Plugin::I18N::TestTranslator',
    allow_formatter => 1,
    allow_unescaped => 1,
);

my @data = (
    {
        test     => q{text as constant, escape HTML, unescaped link},
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('en');
        },
        template => q{<%TEXT VALUE="{link_begin}<link>{link_end}" UNESCAPED_link_begin="<a href='...'>" UNESCAPED_link_end="</a>" FORMATTER="Markdown" ESCAPE=HtMl%>},
        result   => q{<a href='...'>&lt;link&gt;</a>},
    },
    {
        test     => q{text as constant, escape HTML, formatter Markdown, unescaped link},
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('en');
        },
        template => q{<%TEXT VALUE="{link_begin}<**link**>{link_end}" UNESCAPED_link_begin="<a href='...'>" UNESCAPED_link_end="</a>" FORMATTER="Markdown" ESCAPE=HtMl%>},
        result   => q{<a href='...'>&lt;<strong>link</strong>&gt;</a>},
    },
    {
        test     => q{text as var, escape HTML, unescaped link},
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('en');
        },
        template => q{<%TEXT var1 UNESCAPED_link_begin_VAR="var2" UNESCAPED_link_end_VAR="var3" ESCAPE=HtMl%>},
        params    => {
            var1 => q{{link_begin}<link>{link_end}},
            var2 => q{<a href="...">},
            var3 => q{</a>},
        },
        result   => q{<a href="...">&lt;link&gt;</a>},
    },
);

for my $data (@data) {
    if ( exists $data->{prepare} ) {
        $data->{prepare}->();
    }
    my $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
        scalarref => \$data->{template},
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