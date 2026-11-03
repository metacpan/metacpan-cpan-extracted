package Locale::Simple;
# ABSTRACT: Short gettext helpers with one API for Perl, Python, JavaScript, PHP, Go and Rust
our $VERSION = '0.200';
use strict;
use warnings;

use Exporter 'import';
use Locale::TextDomain 1.23 (); # to ensure we get the right version of gettext_dumb
use Locale::gettext_dumb qw(:locale_h :libintl_h);
use POSIX qw' setlocale ';

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

	N_
	Nn_
	Np_
	Nnp_
	Nd_
	Ndn_
	Ndp_
	Ndnp_

	ltd

);

# Deferred translation markers — no-op identity stubs that exist so the
# scraper can treat them as msgid sources while runtime just returns the
# arguments unchanged. Use them where strings must be declared before the
# viewer's locale is known (attribute defaults, DSLs, constants) and pass
# the stored msgid(s) through the matching l*() later.
sub N_    { $_[0] }
sub Nn_   { wantarray ? @_[0,1] : $_[0] }
sub Np_   { $_[1] }
sub Nnp_  { wantarray ? @_[1,2] : $_[1] }
sub Nd_   { $_[1] }
sub Ndn_  { wantarray ? @_[1,2] : $_[1] }
sub Ndp_  { $_[2] }
sub Ndnp_ { wantarray ? @_[2,3] : $_[2] }

my $dry;
my $nowrite;
my $nolocales;

my %tds;
my $dir;

sub l_nolocales { $nolocales = shift }
sub l_dry { $dry = shift; $nowrite = shift; $nolocales = _set($dry) ? 1 : 0 }

# A string counts as set when it is defined and not empty, "0" included.
sub _set { defined $_[0] && length $_[0] }

sub gettext_escape {
	my ( $content ) = @_;
	$content =~ s/\\/\\\\/g;
	$content =~ s/\n/\\n/g;
	$content =~ s/\t/\\t/g;
	$content =~ s/\r/\\r/g;
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

# One placeholder of mo-reader.md §5: %%, or the N$ position, the flags (with
# '<char> as pad character), width, .precision and the conversion.
my $placeholder = qr{
	( % (?: % | (?: ([0-9]+) \$ )? ( (?: [-+\ 0\#] | '. )* ) ( \* | [0-9]+ )?
	  (?: \. ( \* | [0-9]* ) )? ( [bcdeEfFgGiosuxX] ) ) )
}xs;

# One pass over the format: the text between placeholders is copied, and each
# placeholder is formatted on its own with CORE::sprintf and its own
# arguments, so an argument value is never read as a format. %2$s picks its
# argument, a placeholder without N$ takes the next one in order (a * width or
# precision too). A placeholder without an argument stays as it is; extra
# arguments are ignored. python/locale_simple.py formats the same way.
sub _sprintf {
	my ( $format, @args ) = @_;
	my $next = 0;
	$format =~ s{$placeholder}{_placeholder( \@args, \$next, $1, $2, $3, $4, $5, $6 )}ge;
	return $format;
}

sub _placeholder {
	my ( $args, $next, $all, $index, $flags, $width, $precision, $conversion ) = @_;
	return '%' if $all eq '%%';
	my @picks;
	for my $star ( $width, $precision ) {
		push @picks, ${$next}++ if defined $star && $star eq '*';
	}
	push @picks, defined $index ? $index - 1 : ${$next}++;
	return $all if grep { $_ < 0 || $_ > $#{$args} } @picks;
	my @values = @{$args}[@picks];
	my $tail = ( defined $precision ? '.'.$precision : '' ).$conversion;
	my $pad;
	$pad = $1 while $flags =~ s/'(.)//s;
	return CORE::sprintf( '%'.$flags.( defined $width ? $width : '' ).$tail, @values )
		unless defined $pad && defined $width;
	# '<char>: the formatted value is filled up to the width with that character.
	my $size = $width eq '*' ? shift @values : $width;
	my $left = $flags =~ tr/-// || $size < 0;
	$flags =~ tr/-0//d;
	my $body = CORE::sprintf( '%'.$flags.$tail, @values );
	my $fill = abs($size) - length $body;
	return $body if $fill <= 0;
	return $left ? $body.( $pad x $fill ) : ( $pad x $fill ).$body;
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

sub l_dir {
	$dir = shift;
	_bind_textdomain($_) for keys %tds;
	return $dir;
}

# Binds a text domain to the l_dir() directory. ltd(), the domain helpers
# and l_dir() all bind through here, so every bound domain follows l_dir().
sub _bind_textdomain {
	my ( $td ) = @_;
	bindtextdomain($td,$dir);
	bind_textdomain_codeset($td,'utf-8');
	$tds{$td} = 1;
}

sub l_lang {
	my $primary = shift;
	$ENV{LANGUAGE} = $primary;
	$ENV{LANG} = $primary;		# unsure if these ENV assignments are still needed with the setlocale below
	$ENV{LC_ALL} = $primary;
	$ENV{LC_MESSAGES} = $primary; # set locale for messages if the system supports it
	# POSIX knows LC_MESSAGES only where the system has it; Locale::gettext_pp
	# answers its own LC_MESSAGES with a stand-in number everywhere.
	return unless defined eval { POSIX::LC_MESSAGES() };
	setlocale( LC_MESSAGES, $primary );
	# Under the C or POSIX messages locale gettext ignores LANGUAGE and
	# translates nothing. Without an installed locale for $primary, move
	# LC_MESSAGES to one that is not C, so the language set here still wins.
	my $now = setlocale( LC_MESSAGES );
	return if defined $now && $now ne 'C' && $now ne 'POSIX';
	for my $fallback ( 'C.UTF-8', 'en_US.UTF-8' ) {
		return if setlocale( LC_MESSAGES, $fallback );
	}
	return;
}

# write dry: UTF-8 with LF line ends on every platform (:raw drops :crlf)
sub wd {
	return if $nowrite;
	open my $fh, '>>:raw:encoding(UTF-8)', $dry
	  or die 'cannot append to '.$dry.': '.$!;
	print $fh join("\n",@_)."\n\n";
	close $fh;
}

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
	my ($td, $ctxt, $id, $idp, $n) = (shift,shift,shift,shift,shift);
	return $id if defined $id && $id eq '';
	die "please set a locale directory with l_dir() before using other translate functions" unless _set($dir) || $nolocales;
	my @args = @_;
	unshift @args, $n if defined $idp;
	my $return;
	if (_set($dry)) {
		if (!$nowrite) {
			my @save;
			push @save, '# domain: '.$td if _set($td);
			push @save, 'msgctxt "'.gettext_escape($ctxt).'"' if _set($ctxt);
			push @save, 'msgid "'.gettext_escape($id).'"';
			push @save, 'msgid_plural "'.gettext_escape($idp).'"' if _set($idp);
			wd(@save);
		}
		$return = _sprintf(defined $idp && $n != 1 ? $idp : $id, @args);
	} else {
		_bind_textdomain($td) if _set($td) && !$tds{$td};
		# L::TD handles msg ids as bytes internally
		utf8::encode($id);
		my $gt = dnpgettext($td, $ctxt, $id, $idp, $n);
		# Fixing bad utf8 handling
		utf8::decode($gt);
		$return = _sprintf($gt,@args);
	}
	return $return;
}

sub ltd {
	die "please set a locale directory with l_dir() before using other translate functions" unless _set($dir) || $nolocales;
	my $td = shift;
	_bind_textdomain($td) unless $tds{$td};
	textdomain($td);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Simple - Short gettext helpers with one API for Perl, Python, JavaScript, PHP, Go and Rust

=head1 VERSION

version 0.200

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
C<lnp>, C<ldnp>). The same helpers ship for Python, JavaScript, PHP, Go and
Rust (see L</SEE ALSO>), built from the same repository; the same msgids and
the same C<.po> files work across all six languages.

The module only supports UTF-8 data, in and out — that is fixed by design.

=head1 SETUP FUNCTIONS

=head2 l_dir($dir)

Set the locale directory. Structure underneath must follow the standard
gettext layout: C<< $dir/<lang>/LC_MESSAGES/<domain>.mo >>.

Every text domain reads from the directory set last: a later C<l_dir> moves
the domains already bound, whether through L</"ltd($domain)"> or on their
first use in a domain function, to the new directory.

=head2 ltd($domain)

Set (or switch) the active text domain. Binds the domain to the previously
set locale directory on first use.

=head2 l_lang($lang)

Set the active language (e.g. C<'de_DE'>, C<'pt_BR'>). Sets C<$ENV{LANGUAGE}>,
C<$ENV{LANG}>, C<$ENV{LC_ALL}>, C<$ENV{LC_MESSAGES}> and calls C<setlocale>.

The system does not need a locale for C<$lang> installed. gettext translates
nothing while the messages locale is C<C> or C<POSIX>, so when C<$lang> cannot
be set and the process runs under one of those, C<l_lang> sets C<LC_MESSAGES>
to C<C.UTF-8> (or C<en_US.UTF-8>) instead.

On a platform whose L<POSIX> has no C<LC_MESSAGES> category (Windows),
C<l_lang> sets the environment variables only.

=head2 l_dry($file, $nowrite)

Enable dry-run mode. While active, every translation call appends its msgid
block to C<$file> and returns the msgid (or C<$msgid_plural> for C<$n != 1>),
formatted with the same sprintf as a translation, positional placeholders
included. Useful for harvesting msgids from a running system. Pass a truthy
C<$nowrite> to suppress the file output but keep dry semantics.

The block holds the lines C<# domain: ...>, C<msgctxt "...">, C<msgid "...">
and C<msgid_plural "..."> that apply, joined by newlines and followed by a
blank line, in UTF-8 with LF line ends on every platform. Backslash, newline,
tab, carriage return and double quote are escaped as in a C<.po> file. An
empty msgid writes no block. The Python package writes the same bytes:

  # domain: myapp
  msgctxt "menu"
  msgid "%d file"
  msgid_plural "%d files"

Dry-run mode lifts the L</"l_dir($dir)"> check like L</"l_nolocales($bool)">.
C<l_dry(undef)> leaves dry-run mode and turns the check back on.

=head2 l_nolocales($bool)

Disable the sanity check that requires L</"l_dir($dir)"> to have been called. Lets
you use the module in pure sprintf mode (no gettext lookup) — handy in
tests, scripts and the string-extraction pipeline.

=head1 TRANSLATION FUNCTIONS

All translation functions take sprintf-style format arguments after the
required positional arguments. Perl positional-argument syntax
(C<%1$s>, C<%2$d>) is supported and recommended for anything that needs to
be reordered during translation. An empty msgid returns an empty string
without a lookup.

The format takes the conversions C<b c d e E f F g G i o s u x X>, the flags
C<+>, C<->, C<0>, space, C<#> and C<'> followed by a pad character
(C<%'*8s> fills with C<*>), a width and a C<.precision> (either may be C<*>),
the C<N$> position and C<%%>. Each placeholder is formatted on its own as
C<sprintf> formats it, so an argument value is never read as a format. A
placeholder without an argument stays in the text as it is, and extra
arguments are ignored, both without a warning. The Python package formats
the same way.

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
The domain is bound to the L</"l_dir($dir)"> directory on its first use, the
way L</"ltd($domain)"> binds it, so it needs no C<ltd> call of its own. The
three domain functions below do the same.

=head2 ldn($domain, $msgid, $msgid_plural, $n, @args)

Domain + plural.

=head2 ldp($domain, $msgctxt, $msgid, @args)

Domain + context.

=head2 ldnp($domain, $msgctxt, $msgid, $msgid_plural, $n, @args)

All four: domain, context, plural, arguments. The other functions are
convenience wrappers around this one.

=head1 DEFERRED TRANSLATION

Sometimes a msgid must be declared before a user locale is known —
attribute defaults, DSL registrations evaluated at C<use>-time, class
constants. Calling C<l()> inline there freezes the result in the
startup locale. Gettext's classic solution is the C<N_> "no-op"
marker: extraction tools recognise it as a translation source, but at
runtime it just returns its argument so the caller can store the msgid
and translate it later.

C<Locale::Simple> exports C<N_> and a twin for every C<l*()> helper:

  N_($msgid)                          # twin of l()
  Nn_($sg, $pl)                       # twin of ln()
  Np_($ctx, $msgid)                   # twin of lp()
  Nnp_($ctx, $sg, $pl)                # twin of lnp()
  Nd_($dom, $msgid)                   # twin of ld()
  Ndn_($dom, $sg, $pl)                # twin of ldn()
  Ndp_($dom, $ctx, $msgid)            # twin of ldp()
  Ndnp_($dom, $ctx, $sg, $pl)         # twin of ldnp()

All are pure pass-throughs. Plural variants return C<($sg, $pl)> in list
context and C<$sg> in scalar context. The C<domain>/C<context> arguments
contribute to the extracted C<.pot> entry but are not returned — the
caller already has them.

  # Class-construction time (no locale yet):
  my $label = N_($msgid);                      # = $msgid
  my @plur  = Nn_($sg, $pl);                   # = ($sg, $pl)

  # Render time (after l_lang($user_locale)):
  print l($label);
  print ln(@plur, $count);

The scraper (L<Locale::Simple::Scraper>) recognises all eight C<N*_>
names in Perl, JavaScript, Python, PHP and Go sources and their lower-case
macro twins (C<n_!>, C<nn_!>, ...) in Rust, and emits C<.pot> entries
identical to their C<l*()> twins. It finds them in Xslate templates
(C<.tx>) as well, though they are rarely needed there: templates run at
request time, when the language is already known.

=head1 STRING EXTRACTION

The distribution ships the L<locale-simple> command. C<locale-simple scrape>
is a static-analysis tool that walks your source tree and writes a C<.pot>
template. It understands C<.pl>, C<.pm>, C<.t>, C<.py>, C<.js>, C<.php>,
C<.go>, C<.rs> and C<.tx> files, so one extraction run covers a polyglot
project.

  locale-simple scrape --ignore node_modules --ignore build \
                       > po/myapp.pot

See L<Locale::Simple::Scraper> for the programmatic interface and supported
options.

C<locale-simple po2json> converts a C<.po> file into the JSON the JavaScript
package loads with C<loadLocaleData>:

  locale-simple po2json share/locale/de_DE/LC_MESSAGES/myapp.po > myapp.de_DE.json

The older commands C<locale_simple_scraper> and C<po2json> still work but are
deprecated.

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

=item *

L<https://packagist.org/packages/raudssus/locale-simple> — PHP sibling.

=item *

L<https://pkg.go.dev/github.com/Getty/locale-simple/go> — Go sibling.

=item *

L<https://crates.io/crates/locale-simple> — Rust sibling.

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
