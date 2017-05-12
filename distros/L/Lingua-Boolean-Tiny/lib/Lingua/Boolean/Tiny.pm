use 5.006002;
use strict;
use warnings;
use utf8;
no warnings qw( void once uninitialized );

{
	package Lingua::Boolean::Tiny;
	
	require Exporter;
	our @ISA = 'Exporter';
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	our @EXPORT    = qw( boolean );
	our (%LANG, @LANG);
	our @BASELANG  = qw( zh en es hi ru ar pt bn fr ms de ja );
	
	sub new
	{
		require Carp;
		my $class = shift;
		my $self  = $class->new_strict(@_)
			or Carp::carp("Language not available, using English instead");
		$self || "Lingua::Boolean::Tiny"->new_strict("en");
	}
	
	sub new_strict
	{
		shift;
		my ($lang) = @_;
		return "Lingua::Boolean::Tiny::Union"->new(@$lang) if ref($lang);
		return "Lingua::Boolean::Tiny::Union"->new(@BASELANG) if !defined $lang;
		my $class = $LANG{ lc $lang }
			|| do { require Lingua::Boolean::Tiny::More; $LANG{ lc $lang } };
		return $class->new if $class;
		return;
	}
	
	sub boolean
	{
		my $text = shift;
		my $lang = __PACKAGE__->new(@_ ? $_[0] : \@LANG);
		$lang->boolean($text);
	}
	
	sub langs
	{
		@LANG;
	}
	
	sub languages
	{
		map __PACKAGE__->new($_)->languages, @LANG;
	}
}

{
	package Lingua::Boolean::Tiny::BASE;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	# Versions of ~~ and fc for legacy Perls...
	use if $] >= 5.016, feature => 'fc';
	BEGIN { eval q[fc("1")] or eval q[sub fc($) { lc $_[0] }] };
	
	eval q
	{
		use match::simple qw(match);
		1;
	}
	or eval q
	{
		use v5.10.1;
		no warnings;
		sub match { $_[0] ~~ $_[1] };
		1;
	}
	or eval q
	{
		sub match
		{
			my ($a, $b) = @_;
			if (ref($b) eq 'ARRAY')
			{
				for my $b2 (@$b)
				{
					return 1 if match($a, $b2);
				}
			}
			ref($b) eq 'Regexp' and return $a =~ $b;
			ref($b) eq 'CODE'   and return $b->($a);
			return $a eq $b;
		}
	};
	
	sub boolean
	{
		my $self = shift;
		my ($text) = @_;
		
		$text =~ s/(?:^\s+)|(?:\s+$)//gs;
		
		return 1 if fc $text eq fc $self->yes;
		return 0 if fc $text eq fc $self->no;
		return 1 if match($text, $self->yes_expr);
		return 0 if match($text, $self->no_expr);
		return 1 if $text eq 1;
		return 0 if $text eq 0;
		return undef;
	}
	
	sub yesno
	{
		$_[1] ? $_[0]->yes : $_[0]->no
	}
	
	sub make_classes
	{
		my $base = shift;
		no strict 'refs';
		for (@_)
		{
			my ($lang, $codes, $yes, $no, $yes_expr, $no_expr) = @$_;
			$yes_expr = $yes unless defined $yes_expr;
			$no_expr  = $no  unless defined $no_expr;
			my $class = "Lingua::Boolean::Tiny::$lang";
			${"$class\::AUTHORITY"} = $AUTHORITY;
			${"$class\::VERSION"}   = $VERSION;
			@{"$class\::ISA"}       = ($base);
			no warnings qw( closure );
			eval qq
			{
				package $class;
				sub new       { my \$k = shift; bless qr{$lang}, \$k };
				sub yes       { \$yes };
				sub no        { \$no };
				sub yes_expr  { \$yes_expr };
				sub no_expr   { \$no_expr };
				sub languages { \$lang };
				sub langs     { \@{ \$codes } };
			};
			for my $lang (@$codes)
			{
				$Lingua::Boolean::Tiny::LANG{$lang} = $class;
			}
			push @Lingua::Boolean::Tiny::LANG, $codes->[0];
		}
		
		return 1;
	}
}

{
	package Lingua::Boolean::Tiny::Union;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	sub new
	{
		my $class = shift;
		bless [ grep defined, map "Lingua::Boolean::Tiny"->new_strict($_), @_ ] => $class;
	}
	
	sub boolean
	{
		my $self = shift;
		for (@$self)
		{
			my $r = $_->boolean(@_);
			return $r if defined $r;
		}
		return undef;
	}
	
	sub langs
	{
		my $self = shift;
		map $_->langs, @$self;
	}
	
	sub languages
	{
		my $self = shift;
		map $_->languages, @$self;
	}
}

"Lingua::Boolean::Tiny::BASE"->make_classes(
	[
		Chinese => [qw( zh zho chi )],
		q/是/ => q/不是/,
		[qr{^[yY是]}, qw( 是 對 是 对 ), qr{^[ds]h[ìi]$}i],
		[qr{^[nN不否]}, qw( 不是 不對 不是 不对 ), qr{^b[úu]\s*[ds]h[ìi]$}i],
	],
	[
		English => [qw( en eng )],
		qw( yes no ),
		[qr{^y(?:es)?$}i, qr{^on$}i, qr{^ok$}i, qr{^true$}i],
		[qr{^no?$}i, qr{^off$}i, qr{not ?ok$}i, qr{^false$}i],
	],
	[
		Spanish => [qw( es spa )],
		qw( sí no ),
		qr{^[sSyY]},
		qr{^[nN]$},
	],
	[
		Hindi => [qw( hi hin )],
		q/हाँ/ => q/नहीं/,
		["हाँ", qr{^h[aā]̃$}i, "जी", qr{^j[īi]$}i, "जी हाँ", qr{^j[īi]\s*h[aā]̃$}i, qr{^ji\s*ha$}i, qr{^[yY]}],
		["नहीं", qr{^nahī̃$}i, "जी नहीं", qr{^jī nahī̃$}i, qr{^ji\s*nahi$}i, qr{^[nN]}],
	],
	[
		Russian => [qw( ru rus )],
		qw( да нет ),
		[qr{^[ДдYy]}, qr{^да$}i, qr{^da$}i],
		[qr{^[НнNn]}, qr{^нет$}i, qr{^n[iy]?et$}i],
	],
	[
		Arabic => [qw( ar ara )],
		q/نعم/ => q/ﻻ/,
		qr{^[نyY].*},
		qr{^[لnN].*},
	],
	[
		Portuguese  => [qw( pt por )],
		qw( sim não ),
		[qr{^[SsyY].*}, qr{^sim$}i],
		[qr{^[nN].*}, qr{^n[aã]o$}i],
	],
	[
		Bengali => [qw( bn ben )],
		q/হ্যাঁ/ => q/না/,
		[qr{^[হ্যাঁyY]}, q/জি/, q/হ্যাঁ/, qr{^ji$}i, qr{^h[eê][nñ]$}i],
		[qr{^[নাnN]}, q/না/, qr{^n[aā]$}i],
	],
	[
		French => [qw( fr fre fra )],
		qw( oui non ),
		[qr{^[oOjJyYsS1].*}, qr{^oui$}i, qr{^ok$}i, qr{^vraie?$}i],
		[qr{^[nN0].*}, qr{^n(?:on?)?$}i, qr{^faux$}i],
	],
	[
		Malay => [qw( ms may msa )],
		qw( ya tidak ),
		[qr{^[Yy]}, qr{^ya$}i, qr{^ha'?ah$}i],
		[qr{^[Tt]}, qr{^tidak$}i, qr{^tak$}i],
	],
	[
		German => [qw( de deu ger )],
		qw( ja nein ),
		[qr{^[jJyY].*}, qr{^ja?$}i],
		[qr{^[nN].*}, qr{^n(?:ein)?$}i, qr{^y}i],
	],
	[
		Japanese => [qw( ja jpn )],
		q/はい/ => q/いいえ/,
		[qr{^([yYｙＹ]|はい|ハイ)}, q/はい/, q/ええ/, q/うん/, qr{^hai$}i, qr{^[eē]$}i, qr{^un$}i, qr{^n̄$}i],
		[qr{^([nNｎＮ]|いいえ|イイエ)}, q/いいえ/, q/いえ/, q/ううん/, q/違う/, qr{^[íi]?ie$}i, qr{^uun$}i, qr{^[n̄n]n$}i, qr{^chigau$}i],
	],
);

__END__

=encoding utf-8

=head1 NAME

Lingua::Boolean::Tiny - a smaller Lingua::Boolean, with support for more languages

=head1 SYNOPSIS

   use 5.010;
   use Lingua::Boolean::Tiny qw( boolean );
   
   my $response = "ja";  # German for "yes"
   
   if (boolean $response) {
      say "Yes!";
   }
   else {
      say "No!";
   }

=head1 DESCRIPTION

This module provides an API roughly compatible with L<Lingua::Boolean> but
has no non-core dependencies, and supports Perl 5.6.2+ (though Perl versions
earlier than 5.8 have pretty crummy Unicode support).

L<Lingua::Boolean::Tiny> includes hand-written support for the world's twelve
most commonly spoken languages (Standard Chinese, English, Castillian Spanish,
Hindi, Russian, Arabic, Portuguese, Bengali, French, Malay, German and
Japanese). L<Lingua::Boolean::Tiny::More> (which is auto loaded on demand)
provides support for almost any other language you can think of, but it may
not be to the same standard.

The string "1" is always true, and "0" is always false.

=head2 Object-Oriented Interface

=head3 Constructor

=over

=item C<< Lingua::Boolean::Tiny->new($lang) >>

Construct a new object supporting the given language. C<$lang> should be an
ISO language code (e.g. "en" for English or "zh" for Chinese).

If the language is not recognised, a warning is issued and an object with
support for just English is returned.

=item C<< Lingua::Boolean::Tiny->new(\@lang) >>

Construct a new object supporting the union of multiple languages.

Unrecognised languages are simply ignored.

Because a string could be interpreted differently in different languages
(e.g. "no" is a negative answer in English, but affirmative in Polish), the
order is significant - in case of ambiguities, the earlier language wins.

=item C<< Lingua::Boolean::Tiny->new() >>

Construct a new object supporting the union of the twelve main supported
languages.

=item C<< Lingua::Boolean::Tiny->new_strict($lang) >>

Like C<< new >>, but rather than defaulting to English, returns undef.

=back

You can alternatively construct objects using class names based on the
language name:

   my $indonesian = Lingua::Boolean::Tiny::Malay->new();

=head3 Methods

=over

=item C<< boolean($text) >>

Returns true if the text seems to indicate an affirmative answer (e.g. "yes");
returns false if the text seems to indicate an negitive answer (e.g. "no");
returns undef if the meaning of the text could not be established.

=item C<< languages >>

Returns the name of the languages supported by this object.

=item C<< langs >>

Returns the ISO codes of the languages supported by this object.

=item C<< yes >>

Returns a canonical "yes" string for the language. This method only exists
in objects which support a single language, not a union.

=item C<< no >>

Returns a canonical "no" string for the language. This method only exists
in objects which support a single language, not a union.

=item C<< yesno($boolean) >>

Returns a canonical "yes" or "no" string for the language, depending
upon whether C<$boolean> is true or false.  This method only exists in
objects which support a single language, not a union.

This method is effectively the inverse of the C<boolean> method.

=back

=head2 Functional Interface

This module provides several functions:

=over

=item C<< boolean $text, $lang >>

Shortcut for:

   Lingua::Boolean::Tiny->new($lang)->boolean($text)

C<< $lang >> is optional, but may be an ISO language code or a union thereof.

This function is exported by default.

=item C<< Lingua::Boolean::Tiny::languages() >>

Returns the full names of all supported languages.

This function is not exported.

=item C<< Lingua::Boolean::Tiny::langs() >>

Returns the ISO codes of all supported languages.

This function is not exported.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lingua-Boolean-Tiny>.

=head1 SEE ALSO

L<Lingua::Boolean>, L<String::BooleanSimple>, L<I18N::Langinfo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 CREDITS

A thousand thanks to Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 (cpan:DAXIM) for helping me with
L<Lingua::Boolean::Tiny::More> and improving some of the translations
in the main module.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

