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
    plan tests => 3 + 1;
}
use Test::NoWarnings;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(
    allow_maketext  => 1,
    allow_unescaped => 1,
);

my @data = (
    {
        test     => 'maketext, escape HTML and unescaped placeholder',
        template => '<%TEXT VALUE="text <1> [_1] {name}" _1="<>" UNESCAPED_value="<value>" ESCAPE="HtMl"%>',
        result   => 'text=text &lt;1&gt; [_1] {name};maketext=&lt;&gt;;unescaped=value,<value>',
    },
);

for my $data (@data) {
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
