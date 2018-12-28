#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use HTML::Template::Compiled;

my $template_sprintf_30 = '<%= test ESCAPE=SPRINTF_8_RIGHT %>';
my $text                = 'hello'; 

my $tmpl = HTML::Template::Compiled->new(
    scalarref => \$template_sprintf_30,
    plugin    => [ 'HTML::Template::Compiled::Plugin::Sprintf' ],
);

$tmpl->param( test => $text );
my $output = $tmpl->output;

is $output, '   hello', 'sprintf_8_right';

$tmpl->param( test => undef );
my $undef_output = $tmpl->output;

is $undef_output, '', 'sprintf_8_right - undef';

done_testing();
