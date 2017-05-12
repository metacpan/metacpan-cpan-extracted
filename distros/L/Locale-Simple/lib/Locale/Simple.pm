package Locale::Simple;
BEGIN {
  $Locale::Simple::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Functions for translate text based on gettext data, also in JavaScript
$Locale::Simple::VERSION = '0.019';
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
		$return = sprintf($idp && $n != 1 ? $idp : $id, @args);
	} else {
		# L::TD handles msg ids as bytes internally
		utf8::encode($id);
		my $gt = dnpgettext($td, $ctxt, $id, $idp, $n);
		# Fixing bad utf8 handling
		utf8::decode($gt);
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

=head1 NAME

Locale::Simple - Functions for translate text based on gettext data, also in JavaScript

=head1 VERSION

version 0.019

=head1 SYNOPSIS

  use Locale::Simple;

  l_dir('data/locale');
  ltd('test');
  l_lang('de_DE');

  print l("Hello"); # "Hallo"
  print ln("You have %d message","You have %d messages",4); # 'Du hast 4 Nachrichten'

Usage in JavaScript:

  <script language="javascript" src="../../share/js/sprintf.js"></script>
  <script language="javascript" src="../../share/js/gettext/Gettext.js"></script>
  <script language="javascript" src="../../share/js/locale_simple.js"></script>
  <script language="javascript" src="locale/de_DE/LC_MESSAGES/test.json"></script>

  ltd('test');

  l("Hello");
  ln("You have %d message","You have %d messages",4);

Sample PO file, in this case data/locale/test.po

  msgid ""
  msgstr ""
  "Language: de_DE\n"
  "MIME-Version: 1.0\n"
  "Content-Type: text/plain; charset=UTF-8\n"
  "Content-Transfer-Encoding: 8bit\n"
  "Plural-Forms: nplurals=2; plural=n != 1;"

  msgid "You have %d message"
  msgid_plural "You have %d messages"
  msgstr[0] "Du hast %d Nachricht"
  msgstr[1] "Du hast %d Nachrichten"

  msgid "Hello"
  msgstr "Hallo"

=head1 DESCRIPTION

This is a small wrapper around Gettext functionality that integrates sprintf and makes
it a bit more easy to setup the internationalization. It ONLY supports UTF8 data, and in
or output, that is a fixed setup (and always will be).

Gettext in Perl requires compiled po files, so called mo files. You can generate those
with the following command (if you have gettext in general installed on your system):

  msgfmt -o data/locale/test.mo data/locale/test.po

The Gettext implementation in JavaScript which is wrapped, requires a json file to be
generated out of the po. This can be achieved with po2json which is delivered with
this package. Sadly it only generates the json and doesnt integrate it into the
translation storage in the JavaScript. To generate this you can do:

  echo -n "locale_data['test'] = " >data/locale/test.json
  po2json data/locale/test.po >>data/locale/test.json
  echo ";" >>data/locale/test.json

B<WARNING> it could be that the way how to integrate this in JavaScript might change
in future version. Please check this place here on every upgrade for further informations.

=encoding utf8

=head1 SEE ALSO

=head2 L<Locale::Messages>

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-locale-simple
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-locale-simple/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by DuckDuckGo, Inc. L<http://duckduckgo.com/>, Torsten Raudssus <torsten@raudss.us>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
