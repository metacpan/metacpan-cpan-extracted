#!perl -T

use strict;
use warnings;

use Test::More tests => 7 + 1;
use Test::NoWarnings;

use lib qw(./t/lib);

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
    use_ok('HTML::Template::Compiled::Plugin::I18N::TestTranslator');
}

HTML::Template::Compiled::Plugin::I18N->init(
    translator_class => 'HTML::Template::Compiled::Plugin::I18N::TestTranslator',
);

my @data = (
    {
        test     => 'test translator class (en)',
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('en');
        },
        template => '<%TEXT VALUE="Hello <world>!"%>',
        result   => 'Hello <world>!',
    },
    {
        test     => 'test translator class (de)',
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('de');
        },
        template => '<%TEXT VALUE="Hello <world>!"%>',
        result   => 'Hallo <Welt>!',
    },
    {
        test     => 'escape text',
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('de');
        },
        template => '<%TEXT VALUE="Hello <world>!" ESCAPE="HtMl"%>',
        result   => 'Hallo &lt;Welt&gt;!',
    },
    {
        test     => 'escape var',
        prepare  => sub {
            HTML::Template::Compiled::Plugin::I18N::TestTranslator
                ->new()
                ->set_language('de');
        },
        template => '<%TEXT NAME="var" ESCAPE="HtMl"%>',
        params   => { var => 'Hello <world>!' },
        result   => 'Hallo &lt;Welt&gt;!',
    },
);

for my $data (@data) {
    if ( exists $data->{prepare} ) {
        $data->{prepare}->();
    }
    my $htc = HTML::Template::Compiled->new(
        tagstyle  => [qw(-classic -comment +asp)],
        plugin    => [qw(
            HTML::Template::Compiled::Plugin::I18N
        )],
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