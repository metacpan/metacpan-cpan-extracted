package Getopt::EX::i18n;
use 5.014;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.03";

=encoding utf-8

=head1 NAME

Getopt::EX::i18n - General i18n module

=head1 SYNOPSIS

command -Mi18n [ options ]

=head1 DESCRIPTION

This module B<i18n> provide an easy way to set locale environment
before executing arbitrary command.  Locale list is taken from the
system by C<locale -a> command.  Next list is a sample locales
available on macOS 10.15 (Catalina).

    af_ZA    Afrikaans / South Africa
    am_ET    Amharic / Ethiopia
    be_BY    Belarusian / Belarus
    bg_BG    Bulgarian / Bulgaria
    ca_ES    Catalan; Valencian / Spain
    cs_CZ    Czech / Czech Republic
    da_DK    Danish / Denmark
    de_AT    German / Austria
    de_CH    German / Switzerland
    de_DE    German / Germany
    el_GR    Greek, Modern (1453-) / Greece
    en_AU    English / Australia
    en_CA    English / Canada
    en_GB    English / United Kingdom
    en_IE    English / Ireland
    en_NZ    English / New Zealand
    en_US    English / United States
    es_ES    Spanish / Spain
    et_EE    Estonian / Estonia
    eu_ES    Basque / Spain
    fi_FI    Finnish / Finland
    fr_BE    French / Belgium
    fr_CA    French / Canada
    fr_CH    French / Switzerland
    fr_FR    French / France
    he_IL    Hebrew / Israel
    hr_HR    Croatian / Croatia
    hu_HU    Hungarian / Hungary
    hy_AM    Armenian / Armenia
    is_IS    Icelandic / Iceland
    it_CH    Italian / Switzerland
    it_IT    Italian / Italy
    ja_JP    Japanese / Japan
    kk_KZ    Kazakh / Kazakhstan
    ko_KR    Korean / Korea, Republic of
    lt_LT    Lithuanian / Lithuania
    nl_BE    Dutch / Belgium
    nl_NL    Dutch / Netherlands
    no_NO    Norwegian / Norway
    pl_PL    Polish / Poland
    pt_BR    Portuguese / Brazil
    pt_PT    Portuguese / Portugal
    ro_RO    Romanian / Romania
    ru_RU    Russian / Russian Federation
    sk_SK    Slovak / Slovakia
    sl_SI    Slovenian / Slovenia
    sr_YU    Serbian / Yugoslavia
    sv_SE    Swedish / Sweden
    tr_TR    Turkish / Turkey
    uk_UA    Ukrainian / Ukraine
    zh_CN    Chinese / China
    zh_HK    Chinese / Hong Kong
    zh_TW    Chinese / Taiwan, Province of China

As for Japanese locale C<ja_JP>, following options are defined by
default, and set C<LANG> environment as C<ja_JP>.

    LOCALE:   --ja_JP  (raw)
              --ja-JP  (dash)
              --jaJP   (long)
              --jajp   (lclong)
    LANGUAGE: --ja     (lang)
    COUNTRY:  --JP     (country)
              --jp     (country)

Short language option (C<--ja>) is defined in the alphabetical order
of the country code, so the option C<--en> is assigned to C<en_AU>.
But if the same country name is found as language, it takes
precedence; German is used in three locales (C<de_AT>, C<de_CH>,
C<de_DE>) but option C<--de> is defined as C<de_DE>.

Country options (C<--JP> and C<--jp>) are defined only when the same
language option is not defined by other entry, and only single entry
can be found for the country.  Option for Switzerland is not defined
because there are three entries (C<de_CH>, C<fr_CH>, C<it_CH>).
Country option C<--AM> is assigned to C<hy_AM>, but language option
C<--am> is assigned to C<am_ET>.

=head1 OPTION

Option parameter can be given with B<setopt> function called with
module declaration.

    command -Mi18n::setopt(name[=value])

=over 7

=item B<raw>

=item B<dash>

=item B<long>

=item B<lclong>

=item B<lang>

=item B<country>

These parameter tells which option is defined.  All options are
enabled by default.  You can disable country option like this:

    command -Mi18n::setopt(country=0)

    command -Mi18n::setopt=country=0

=item B<verbose>

Show locale information.

    $ optex -Mi18n::setopt=verbose date --it
    LANG=it_IT (Italian / Italy)
    Gio  4 Giu 2020 16:47:33 JST

=item B<list>

Show option list.

=item B<listopt>=I<option>

Set the option to display option list and exit.  You can introduce a
new option B<-l> to show available option list:

    -Mi18n::setopt(listopt=-l)

=item B<prefix>=I<string>

Specify prefix string.  Default is C<-->.

=back

=head1 SEE ALSO

=over 7

=item B<optex>

You can execute arbitrary command on the system getting the benefit of
B<Getopt::EX> using B<optex>.

    $ optex -Mi18n cal 2020 --am

L<https://github.com/kaz-utashiro/optex>

L<https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6>

=back

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro E<lt>kaz@utashiro.comE<gt>

=cut

use Getopt::EX::i18n::iso3361 qw(%iso3361);
use Getopt::EX::i18n::iso639 qw(%iso639);

my %opt = (
    raw     => 1,
    dash    => 1,
    long    => 1,
    lclong  => 1,
    lang    => 1,
    country => 1,
    verbose => 0,
    list    => 0,
    prefix  => '--',
    listopt => undef,
    );

my $module;

sub initialize {
    return if state $called++;
    my($obj, $argv) = @_;
    $module = $obj;
    setup();
}

my @locale;
my %lang;
my %cc;
my %opthash;

sub finalize {
    my($obj, $argv) = @_;
    for my $locale (sort @locale) {
	$locale =~ /^(?<lang>\w\w)_(?<cc>\w\w)$/ or next;
	my($lang, $cc) = @+{qw(lang cc)};;
	my @list;
	push @list, "$locale"   if $opt{raw};
	push @list, "$lang-$cc" if $opt{dash};
	push @list, "$lang$cc"  if $opt{long};
	$cc = lc $cc;
	push @list, "$lang$cc"  if $opt{lclong};
	if ($opt{lang}) {
	    if (!$opthash{$lang} or $lang eq $cc) {
		push @list, $lang;
	    }
	}
	if ($opt{country}) {
	    if ($lang eq $cc or @{$cc{$cc}} == 1) {
		push @list, uc $cc;
		push @list, $cc if not $lang{$cc};
	    }
	}
	for (@list) {
	    $opthash{$_} = $locale;
	}
    }

    $obj->mode(function => 1);
    if (my $listopt = $opt{listopt}) {
	$obj->setopt($listopt, "&options(show,exit)");
    }
    &options(set => 1, show => $opt{list});
    return;
}

sub localeinfo {
    $_[0]=~ /^(?<lang>[a-z][a-z])_(?<cc>[A-Z][A-Z])$/;
    ( $+{lang} && $iso639{$+{lang}} || 'UNKNOWN' ,
      $+{cc}   && $iso3361{$+{cc}}  || 'UNKNOWN' );
}

sub options {
    my %arg = (
	set  => 0, # set option
	show => 0, # print option
	exit => 0, # exit at the end
	@_);
    my $optwidth = length($opt{prefix}) + 5;
    for my $opt (sort { lc $a cmp lc $b } keys %opthash) {
	my $option = $opt{prefix} . $opt;
	my $call = "&setenv(LANG=$opthash{$opt})";
	$module->setopt($option, $call) if $arg{set};
	if ($arg{show}) {
	    my($lang, $cc) = localeinfo($opthash{$opt});
	    printf "option %-*s %s # %s / %s\n",
		$optwidth, $option, $call, $lang, $cc;
	}
    }
    exit if $arg{exit};
    return ();
}

sub setup {
    return if state $called++;
    grep { -x "$_/locale" } split /:/, $ENV{PATH} or return;
    for (`locale -a`) {
	/^((\w\w)_(\w\w))$/ or next;
	my($name, $lang, $cc) = ($1, $2, lc $3);
	push @locale,           $name;
	push @{ $lang{$lang} }, $name;
	push @{ $cc{$cc}     }, $name;
    }
}

sub locales {
    chomp( my @locale = `locale -a` );
    grep { /^\w\w_\w\w$/ } @locale;
}

sub setopt {
    %opt = (%opt, @_);
}

sub setenv {
    while (@_ >= 2) {
	my($key, $value) = splice @_, 0, 2;
	if ($opt{verbose}) {
	    my($lang, $cc) = localeinfo $value;
	    warn "$key=$value ($lang / $cc)\n";
	}
	$ENV{$key} = $value;
    }
    return ();
}

1;

__DATA__
