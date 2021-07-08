use v5.14;
package Getopt::EX::i18n;

our $VERSION = '0.09';

use warnings;
use Data::Dumper;

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

    LOCALE:     --ja_JP  (raw)
                --ja-JP  (dash)
                --jaJP   (long)
                --jajp   (long_lc)
    LANGUAGE:   --ja     (language)
    TERRITORY:  --JP     (territory)
                --jp     (territory_lc)

Short language option (C<--ja>) is defined in the alphabetical order
of the territory code, so the option C<--en> is assigned to C<en_AU>.
But if the same territory name is found as language, it takes
precedence; German is used in three locales (C<de_AT>, C<de_CH>,
C<de_DE>) but option C<--de> is defined as C<de_DE>.

Territory options (C<--JP> and C<--jp>) are defined only when the same
language option is not defined by other entry, and only single entry
can be found for the territory.  Option for Switzerland is not defined
because there are three entries (C<de_CH>, C<fr_CH>, C<it_CH>).
Territory option C<--AM> is assigned to C<hy_AM>, but language option
C<--am> is assigned to C<am_ET>.

=head1 OPTION

Option parameter can be given with B<setopt> function called with
module declaration.

    command -Mi18n::setopt(name[=value])

=over 7

=item B<raw>

=item B<dash>

=item B<long>

=item B<long_lc>

=item B<lang>

=item B<territory>

=item B<territory_lc>

These parameter tells which option is defined.  All options are
enabled by default.  You can disable territory option like this:

    command -Mi18n::setopt(territory=0,territory_lc=0)

    command -Mi18n::setopt=territory=0,territory_lc=0

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

=head1 BUGS

Support only UTF-8.

=head1 SEE ALSO

=over 7

=item L<Getopt::EX>

L<https://github.com/kaz-utashiro/Getopt-EX>

=item L<optex|App::optex>

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

my %opt = (
    raw          => 1,
    dash         => 1,
    long         => 1,
    long_lc      => 1,
    language     => 1,
    territory    => 1,
    territory_lc => 1,
    verbose      => 0,
    list         => 0,
    prefix       => '--',
    listopt      => undef,
    );

my $module;

sub initialize {
    return if state $called++;
    my($obj, $argv) = @_;
    $module = $obj;
    setup();
}

my @locale;
my %locale;
my %lang;
my %cc;
my %opthash;

package LocaleObj {
    sub new {
	my($class, %hash) = @_;
	bless \%hash, $class;
    }
    sub name { $_[0]->{name} // '' }
    sub lang { $_[0]->{lang} // '' }
    sub cc   { $_[0]->{cc}   // '' }
    sub create {
	(my $class, local $_) = @_;
	/^(?<name>(?<lang>[a-z][a-z])_(?<cc>[A-Z][A-Z]))/ or die;
	$class->new(%+);
    }
    use Getopt::EX::i18n::iso639 qw(%iso639);
    use Getopt::EX::i18n::iso3361 qw(%iso3361);
    sub lang_name { $iso639 {+shift->lang} || 'UNKNOWN' }
    sub cc_name   { $iso3361{+shift->cc}   || 'UNKNOWN' }
}

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
	push @list, "$lang$cc"  if $opt{long_lc};
	if ($opt{language}) {
	    if (!$opthash{$lang} or $lang eq $cc) {
		push @list, $lang;
	    }
	}
	if ($lang eq $cc or @{$cc{$cc}} == 1) {
	    push @list, uc $cc if $opt{territory};
	    push @list,    $cc if $opt{territory_lc} and !$lang{$cc};
	}
	for (@list) {
	    $opthash{$_} = LocaleObj->create($locale);
	}
    }

    $obj->mode(function => 1);
    if (my $listopt = $opt{listopt}) {
	$obj->setopt($listopt, "&options(show,exit)");
    }
    &options(set => 1, show => $opt{list});
    return;
}

sub options {
    my %arg = (
	set  => 0, # set option
	show => 0, # print option
	exit => 0, # exit at the end
	@_);
    my @keys = do {
	map  { $_->[0] }
	sort { $a->[1] cmp $b->[1] ||
	       lc $a->[0] cmp lc $b->[0] || $a->[0] cmp $b->[0] }
	map  { [ $_, $opthash{$_}->cc ] }
	keys %opthash;
    };
    for my $opt (@keys) {
	my $obj = $opthash{$opt};
	my $option = $opt{prefix} . $opt;
	my $name = $obj->name;
	my $locale = $locale{$name};
	my $call = "&setenv(LANG=$locale)";
	$module->setopt($option, $call) if $arg{set};
	if ($arg{show}) {
	    printf "option %-*s %s # %s / %s\n",
		(state $optwidth = length($opt{prefix}) + length($name)),
		$option, $call,
		$obj->cc_name, $obj->lang_name;
	}
    }
    exit if $arg{exit};
    return ();
}

sub setup {
    return if state $called++;
    grep { -x "$_/locale" } split /:/, $ENV{PATH} or return;
    for (`locale -a`) {
	chomp;
	/^(([a-z][a-z])_([A-Z][A-Z]))(?=(?i:$|\.utf))/ or next;
	my($name, $lang, $cc) = ($1, $2, lc $3);
	if (my $last = $locale{$name}) {
	    $locale{$name} = $_ if length($_) < length($last);
	    next;
	}
	$locale{$name} = $_;
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
	    my $l = LocaleObj->create($value);
	    warn sprintf("%s=%s (%s / %s)\n",
			 $key, $value, $l->lang_name, $l->cc_name);
	}
	$ENV{$key} = $value;
    }
    return ();
}

1;

__DATA__
