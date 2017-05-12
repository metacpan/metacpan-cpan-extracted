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
    allow_gettext    => 1,
    allow_unescaped  => 1,
    translator_class => 'Example::Translator',
);

my $htc = HTML::Template::Compiled->new(
    plugin    => [qw(HTML::Template::Compiled::Plugin::I18N)],
    tagstyle  => [qw(-classic -comment +asp)],
    scalarref => \<<'EOT');
* placeholder
  <%TEXT VALUE="{name} is programming <{language}>." _name="Steffen" _language_VAR="language"%>
* placeholder and escape
  <%TEXT VALUE="{name} is programming <{language}>." _name="Steffen" _language_VAR="language" ESCAPE="HTML"%>
* unescaped placeholder
  <%TEXT VALUE="This is the {link_begin}<link>{link_end}." UNESCAPED_link_begin="<a href=http://www.perl.org/>" UNESCAPED_link_end="</a>" ESCAPE="HTML"%>
* no context
  <%TEXT VALUE="Context?"%>
* context
  <%TEXT VALUE="Context?" CONTEXT="this_context"%>
* plural
  <%TEXT VALUE="shelf" PLURAL="shelves" COUNT="1"%>
  <%TEXT VALUE="shelf" PLURAL="shelves" COUNT="2"%>
* context and plural
  <%TEXT VALUE="shelf<>" PLURAL="shelve<s>" COUNT="1" CONTEXT="better"%>
  <%TEXT VALUE="shelf<>" PLURAL="shelve<s>" COUNT="2" CONTEXT="better"%>

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
  Steffen is programming Perl.
* unescaped placeholder
  This is the <a href=http://www.perl.org/>&lt;link&gt;</a>.
* no context
  No context.
* context
  Has context.
* plural
  shelf
  shelves
* context and plural
  good shelf<>
  good shelve<s>

* placeholder
  Steffen programmiert Perl.
* different placeholder escape
  Das ist der <a href=http://www.perl.org/>&lt;Link&gt;</a>.
* no context
  Kein Kontext.
* context
  Hat Kontext.
* plural
  Regal
  Regale
* context and plural
  gutes Regal<>
  gute Regal<e>