package Egg::Plugin::Filter::Plugin::Japanese;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Japanese.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Egg::Plugin::Filter;
use Jcode;

our $VERSION = '3.00';

our($Zspace, $RZspace);

my $EGG= 0;
my $VAL= 1;
my $ARG= 2;

sub _setup_filters {
	my($class, $e)= @_;

	$Zspace  || die q{ I want setup '$Zspace'.  };
	$RZspace || die q{ I want setup '$RZspace'. };

	my $filters= \%Egg::Plugin::Filter::Filters;

	$filters->{h2z}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}= Jcode->new($_[$VAL])->h2z;
	  };

	$filters->{a2z}= sub {
		return 0 unless defined(${$_[$VAL]});
		my $w= Jcode->new($_[$VAL])->h2z;
		$w->tr('A-Z', '£Á-£Ú');
		$w->tr('a-z', '£Á-£Ú');
		$w->tr('0-9', '£°-£¹');
		${$_[$VAL]}= $w;
	  };

	$filters->{j_trim}= sub {
		return 0 unless defined(${$_[$VAL]});
		1 while ${$_[$VAL]}=~s{^(?:\s|$Zspace)+} []sg;
		1 while ${$_[$VAL]}=~s{(?:\s|$Zspace)$} []sg;
	  };

	$filters->{j_hold}= sub {
		defined(${$_[$VAL]}) and ${$_[$VAL]}=~s{(?:\s|$Zspace)+} []sg;
	  };

	$filters->{j_strip}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?:\s|$Zspace)+} [ ]sg;
	  };

	$filters->{j_strip_j}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?:\s|$Zspace)+} [$RZspace]sge;
	  };

	$filters->{j_strip_blank}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?: |$Zspace)+} [ ]sg;
	  };

	$filters->{j_strip_blank_j}= sub {
		return 0 unless defined(${$_[$VAL]});
		${$_[$VAL]}=~s{(?: |$Zspace)+} [$RZspace]sge;
	  };

	$filters->{j_text}= sub {
		my($e, $v, $a)= @_;
		$filters->{h2z}->($e, $v);
		$filters->{strip_tab}->($e, $v);
		$filters->{j_trim}->($e, $v);
		$filters->{j_strip_blank}->($e, $v);
		$filters->{crlf}->($e, $v, [$a->[0] || 3]);
	  };

	$filters->{j_fold}= sub {
		my($e, $v, $a)= @_;
		my $len= $a->[0] || 72;
		my $text;
		for (split /\n/, ${$_[$VAL]}) {
			$text.= $_ ? join("\n", Jcode->new(\$_)->jfold($len)). "\n": "\n";
		}
		chomp $text;
		${$_[$VAL]}= $text;
	  };

	@_;
}

1;

__END__

=head1 NAME

Egg::Plugin::Filter::Plugin::Japanese - Filter processing for Japanese.

=head1 SYNOPSIS

  package MyApp;
  use Egg qw/ Filter /;
  
  __PACKAGE__->egg_startup(
   ..........
   ....
   plugin_filter => {
     plugins=> [qw/ Japanese::EUC /],
     },
   );
  
  $e->filter(
    name    => [qw/ hold_html h2z a2z j_strip j_trim /],
    message => [qw/ escape_html j_text:3 j_fold:72 /],
    );

=head1 DESCRIPTION

It is a plugin for L<Egg::Plugin::Filter> that does the filter processing for Japanese.

It is made to use by setting plugin of the configuration of L<Egg::Plugin::Filter>.

   plugin_filter => {
     plugins=> [qw/ Japanese::UTF8 /],
     },

[[Egg::Plugin::Filter::Japanese::UTF8]]¡¢
[[Egg::Plugin::Filter::Japanese::EUC]]¡¢
[[Egg::Plugin::Filter::Japanese::Shift_JIS]]

=head1 FILTERS

=head3 h2z

The normal-width katakana is made multi byte character.

see [[Jcode]]

=head3 a2z

The alphanumeric character is made multi byte character.

The tr method of [[Jcode]] is used.

=head3 j_trim

'trim' corresponding to the multi byte space is done.

=head3 j_hold

'hold' corresponding to the multi byte space is done.

=head3 j_strip

'strip' corresponding to the multi byte space is done.
It is replaced with half angle space.

=head3 j_strip_j

'strip' corresponding to the multi byte space is done.
It is replaced with the multi byte space.

=head3 j_strip_blank

'strip' is done for only half angle space and the em-size space.
It is replaced with half angle space.

=head3 j_strip_blank_j

'strip' is done for only half angle space and the em-size space.
It is replaced with the multi byte space.

=head3 j_text [:NUMBER]

'h2z' , 'strip_tab' , 'j_trim', 'j_strip_blank', 'crlf' are done at a time.

In NUMBER, the default when unspecifying it by the figure passed to crlf is three.

  $e->filter(
    hoge => [qw/ j_text:2 /],
    );

Using it by inputting textarea is convenient.

=head3 j_fold [:NUMBER]

The length of the character a line is arranged.

NUMBER is a figure passed to the jfold method of Jcode, and default is 72.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::Filter>,
L<Egg::Plugin::Filter::Plugin::UTF8>,
L<Egg::Plugin::Filter::Plugin::Shift_JIS>,
L<Jcode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

