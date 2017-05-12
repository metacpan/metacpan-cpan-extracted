package Lingua::FI::Kontti;

=pod

=head1 NAME

Lingua::FI::Kontti - Finnish Pig Latin (kontinkieli)

=head1 NIMI

Lingua::FI::Kontti - kontinkieli

=head1 SYNOPSIS

    use Lingua::FI::Kontti qw(kontita);

    print kontita("on meillä hauska täti"), "\n";
    # will print "kon ontti keillä montti kauska hontti koti täntti\n";

    print kontita("on meillä hauska täti", "tunkki"), "\n";
    # will print "tun onkki teillä munkki tauska hunkki tuti tänkki\n";

=head1 KÄYTTÖ

    use Lingua::FI::Kontti qw(kontita);

    print kontita("on meillä hauska täti"), "\n";
    # tulostaa "kon ontti keillä montti kauska hontti koti täntti\n";

    print kontita("on meillä hauska täti", "tunkki"), "\n";
    # tulostaa "tun onkki teillä munkki tauska hunkki tuti tänkki\n";

=head1 DESCRIPTION

Similar to Pig Latin of English

    English    We're gonna rock around the clock tonight
    Pig Latin  E'reway onnagay ockray aroundway ethay ockclay onighttay

there's a tongue-and-brain-twisting "secret" kids' language for
Finnish, called "kontinkieli" ("kontti speak").  In principle the
transformation is simple: the beginning of the word you want to
translate is switched with the beginning of the word "kontti".  In
practice it's a little bit more complicated that that because one has
to know the Finnish syllable division and vowel harmony rules.

With this module you can converse like a pro with Finnish kids.

In addition to the standard "secret key" I<kontti> you can use
any other word that according to Finnish syllable division rules
starts with CVCC (consonant-vowel-consonant-constant) syllable,
like for example I<kirppu>, I<linssi>, I<portti>, I<salkku>, I<turkki>.
Give the keyword as the second argument.

=head1 KUVAUS

Tällä modulilla voit kääntää suomea kontiksi.

"Salaisen avaimen" I<kontti> sijasta voit käyttää mitä tahansa sanaa joka
suomeksi tavutettuna alkaa KVKK-tavulla (konsonantti-vokaali-konsonantti-
konsonantti), kuten esimerkiksi I<kirppu>, I<linssi>, I<portti>, I<salkku>,
I<turkki>.  Anna avainsana toisena argumenttina.

Englannin puhujilla on samankaltainen lastenkieli, "sikalatina" (Pig Latin),
yllä esimerkki.

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Pig Latin translator

http://www.snowcrest.net/donnelly/piglatin.html

=item *

Rock Around the Clock

Bill Haley and the Comets

=back

=head1 KIITOKSET

=over 4

=item *

Sikalatinakäännin

http://www.snowcrest.net/donnelly/piglatin.html

=item *

Rock Around the Clock

Bill Haley and the Comets

=back

=head1 AUTHOR

Jarkko Hietaniemi <jhi@iki.fi>

=head1 COPYRIGHT

Copyright 2001 Jarkko Hietaniemi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 TEKIJÄ

Jarkko Hietaniemi <jhi@iki.fi>

=head1 TEKIJÄNOIKEUS

Copyright 2001 Jarkko Hietaniemi

=head1 LISENSSI

Tämä kirjastomoduli on vapaa; voit jakaa ja/tai muuttaa sitä samojen
ehtojen mukaisesti kuin Perliä itseään.

=cut

use strict;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = 0.02;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(kontita);

use Lingua::FI::Hyphenate 'tavuta';

my $vp = "aeiouyäåö";
my $vI = "AEIOUYÅÄÖ";
my $v  = "$vp$vI";
my $kp = "bcdfghjklmnpqrstvwxz";
my $kI = "BCDFGHJKLMNPQRSTVWXZ";
my $k  = "$kp$kI";
my $V  = "[$v]";
my $K  = "[$k]";
my $p  = "$vp$kp";
my $I  = "$vI$kI";

sub kontita {
    my $s = shift;

    my $kontti = @_ ? shift : "kontti";

    my @ak = tavuta($kontti);

    die "kontita: '$kontti' ei ala KVKK\n"
	unless $ak[0] =~ /^($K)($V)($K)($K)/;

    my $k1 = substr($kontti, 0, 1);
    my $v1 = substr($kontti, 1, 1);
    my $k2 = substr($kontti, 2, 1);
    my $k3 = substr($kontti, 3, 1);

    my $kontitettu = '';

    for my $s (split(/([$v$k]+)/, $s)) {
	$kontitettu .= $s, next unless $s =~ /[$v$k]/;
	my @k = @ak;
	my @t = tavuta($s);
	if ($t[0] =~ /^($K)($V)$/) {				# talo
	    $t[0] = $k1 . $v1 ;					# kolo
	    $k[0] = $1  . $2 . $k2 . $k3;			# tantti
	} elsif ($t[0] =~ /^($K)($V)($K)$/) {			# marras
	    $t[0] = $k1 . $v1  . $3;				# korras
	    $k[0] = $1  . $2 . $k2 . $k3;			# mantti
	} elsif ($t[0] =~ /^($K)($V)($V)$/) {
	    if ($2 eq $3) {					# saari
		$t[0] = $k1 . $v1 . $v1;			# koori
		$k[0] = $1  . $2  . $k2 . $k3;			# santti
	    } elsif ($3 eq $v1) {				# huomenta
		$t[0] = $k1 . $v1 . $2;				# koumenta
		$k[0] = $1  . $2  . $k2 . $k3;			# huntti
	    } else {						# taivas
		$t[0] = $k1 . $v1 . $3;				# koivas
		$k[0] = $1  . $2  . $k2 . $k3;			# tantti
	    }
	} elsif ($t[0] =~ /^($K)($V)($V)($K)$/) {
	    if ($2 eq $3) {					# saarni
		$t[0] = $k1 . $v1 . $v1 . $4;			# koorni
		$k[0] = $1  . $2  . $k2 . $k3;			# kantti
	    } else {						# hiekka
		$t[0] = $k1 . $2  . $3  . $4;			# kiekka
		$k[0] = $1  . $v1 . $k2 . $k3;			# hontti
	    }
	} elsif ($t[0] =~ /^($V)($K)$/) {			# alku
	    $t[0] = $k1 . $v1 . $2;				# kolku
	    $k[0] = $1  . $k2 . $k3;				# antti
	} elsif ($t[0] =~ /^($V)$/) {				# ase
	    $t[0] = $k1 . $v1;					# kose
	    $k[0] = $1  . $k2 . $k3;				# antti
	} elsif ($t[0] =~ /^($V)($V)$/) {
	    if ($1 eq $2) {					# aari
		$t[0] = $k1 . $v1 . $v1;			# koori
		$k[0] = $1  . $k2 . $k3;			# antti
	    } elsif ($2 eq 'ö') {				# yö
		$t[0] = $k1 . $2  . $1;				# köy
		$k[0] = $1  . $k2 . $k3;			# yntti
	    } else {						# autio
		$t[0] = $k1 . $v1 . $2;				# koutio
		$k[0] = $1  . $k2 . $k3;			# antti
	    }
	} elsif ($t[0] =~ /^($K)($V)($K)($K)$/) {		# tausta
	    $t[0] = $k1 . $v1  . $3  . $4;			# kousta
	    $k[0] = $1  . $2   . $k2 . $k3;			# tantti
	} elsif ($t[0] =~ /^($V)($V)($K)$/) {
	    if ($1 eq $2) {					# aarni
		$t[0] = $k1 . $v1 . $v1 . $3;			# koorni
		$k[0] = $1  . $k2 . $k3;			# antti
	    } else {						# aukko
		$t[0] = $k1 . $v1 . $2  . $3;			# koukko
		$k[0] = $1  . $k2 . $k3;			# antti
	    }
	} elsif ($t[0] =~ /^($V)($K)($K)$/) {			# arkku
	    $t[0] = $k1 . $v1  . $2  . $3;			# korkku
	    $k[0] = $1  . $k2 . $k3;				# antti
	} elsif ($t[0] =~ /^($K)($K)($V)$/) {			# trapetsi
	    $t[0] = $k1 . $v1;					# kopetsi
	    $k[0] = $1  . $2  . $3 . $k2  . $k3;		# trantti
	} elsif ($t[0] =~ /^($K)($K)($V)($K)$/) {		# traktori
	    $t[0] = $k1 . $2  . $v1 . $4;			# kroktori
	    $k[0] = $1  . $3  . $k2 . $k3;			# tantti
	} elsif ($t[0] =~ /^($K)($K)($V)($V)$/) {
	    if ($3 eq $4) {					# traani
		$t[0] = $k1 . $v1 . $v1;			# kooni
		$k[0] = $1  . $2  . $3  .  $k2 . $k3;		# trantti
	    } else {						# trauma
		$t[0] = $k1 . $v1 . $4;				# kouma
		$k[0] = $1  . $2  . $3  .  $k2 . $k3;		# trantti
	    }
	} elsif ($t[0] =~ /^($K)($K)($V)($V)($K)$/) {		# truantti
	    $t[0] = $k1 . $v1 . $4  . $5;			# koantti
	    $k[0] = $1  . $2 . $3  . $k2 . $k3;			# trantti
	} elsif ($t[0] =~ /^($K)($K)($V)($K)($K)$/) {		# transsi
	    $t[0] = $k1 . $v1 . $4  . $5;			# konssi
	    $k[0] = $1  . $2  . $3  . $k2 . $k3;		# trantti
	}
	
	# vokaalisointu

	@t = map { tr/aouAOU/äöyÄÖY/; $_ } @t if grep { /[yäöYÄÖ]/ } @t;
	@k = map { tr/aouAOU/äöyÄÖY/; $_ } @k if grep { /[yäöYÄÖ]/ } @k;

	# Iso alkukirjain
	my $a = substr($t[0], 0, 1);
	my $b = substr($k[0], 0, 1);
	if ($a =~ /^[$p]/ && $b =~ /^[$I]/) {
	    substr($t[0], 0, 1) = substr($I, index($p, $a), 1);
	    substr($k[0], 0, 1) = substr($p, index($I, $b), 1);
	}

	$kontitettu .= join("", @t) . " " . join("", @k)
    }

    return $kontitettu;
}

1;
