#!perl -T

use strict;
use warnings;

use Test::More tests => 10 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(allow_gettext => 1);

my @data = (
    {
        test     => 'gettext plural only',
        template => '<%TEXT VALUE="text_singular1" PLURAL="text_plural1"%>',
        result   => 'text=text_singular1;plural=text_plural1',
    },
    {
        test     => 'gettext count only',
        template => '<%TEXT VALUE="text_singular2" COUNT="2"%>',
        result   => 'text=text_singular2;count=2',
    },
    {
        test     => 'gettext plural',
        template => '<%TEXT VALUE="text_singular3" PLURAL="text_plural3" COUNT="2"%>',
        result   => 'text=text_singular3;plural=text_plural3;count=2',
    },
    {
        test     => 'gettext plural, all as var',
        template => '<%TEXT var_singular PLURAL_VAR="var_plural" COUNT_VAR="var_count"%>',
        params   => {
            var_singular => 'text_singular4',
            var_plural   => 'text_plural4',
            var_count    => 2,
        },
        result   => 'text=text_singular4;plural=text_plural4;count=2',
    },
    {
        test     => 'gettext context',
        template => '<%TEXT VALUE="text5" CONTEXT="context5"%>',
        result   => 'context=context5;text=text5',
    },
    {
        test     => 'gettext context as var',
        template => '<%TEXT VALUE="text6" CONTEXT_VAR="var_context"%>',
        params   => {var_context => 'context6'},
        result   => 'context=context6;text=text6',
    },
    {
        test     => 'gettext all',
        template => '<%TEXT VALUE="text_singular7" PLURAL="text_plural7" COUNT="2" CONTEXT="context7" _name="gt7"%>',
        result   => 'context=context7;text=text_singular7;plural=text_plural7;count=2;gettext=name,gt7',
    },
    {
        test     => 'gettext all, all as var',
        template => '<%TEXT var_singular PLURAL_VAR="var_plural" COUNT_VAR="var_count" CONTEXT_VAR="var_context" _name_VAR="var_name"%>',
        params   => {
            var_singular => 'text_singular8',
            var_plural   => 'text_plural8',
            var_count    => 2,
            var_context  => 'context8',
            var_name     => 'gt8',
        },
        result   => 'context=context8;text=text_singular8;plural=text_plural8;count=2;gettext=name,gt8',
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