#!perl

use strict;
use warnings;

our $VERSION = 0;

use HTML::Template::Compiled;
use HTML::Template::Compiled::Plugin::I18N;

HTML::Template::Compiled::Plugin::I18N->init();

my $htc = HTML::Template::Compiled->new(
    plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle  => [qw(-classic -comment +asp)],
    scalarref => \<<'EOT');
<%TEXT VALUE="foo & bar" ESCAPE="HTML"%>
EOT
$htc->param(
);
() = print $htc->output();

# $Id: using_default_translator.pl 163 2009-12-03 09:20:38Z steffenw $

__END__

Output:

text=foo &amp; bar