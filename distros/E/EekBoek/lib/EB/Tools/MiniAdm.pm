#! perl --			-*- coding: utf-8 -*-

use utf8;

# MiniAdm.pm -- 
# Author          : Johan Vromans
# Created On      : Sun Oct  4 15:11:05 2009
# Last Modified By: Johan Vromans
# Last Modified On: Fri May  6 13:44:19 2011
# Update Count    : 111
# Status          : Unknown, Use with caution!

package main;

use strict;
use warnings;
use Encode;

our$cfg;

package EB::Tools::MiniAdm;

#use EB::Config;
use EB;

sub donotclobber {
    my ( $self, $opts ) = @_;

    my @files = qw( schema.dat opening.eb mutaties.eb relaties.eb );
    push( @files, $cfg->std_config );
    my $tally = 0;
    foreach ( @files ) {
	$tally++ if -f $_;
    }

    if ( $tally == @files ) {
	warn("?"._T("GESTOPT: Er is al een administratie aangemaakt")."\n");
	return;
    }
    if ( $tally ) {
	warn("?"._T("GESTOPT: Er is al een administratie gedeeltelijk aangemaakt")."\n");
	return;
    }
    return 1;
}

sub build {
    my ( $self, $opts ) = @_;

    return unless $self->donotclobber;
    return unless $self->sanitize($opts);

    # Generate.
    $self->generate_config($opts);
    $self->generate_schema($opts);
    $self->generate_relaties($opts);
    $self->generate_opening($opts);
    $self->generate_mutaties($opts);

    1;
}

sub sanitize {
    my ( $self, $opts ) = @_;

    $opts->{adm_naam}         ||= _T("Demo administratie");
    $opts->{adm_btwperiode}   ||= "jaar" if $opts->{has_btw};
    $opts->{adm_begindatum}   ||= 1900 + (localtime(time))[5];
    $opts->{adm_boekjaarcode} ||= 1900 + (localtime(time))[5];

    for ( qw(naam boekjaarcode) ) {
	$opts->{ "adm_$_" } =~ s/"/_/g;
    }

    $opts->{db_naam}          ||= "demoadm";
    $opts->{db_driver}        ||= "sqlite";

    1;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Encode;

sub generate_file {
    my ( $self, $file, $type, $opts, $writer ) = @_;

    if ( ! $opts->{_zip} && $opts->{template} ) {
	$opts->{_zip} = Archive::Zip->new();
	die( "?".__x("Probleem met het benaderen van {file}: {err}",
		     file => $opts->{template}, err => "$!")."\n" )
	  unless $opts->{_zip}->read( $opts->{template} ) == AZ_OK;
    }

    my $m;
    if ( $opts->{_zip} ) {
	$m = $opts->{_zip}->memberNamed($file);
    }

    my $fd;
    if ( $opts->{_zip} && $m ) {
	my $data = $opts->{_zip}->contents($m);
	die( "?".__x("Probleem met het aanmaken van {file}: Zip error",
		     file => $file)."\n" ) unless $data;

	#### TODO: Make more generic.
	if ( $file eq "opening.eb" ) {
	    for ( $data ) {
		s/^(\s*adm_naam\s+).*$        /$1"$opts->{adm_naam}"        /mgx;
		s/^(\s*adm_btwperiode\s+).*$  /$1"$opts->{adm_btwperiode}"  /mgx;
		s/^(\s*adm_begindatum\s+).*$  /$1"$opts->{adm_begindatum}"  /mgx;
		s/^(\s*adm_boekjaarcode\s+).*$/$1"$opts->{adm_boekjaarcode}"/mgx;
	    }
	}

	$data =~ s/\r//g;
	$data = decode_utf8($data);
	$data = [ split(/\n/, $data) ];
	$writer = sub { print { $fd } $_, "\n" foreach @$data };
	$type = undef;
    }

    open( $fd, '>:encoding(utf-8)', $file )
      or die( "?".__x("Probleem met het aanmaken van {file}: {err}",
		      file => $file, err => "$!")."\n" );
    if ( $type ) {
	print { $fd } ("# EekBoek $type\n",
		       "# Content-Type: text/plain; charset = UTF-8\n\n");
    }

    if ( $writer ) {
	$writer->( $self, $fd );
    }

    close( $fd )
      or die( "?".__x("Probleem met het afsluiten van {file}: {err}",
		      file => $file, err => "$!")."\n" );
}

sub generate_config {
    my ( $self, $opts ) = @_;

    return if exists $opts->{create_config} && !$opts->{create_config};

    my $fmt = "%-10.10s = %s\n";

    $self->generate_file
      ( $cfg->std_config, undef, $opts,
	sub {
	    my ( $self, $fd ) = @_;
	    if ( $opts->{lang} ) {
		print { $fd } ("[locale]\n");
		printf { $fd } ( $fmt, "lang", $opts->{lang} );
		print { $fd } ("\n");
	    }
	    print { $fd } ("[database]\n");
	    printf { $fd } ( $fmt, "name", $opts->{db_naam} );
	    foreach ( qw( driver host port user password path ) ) {
		next unless defined $opts->{"db_$_"};
		printf { $fd } ( $fmt, $_, $opts->{"db_$_"} )
	    }
	  }
      );
}

sub generate_schema {
    my ( $self, $opts ) = @_;

    return if exists $opts->{create_schema} && !$opts->{create_schema};

    # has_btw
    # has_crediteuren
    # has_crediteuren
    # has_kas
    # has_bank

    $self->generate_file
      ( "schema.dat", _T("Rekeningschema"), $opts,
	sub {
	    my ( $self, $fd ) = @_;
	    print { $fd } ( <<'EOD' );
# Dit bestand definiëert alle vaste gegevens van een administratie of
# groep administraties: het rekeningschema (balansrekeningen en
# resultaatrekeningen), de dagboeken en de BTW tarieven.
#
# Algemene syntaxregels:
#
# * Lege regels en regels die beginnen met een hekje # worden niet
#   geïnterpreteerd.
# * Een niet-ingesprongen tekst introduceert een nieuw onderdeel.
# * Alle ingesprongen regels zijn gegevens voor dat onderdeel.

# REKENINGSCHEMA
#
# Het rekeningschema is hiërarchisch opgezet volgende de beproefde
# methode Bakker. De hoofdverdichtingen lopen van 1 t/m 9, de
# verdichtingen t/m 99. De grootboekrekeningen zijn verdeeld in
# balansrekeningen en resultaatrekeningen.
#
# De omschrijving van de grootboekrekeningen wordt voorafgegaan door
# een vlaggetje, een letter die resp. Debet/Credit (voor
# balansrekeningen) en Kosten/Omzet/Neutraal (voor resultaatrekeningen)
# aangeeft. De omschrijving wordt indien nodig gevolgd door extra
EOD

	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<'EOD' );
# informatie. Voor grootboekrekeningen kan op deze wijze de BTW
# tariefstelling worden aangegeven die op deze rekening van toepassing
# is:
#
#   :btw=nul
#   :btw=hoog
#   :btw=laag
#   :btw=privé
#   :btw=anders
EOD
	    }
	    else {
		print { $fd } ( <<'EOD' );
# informatie.
EOD
	    }
	    print { $fd } ( <<'EOD' );
#
# Ook is het mogelijk aan te geven dat een rekening een koppeling
# (speciale betekenis) heeft met :koppeling=xxx. De volgende koppelingen
# zijn mogelijk:
#
EOD
	    if ( $opts->{has_crediteuren} ) {
		print { $fd } ( <<'EOD' );
#   crd		de standaard tegenrekening (Crediteuren) voor inkoopboekingen
EOD
	    }
	    if ( $opts->{has_debiteuren} ) {
		print { $fd } ( <<'EOD' );
#   deb		de standaard tegenrekening (Debiteuren) voor verkoopboekingen
EOD
	    }
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<'EOD' );
#   btw_ih	de rekening voor BTW boekingen voor inkopen, hoog tarief
#   btw_il	idem, laag tarief
#   btw_vh	idem, verkopen, hoog tarief
#   btw_vl	idem, laag tarief
#   btw_ph	idem, privé, hoog tarief
#   btw_pl	idem, laag tarief
#   btw_ah	idem, anders, hoog tarief
#   btw_al	idem, laag tarief
#   btw_ok	rekening voor de betaalde BTW
EOD
	    }
	    print { $fd } ( <<'EOD' );
#   winst	rekening waarop de winst wordt geboekt
#
# De koppeling winst is verplicht en moet altijd in een administratie
# voorkomen in verband met de jaarafsluiting.
EOD
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<'EOD' );
# De koppelingen voor BTW moeten worden opgegeven indien BTW
# van toepassing is op de administratie.
EOD
	    }
	    print { $fd } ( <<'EOD' );
# De koppelingen voor Crediteuren en Debiteuren moeten worden
# opgegeven indien er inkoop dan wel verkoopdagboeken zijn die gebruik
# maken van de standaardwaarden (dus zelf geen tegenrekening hebben
# opgegeven).

# Normaal lopen hoofdverdichtingen van 1 t/m 9, en verdichtingen
# van 10 t/m 99. Indien daarvan wordt afgeweken kan dit worden opgegeven
# met de opdracht "Verdichting". De twee getallen geven het hoogste
# nummer voor hoofdverdichtingen resp. verdichtingen.

Verdichting 9 99

# De nummers van de grootboekrekeningen worden geacht groter te zijn
# dan de maximale verdichting. Daarvan kan worden afgeweken door
# middels voorloopnullen de _lengte_ van het nummer groter te maken
# dan de lengte van de maximale verdichting. Als bijvoorbeeld 99 de
# maximale verdichting is, dan geeft 001 een grootboekrekening met
# nummer 1 aan.

Balansrekeningen

  1  Vaste Activa
     11  Materiële vaste activa

  2  Vlottende activa
     21  Handelsvoorraden
     22  Vorderingen
EOD
	    if ( $opts->{has_debiteuren} ) {
		print { $fd } ( <<'EOD' );
         2200  D   Debiteuren                                 :koppeling=deb
EOD
	    }
	    print { $fd } ( <<'EOD' );
     23  Liquide middelen
EOD
	    if ( $opts->{has_kas} ) {
		print { $fd } ( <<"EOD" );
         2300  D   Kas
EOD
	    }
	    if ( $opts->{has_bank} ) {
		print { $fd } ( <<"EOD" );
         2320  D   Bank
EOD
	    }
	print { $fd } ( <<"EOD" );
         2390  D   Kruisposten

  3  Eigen vermogen
     31  Kapitaal
         3100  C   Kapitaal de heer/mevrouw                   :koppeling=winst
         3110  C   Privé stortingen
         3120  D   Privé opnamen

  4  Vreemd vermogen
     41  Leveranciers kredieten
EOD
	    if ( $opts->{has_crediteuren} ) {
		print { $fd } ( <<'EOD' );
         4100  C   Crediteuren                                :koppeling=crd
EOD
	    }
	    print { $fd } ( <<'EOD' );
     42  Belastingen & soc. lasten
EOD
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<"EOD" );
         4200  C   BTW Verkoop Hoog                           :koppeling=btw_vh
         4210  C   BTW Verkoop Laag                           :koppeling=btw_vl
         4212  C   BTW Verkoop Privé                          :koppeling=btw_vp
         4214  C   BTW Verkoop Anders                         :koppeling=btw_va
         4220  D   BTW Inkoop Hoog                            :koppeling=btw_ih
         4230  D   BTW Inkoop Laag                            :koppeling=btw_il
         4232  D   BTW Inkoop Privé                           :koppeling=btw_ip
         4234  D   BTW Inkoop Anders                          :koppeling=btw_ia
         4290  C   Omzetbelasting betaald                     :koppeling=btw_ok
EOD
	    }

	    my $btw_hoog = "";
	    my $btw_laag = "";
	    if ( $opts->{has_btw} ) {
		$btw_hoog = ":btw=hoog";
		$btw_laag = ":btw=laag";
	    }
	    print { $fd } ( <<"EOD" );

Resultaatrekeningen

  6  Kosten
     61  Verkoopkosten
     62  Huisvestingskosten
     63  Bedrijfsvoering
     67  Contributies & abonnementen
     69  Algemene kosten
EOD
	    if ( $opts->{has_bank} ) {
		print { $fd } ( <<"EOD" );
         6980  K   Bankkosten
EOD
	    }
	    if ( $opts->{has_kas} ) {
		print { $fd } ( <<"EOD" );
         6981  K   Kasverschillen
EOD
	    }
	    print { $fd } ( <<"EOD" );

  8  Bedrijfsopbrengsten
     89	 Omzet Diversen
EOD
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<'EOD' );
         8900  O   Omzet diversen BTW hoog                    :btw=hoog
         8910  O   Omzet diversen BTW laag                    :btw=laag
         8920  O   Omzet diversen BTW vrij
EOD
	    }
	    print { $fd } ( <<"EOD" );

  9  Financiële baten & lasten
     91  Rente baten
EOD
	    if ( $opts->{has_bank} ) {
		print { $fd } ( <<"EOD" );
         9120  O   Rente bate Bank
EOD
	    }
	    print { $fd } ( <<"EOD" );
     92  Rente- en overige financiële lasten
EOD
	    if ( $opts->{has_bank} ) {
		print { $fd } ( <<"EOD" );
         9220  K   Rente last Bank
EOD
	    }
	    print { $fd } ( <<"EOD" );
     93  Overige baten
EOD
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<"EOD" );
         9390  O   Kleine ondernemersregeling
EOD
	    }
	    print { $fd } ( <<"EOD" );

# DAGBOEKEN
#
# EekBoek ondersteunt vijf soorten dagboeken: Kas, Bank, Inkoop,
# Verkoop en Memoriaal. Er kunnen een in principe onbeperkt aantal
# dagboeken worden aangemaakt.
# In de eerste kolom wordt de korte naam (code) voor het dagboek
# opgegeven. Verder moet voor elk dagboek worden opgegeven van welk
# type het is. Voor dagboeken van het type Kas en Bank moet een
# tegenrekening worden opgegeven, voor de overige dagboeken mag een
# tegenrekening worden opgegeven.
# De optie :dc kan worden gebruikt om aan te geven dat het journaal
# voor dit dagboek de boekstuktotalen in gescheiden debet en credit
# moet tonen.

Dagboeken

EOD
	    if ( $opts->{has_crediteuren} ) {
		print { $fd } ( <<"EOD" );
  I     Inkoop                :type=inkoop
EOD
	    }
	    if ( $opts->{has_debiteuren} ) {
		print { $fd } ( <<"EOD" );
  V     Verkoop               :type=verkoop
EOD
	    }
	    if ( $opts->{has_kas} ) {
		print { $fd } ( <<"EOD" );
  K     Kas                   :type=kas        :rekening=2300
EOD
	    }
	    if ( $opts->{has_bank} ) {
		print { $fd } ( <<"EOD" );
  B     Bank                  :type=bank       :rekening=2320
EOD
	    }
	    print { $fd } ( <<"EOD" );
  M     Memoriaal             :type=memoriaal
EOD
	    if ( $opts->{has_btw} ) {
		print { $fd } ( <<"EOD" );

# BTW TARIEVEN
#
# Er zijn vijf tariefgroepen: "hoog", "laag", "nul", "privé" en
# "anders". De tariefgroep bepaalt het rekeningnummer waarop de
# betreffende boeking plaatsvindt.
# Binnen elke tariefgroep zijn meerdere tarieven mogelijk, hoewel dit
# in de praktijk niet snel zal voorkomen.
# In de eerste kolom wordt de (numerieke) code voor dit tarief
# opgegeven. Deze kan o.m. worden gebruikt om expliciet een BTW tarief
# op te geven bij het boeken. Voor elk gebruikt tarief (behalve die
# van groep "nul") moet het percentage worden opgegeven. Met de
# aanduiding :exclusief kan worden opgegeven dat boekingen op
# rekeningen met deze tariefgroep standaard het bedrag exclusief BTW
# aangeven.
#
# BELANGRIJK: Mutaties die middels de command line shell of de API
# worden uitgevoerd maken gebruik van het geassocieerde BTW tarief van
# de grootboekrekeningen. Wijzigingen hierin kunnen dus consequenties
# hebben voor de reeds in scripts vastgelegde boekingen.

BTW Tarieven

   0  BTW 0%                 :tariefgroep=nul
   1  BTW 19% incl.          :tariefgroep=hoog :perc=19,00
   2  BTW 19% excl.          :tariefgroep=hoog :perc=19,00 :exclusief
   3  BTW 6,0% incl.         :tariefgroep=laag :perc=6,00
   4  BTW 6,0% excl.         :tariefgroep=laag :perc=6,00 :exclusief
   5  BTW Privé 12% incl.    :tariefgroep=privé :perc=12,00
   6  BTW Privé 12% ex.	     :tariefgroep=privé :perc=12,00 :exclusief
EOD
	    }
	    print { $fd } ( <<"EOD" );

# Einde EekBoek schema
EOD
	} );
}

sub generate_relaties {
    my ( $self, $opts ) = @_;

    return if exists $opts->{create_relaties} && !$opts->{create_relaties};

    $self->generate_file( "relaties.eb", _T("Relaties"), $opts );
}

sub generate_opening {
    my ( $self, $opts ) = @_; 

    return if exists $opts->{create_opening} && !$opts->{create_opening};

    $self->generate_file
      ( "opening.eb", _T("Opening"), $opts,
	sub {
	    my ( $self, $fd ) = @_;
	    print { $fd }
	      ( "adm_naam \"", $opts->{adm_naam}, "\"\n" );
	    print { $fd }
	      ( "adm_btwperiode ", $opts->{adm_btwperiode}, "\n" )
		if $opts->{has_btw};
	    print { $fd }
	      ( "adm_begindatum \"", $opts->{adm_begindatum}, "\"\n" );
	    print { $fd }
	      ( "adm_boekjaarcode \"", $opts->{adm_boekjaarcode}, "\"\n" );
	    print { $fd }
	      ( "adm_open\n");
	  }
      );
}

sub generate_mutaties {
    my ( $self, $opts ) = @_;

    return if exists $opts->{create_mutaties} && !$opts->{create_mutaties};

    $self->generate_file( "mutaties.eb", _T("Mutaties"), $opts );
}

1;
