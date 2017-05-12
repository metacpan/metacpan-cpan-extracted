#!perl

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use English qw(-no_match_vars $OS_ERROR);
use HTML::Template::Compiled;
use HTML::Template::Compiled::Plugin::I18N;
use lib qw(./lib);
use Example::Translator;

HTML::Template::Compiled::Plugin::I18N->init(
    allow_maketext   => 1,
    allow_unescaped  => 1,
    translator_class => 'Example::Translator',
);

my $htc = HTML::Template::Compiled->new(
    plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle  => [qw(-classic -comment +asp)],
    scalarref => \<<'EOT');
* placeholder
  <%TEXT VALUE="[_1] is programming <[_2]>." _1="Steffen" _2_VAR="language"%>
* placeholder and escape
  <%TEXT VALUE="[_1] is programming <[_2]>." _1="Steffen" _2_VAR="language" ESCAPE="HTML"%>
* unescaped placeholder
  <%TEXT VALUE="This is the {link_begin}<link>{link_end}." UNESCAPED_link_begin="<a href=http://www.perl.org/>" UNESCAPED_link_end="</a>" ESCAPE="HTML"%>

EOT
$htc->param(
    language => 'Perl',
);

binmode STDOUT, 'encoding(utf-8)'
    or croak "Can not switch encoding for STDOUT to utf-8: $OS_ERROR";
Example::Translator->set_language('en_GB');
() = print $htc->output();

Example::Translator->set_language('de_DE');
() = print $htc->output();

# $Id: example.pl 163 2009-12-03 09:20:38Z steffenw $

__END__

Output:

* placeholder
  Steffen is programming <Perl>.
* placeholder and escape
  Steffen is programming &lt;Perl&gt;.
* unescaped placeholder
  This is the <a href=http://www.perl.org/>&lt;link&gt;</a>.

* placeholder
  Steffen programmiert <Perl>.
* placeholder and escape
  Steffen programmiert &lt;Perl&gt;.
* unescaped placeholder
  Das ist der <a href=http://www.perl.org/>&lt;Link&gt;</a>.