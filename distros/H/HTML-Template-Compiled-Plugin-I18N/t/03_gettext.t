#!perl -T

use strict;
use warnings;

use Test::More tests => 9 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init(allow_gettext => 1);

my @data = (
    {
        test     => '1 gettext placeholder as text',
        template => '<%TEXT VALUE="text1" _name="gt1"%>',
        result   => 'text=text1;gettext=name,gt1',
    },
    {
        test     => '2 gettext placeholders as text',
        template => '<%TEXT VALUE="text2" _name1="gt1" _name2="gt2"%>',
        result   => 'text=text2;gettext=name1,gt1,name2,gt2',
    },
    {
        test     => '1 gettext placeholder as var',
        template => '<%TEXT VALUE="text3" _name_VAR="value"%>',
        params   => {
            value => 'gt1',
        },
        result   => 'text=text3;gettext=name,gt1',
    },
    {
        test     => '2 gettext placeholders as var',
        template => '<%TEXT VALUE="text4" _name1_VAR="hash.value1" _name2_VAR="hash.value2"%>',
        params   => {
            hash => {value1 => 'gt1', value2 => 'gt2'},
        },
        result   => 'text=text4;gettext=name1,gt1,name2,gt2',
    },
    {
        test     => 'mixed gettext placeholders',
        template => '<%TEXT VALUE="text5" _name1="gt1" _name2_VAR="hash.value2"%>',
        params   => {
            hash => {value2 => 'gt2'},
        },
        result   => 'text=text5;gettext=name1,gt1,name2,gt2',
    },
    {
        test     => 'missing data of gettext placeholders',
        template => '<%TEXT VALUE="text6" _name1_VAR="var" _name2_VAR="hash.value"%>',
        result   => 'text=text6;gettext=name1,undef,name2,undef',
    },
    {
        test     => 'allowed gettext placeholder names',
        template => '<%TEXT VALUE="text7" _name_1="gt1" _name_2_VAR="var"%>',
        params   => {var => 'gt2'},
        result   => 'text=text7;gettext=name_1,gt1,name_2,gt2',
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