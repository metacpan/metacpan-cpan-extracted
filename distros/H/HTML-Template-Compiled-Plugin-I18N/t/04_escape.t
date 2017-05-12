#!perl -T

use strict;
use warnings;

use English qw(-no_match_vars $EVAL_ERROR);
use Test::More;
BEGIN {
    eval 'use HTML::Entities';
    plan skip_all => "HTML::Entities required for testing ESCAPE=HTML; $EVAL_ERROR" if $EVAL_ERROR;
    plan tests => 7 + 1;
}
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('HTML::Template::Compiled');
    use_ok('HTML::Template::Compiled::Plugin::I18N');
}

HTML::Template::Compiled::Plugin::I18N->init();

my @data = (
    {
        test     => 'no escape',
        template => '<%TEXT VALUE="<>"%>',
        result   => 'text=<>',
    },
    {
        test     => 'escape 0',
        template => '<%TEXT VALUE="<>" ESCAPE=0%>',
        result   => 'text=<>',
    },
    {
        test     => 'escape HTML',
        template => '<%TEXT VALUE="<>" ESCAPE=HtMl%>',
        result   => 'text=&lt;&gt;',
    },
    {
        test     => 'escape DUMP',
        template => '<%TEXT VALUE="mytext" ESCAPE=DuMp%>',
        result   => "text=\$VAR1 = 'mytext';\n",
    },
    {
        test     => 'escape DUMP|HTML',
        template => '<%TEXT VALUE="mytext" ESCAPE=DuMp|HtMl%>',
        result   => "text=\$VAR1 = &#39;mytext&#39;;\n",
    },
#    {
#        test      => 'unknown escape',
#        template  => '<%TEXT VALUE="mytext" ESCAPE=XxX%>',
#        exception => qr{\Qunknown escape XxX}xms,
#    },
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
    if ( exists $data->{exception} ) {
        throws_ok(
            sub { $htc->output() },
            $data->{exception},
            $data->{test},
        );
    }
    else {
        is(
            $htc->output(),
            $data->{result},
            $data->{test},
        );
    }
}