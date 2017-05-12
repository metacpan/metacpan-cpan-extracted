#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use HTML::Template::Compiled;

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = 'hello>'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, 'hello&gt;', '> => &gt;';
}

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = 'hello &gt;'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, 'hello &amp;gt;', '& => &amp;';
}

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = 'hello'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, 'hello', 'hello';
}

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = 'hello<br />'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, 'hello<br />', 'do not escape <br />';
}

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = '&nbsp;
 hello<br />'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, "&nbsp;\n hello<br />", 'do not escape &nbsp; either';
}

{
    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = '&nbsp; hello<br />'; 

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, '&nbsp; hello<br />', 'test';
}
