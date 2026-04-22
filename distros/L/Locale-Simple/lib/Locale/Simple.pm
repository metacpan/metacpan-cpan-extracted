package Locale::Simple;
# ABSTRACT: Functions for translate text based on gettext data, also in JavaScript
our $VERSION = '0.108';
use strict;
use warnings;

use Exporter 'import';
use Locale::TextDomain 1.23 (); # to ensure we get the right version of gettext_dumb
use Locale::gettext_dumb qw(:locale_h :libintl_h);
use POSIX qw' setlocale ';
use IO::All 0.41 -utf8;

our @EXPORT = qw(
	
	l_dir
	l_lang
	l_dry
	l_nolocales

	l
	ln
	lp
	lnp
	ld
	ldn
	ldp
	ldnp
	
	ltd

);

my $dry;
my $nowrite;
my $nolocales;

my %tds;
my $dir;

sub l_nolocales { $nolocales = shift }
sub l_dry { $dry = shift; $nowrite = shift; $nolocales = 1 if $dry }

sub gettext_escape {
	my ( $content ) = @_;
	$content =~ s/\\/\\\\/g;
	$content =~ s/\n/\\n/g;
	$content =~ s/"/\\"/g;
	return $content;
}

sub sprintf_compare {
	my ( $first, $second ) = @_;
	my $re = qr/(?:%%|%(?:[0-9]+\$)?[+-]?(?:[ 0]|\'.)?-?[0-9]*(?:\.[0-9]+)?[bcdeufFosxX])/;
	my @placeholder_first = sort { $a cmp $b } map { my @chars = split(//,$_); pop @chars; } ($first =~ m/$re/g);
	my @placeholder_second = sort { $a cmp $b } map { my @chars = split(//,$_); pop @chars; } ($second =~ m/$re/g);
	return join("",@placeholder_first) eq join("",@placeholder_second);
}

sub coderef_hash {{
	l => sub { l(@_) },
	ln => sub { ln(@_) },
	lp => sub { lp(@_) },
	lnp => sub { lnp(@_) },
	ld => sub { ld(@_) },
	ldn => sub { ldn(@_) },
	ldp => sub { ldp(@_) },
	ldnp => sub { ldnp(@_) },
}}

sub l_dir { $dir = shift }

sub l_lang {
	my $primary = shift;
	$ENV{LANGUAGE} = $primary;
	$ENV{LANG} = $primary;		# unsure if these ENV assignments are still needed with the setlocale below
	$ENV{LC_ALL} = $primary;
	$ENV{LC_MESSAGES} = $primary; # set locale for messages if the system supports it
	setlocale( LC_MESSAGES, $primary ) if eval { LC_MESSAGES }; # set locale for messages if the system supports it
}

# write dry
sub wd { io($dry)->append(join("\n",@_)."\n\n") if !$nowrite }

# l(msgid,...)
sub l { return ldnp('',undef,shift,undef,undef,@_) }
# ln(msgid,msgid_plural,count,...)
sub ln { return ldnp('',undef,@_) }
# lp(msgctxt,msgid,...)
sub lp { return ldnp('',shift,shift,undef,undef,@_) }
# lnp(msgctxt,msgid,msgid_plural,count,...)
sub lnp { return ldnp('',shift,shift,shift,shift,@_) }
# ld(domain,msgid,...)
sub ld { return ldnp(shift,undef,shift,undef,undef,@_) }
# ldn(domain,msgid,msgid_plural,count,...)
sub ldn { return ldnp(shift,undef,shift,shift,shift,@_) }
# ldp(domain,msgctxt,msgid,...)
sub ldp { return ldnp(shift,shift,shift,undef,undef,@_) }
# ldnp(domain,msgctxt,msgid,msgid_plural,count,...)
sub ldnp {
	die "please set a locale directory with l_dir() before using other translate functions" unless $dir || $nolocales;
	my ($td, $ctxt, $id, $idp, $n) = (shift,shift,shift,shift,shift);
	my @args = @_;
	unshift @args, $n if $idp;
	my $return;
	if ($dry) {
		if (!$nowrite) {
			my @save;
			push @save, '# domain: '.$td if $td;
			push @save, 'msgctxt "'.gettext_escape($ctxt).'"' if $ctxt;
			push @save, 'msgid "'.gettext_escape($id).'"';
			push @save, 'msgid_plural "'.gettext_escape($idp).'"' if $idp;
			wd(@save);
		}
		no warnings 'redundant';
		$return = sprintf($idp && $n != 1 ? $idp : $id, @args);
	} else {
		# L::TD handles msg ids as bytes internally
		utf8::encode($id);
		my $gt = dnpgettext($td, $ctxt, $id, $idp, $n);
		# Fixing bad utf8 handling
		utf8::decode($gt);
		no warnings 'redundant';
		$return = sprintf($gt,@args);
	}
	return $return;
}

sub ltd {
	die "please set a locale directory with l_dir() before using other translate functions" unless $dir || $nolocales;
	my $td = shift;
	unless (defined $tds{$td}) {
		bindtextdomain($td,$dir);
		bind_textdomain_codeset($td,'utf-8');
		$tds{$td} = 1;
	}
	textdomain($td);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple - Functions for translate text based on gettext data, also in JavaScript

=head1 VERSION

version 0.108

=head1 SYNOPSIS

  use Locale::Simple;

  l_dir('share/locale');   # dir containing <lang>/LC_MESSAGES/<domain>.mo
  ltd('myapp');            # text domain
  l_lang('de_DE');         # active language

  print l("Hello");                                        # "Hallo"
  print ln("You have %d message",
           "You have %d messages", 4);                     # "Du hast 4 Nachrichten"
  print lp("menu", "Open");                                # context-specific lookup

Sample PO file (C<share/locale/de_DE/LC_MESSAGES/myapp.po>):

  msgid ""
  msgstr ""
  "Language: de_DE\n"
  "MIME-Version: 1.0\n"
  "Content-Type: text/plain; charset=UTF-8\n"
  "Content-Transfer-Encoding: 8bit\n"
  "Plural-Forms: nplurals=2; plural=n != 1;"

  msgid "Hello"
  msgstr "Hallo"

  msgid "You have %d message"
  msgid_plural "You have %d messages"
  msgstr[0] "Du hast %d Nachricht"
  msgstr[1] "Du hast %d Nachrichten"

Compile to C<.mo>:

  msgfmt share/locale/de_DE/LC_MESSAGES/myapp.po \
         -o share/locale/de_DE/LC_MESSAGES/myapp.mo

=head1 DESCRIPTION

C<Locale::Simple> is a thin wrapper over L<Locale::TextDomain> / gettext,
exporting short function names (C<l>, C<ln>, C<lp>, C<ld>, C<ldn>, C<ldp>,
C<lnp>, C<ldnp>) that are API-compatible with the matching Python package
L<locale-simple|https://pypi.org/project/locale-simple/> and the npm package
L<locale-simple|https://www.npmjs.com/package/locale-simple>. The same msgids
and the same C<.po> files work across all three languages.

The module only supports UTF-8 data, in and out — that is fixed by design.

=head1 SETUP FUNCTIONS

=head2 l_dir($dir)

Set the locale directory. Structure underneath must follow the standard
gettext layout: C<< $dir/<lang>/LC_MESSAGES/<domain>.mo >>.

=head2 ltd($domain)

Set (or switch) the active text domain. Binds the domain to the previously
set locale directory on first use.

=head2 l_lang($lang)

Set the active language (e.g. C<'de_DE'>, C<'pt_BR'>). Sets C<$ENV{LANGUAGE}>,
C<$ENV{LANG}>, C<$ENV{LC_ALL}>, C<$ENV{LC_MESSAGES}> and calls C<setlocale>.

=head2 l_dry($file, $nowrite)

Enable dry-run mode. While active, every translation call appends its msgid
in C<.po> format to C<$file> and still returns the formatted result. Useful
for harvesting msgids from a running system. Pass a truthy C<$nowrite> to
suppress the file output but keep dry semantics.

=head2 l_nolocales($bool)

Disable the sanity check that requires L</l_dir> to have been called. Lets
you use the module in pure sprintf mode (no gettext lookup) — handy in
tests, scripts and the string-extraction pipeline.

=head1 TRANSLATION FUNCTIONS

All translation functions take sprintf-style format arguments after the
required positional arguments. Perl positional-argument syntax
(C<%1$s>, C<%2$d>) is supported and recommended for anything that needs to
be reordered during translation.

=head2 l($msgid, @args)

Plain translation.

=head2 ln($msgid, $msgid_plural, $n, @args)

Plural-aware translation; C<$n> selects between singular and plural forms.
C<$n> is implicitly passed as the first sprintf argument.

=head2 lp($msgctxt, $msgid, @args)

Context-aware translation. Use when the same msgid needs different
translations in different UI contexts (e.g. C<lp("menu", "Open")> vs.
C<lp("state", "Open")>).

=head2 lnp($msgctxt, $msgid, $msgid_plural, $n, @args)

Context + plural. The full gettext C<p_gettext_n> shape.

=head2 ld($domain, $msgid, @args)

Translation from a specific domain without switching the current domain.

=head2 ldn($domain, $msgid, $msgid_plural, $n, @args)

Domain + plural.

=head2 ldp($domain, $msgctxt, $msgid, @args)

Domain + context.

=head2 ldnp($domain, $msgctxt, $msgid, $msgid_plural, $n, @args)

All four: domain, context, plural, arguments. The other functions are
convenience wrappers around this one.

=head1 STRING EXTRACTION

The distribution ships C<bin/locale_simple_scraper>, a static-analysis tool
that walks your source tree and writes a C<.pot> template. It understands
C<.pl>, C<.pm>, C<.t>, C<.py>, C<.js> and C<.tx> files uniformly, so one
extraction run covers a polyglot project.

  locale_simple_scraper --ignore node_modules --ignore build \
                        > po/myapp.pot

See L<Locale::Simple::Scraper> for the programmatic interface and supported
options.

=head1 SEE ALSO

=over 4

=item *

L<Locale::TextDomain> — the underlying gettext binding.

=item *

L<Locale::Messages> — the lower-level layer.

=item *

L<https://pypi.org/project/locale-simple/> — Python sibling.

=item *

L<https://www.npmjs.com/package/locale-simple> — JavaScript sibling.

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/locale-simple/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software, licensed under:

  The MIT (X11) License

=cut
