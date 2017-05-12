package Lingua::IT::Conjugate;

# use strict;
# use warnings;

@ISA = qw( Exporter );

@EXPORT_OK = qw(
	coniuga
	coniugazione
	declina
);

use FindBin;
#use Tie::RegexpHash;

use vars qw(
	$VERSION
	%Desinenza
	%Regolarizza
	%Irregolarita
	%Prefissi
	%Simile
	@Ausiliari_essere
	@Pronome
	@Pronome_riflessivo
	@Tempi
	$Errore
	%Opzioni
);

$VERSION = "0.50";

@Pronome = ( 
	'nessuno', 
	'io  ', 
	'tu  ', 
	'lui ', 
	'noi ', 
	'voi ', 
	'essi',
);
@Pronome_riflessivo = ( 
	'nessuno', 
	'mi', 
	'ti', 
	'si', 
	'ci', 
	'vi', 
	'si',
);

@Tempi = qw(
	presente				imperfetto
	passato_prossimo		trapassato_prossimo
	passato_remoto			trapassato_remoto
	futuro_semplice			futuro_anteriore
	congiuntivo_presente	congiuntivo_imperfetto
	congiuntivo_passato		congiuntivo_trapassato
	condizionale_presente	condizionale_passato
);

#tie %Opzioni, 'Tie::RegexpHash';
%Opzioni = (
#	qr/^(pronomi|pronouns)$/ => 1,
#	qr/^(coniuga_sconosciuti|conjugate_unknown)$/ => 1,
#	prefer_csv => 0,
#	qr/^(gender|sesso)$/ => 'M'
	pronomi => 1,
	coniuga_sconosciuti => 1,
	prefer_csv => 0,
	sesso => 'M',
);

inizializza();

sub inizializza {
	my($in_pod, $sezione, $verbo, $declinazione, $tempo, $tempo_ausiliare, $desinenze);
	my($forma_regolare, $tempi, $prefissi, $persona, $forma, $prefisso);
	$in_pod = 1;	
	$sezione = "";
	while(<DATA>) {
		if($in_pod) {
			$in_pod = 0 if /^=cut/;
			next if $in_pod;
		}
		next if /^\s*#/ or /^\s*$/;
		chomp;
		s/^\s+|\s+$//;
		if(/^\[(.*)\]/) {
			$sezione = ucfirst(lc($1));
		} else {
			if($sezione eq "Desinenze") {
				($declinazione, $tempo, $desinenze) = split(/\s+/, $_, 3);
				$Desinenza{$declinazione} = {} unless exists $Desinenza{$declinazione};
				$Desinenza{$declinazione}{$tempo} = [] unless exists $Desinenza{$declinazione}{$tempo};
				$Desinenza{$declinazione}{$tempo} = [ split(/\s*,\s*/, $desinenze) ];

			} elsif($sezione eq "Composti") {
				($tempo, $tempo_ausiliare) = split(/\s+/, $_, 2);		
				foreach $declinazione ( qw( are ere ire ) ) {
					$Desinenza{$declinazione} = {} unless exists $Desinenza{$declinazione};
					$Desinenza{$declinazione}{$tempo} = "ausiliare($tempo_ausiliare)+participio";
				}

			} elsif($sezione eq "Regolarizza") {
				($verbo, $forma_regolare, $tempi) = split(/\s+/, $_, 3);
				$Regolarizza{$verbo} = "$forma_regolare;$tempi";

			} elsif($sezione eq "Ausiliari_essere") {			
				push(@Ausiliari_essere, $_);

			} elsif($sezione eq "Prefissi") {
				($verbo, $prefissi) = split(/\s+/, $_, 2);
				$Prefissi{$verbo} = [] unless exists $Prefissi{$verbo};
				$Prefissi{$verbo} = [ split(/\s+/, $prefissi) ];

			} elsif($sezione eq "Irregolarita") {
				($verbo, $tempo, $persona, $forma) = split(/\s+/, $_, 4);
				$Irregolarita{$verbo} = {} unless exists $Irregolarita{$verbo};
				$Irregolarita{$verbo}{$tempo} = {} unless exists $Irregolarita{$verbo}{$tempo};
				$Irregolarita{$verbo}{$tempo}{$persona} = $forma;
			}
		}						
	}
	foreach $verbo (keys %Prefissi) {
		foreach $prefisso (@{$Prefissi{$verbo}}) {
			$Simile{ $prefisso.$verbo } = $verbo;
		}
	}
}

sub opzioni_default {
	no warnings;
	my($opzioni) = @_;
	my %default;
	# tie %default, 'Tie::RegexpHash';
	foreach my $opzione (keys %Opzioni) {
		$default{$opzione} = $Opzioni{$opzione};
	}
	
	my $chiamante = (caller(1))[3];
	$chiamante =~ s/Lingua::IT::Conjugate:://;

	if($chiamante eq 'coniuga') {
		$default{ pronomi } = 0;
	} elsif($chiamante eq 'coniugazione') {
		$default{ pronomi } = 0;
	}
	if(defined $opzioni and ref($opzioni) eq "HASH") {
		foreach (keys %$opzioni) {
			$default{$_} = $opzioni->{$_};
		}
	}
	return \%default;
}

sub coniuga {
	my($verbo, $tempo, $persona, $opzioni) = @_;
	my @risultato;
	my %risultato;

	$opzioni = opzioni_default( $opzioni );

	if( $opzioni->{coniuga_sconosciuti} == 0) {
		if(not verbo_esistente( $verbo )) {
			$Errore = "unknown verb ('$verbo')";
			return "[unknown verb ('$verbo')]";
		}
	}

	if(defined $tempo and defined $persona) {
		return coniuga_forma($verbo, $tempo, $persona);
	} elsif(not defined $tempo and defined $persona) {
		foreach $tempo (@Tempi) {
			$risultato{$tempo} = coniuga_forma($verbo, $tempo, $persona);
		}
		return wantarray ? %risultato : \%risultato;
	} elsif(defined $tempo and not defined $persona) {
		foreach $persona (1..6) {
			push(@risultato, coniuga_forma($verbo, $tempo, $persona));
		}
		return wantarray ? @risultato : join(", ", @risultato);
	} else {
		foreach $tempo (@Tempi) {
			foreach $persona (1..6) {
				push(@risultato, coniuga_forma($verbo, $tempo, $persona));
			}
			$risultato{$tempo} = [ @risultato ];
		}
		return wantarray ? %risultato : \%risultato;
	}
}

sub applica_irregolarita {
	my($risultato, $verbo, $tempo) = @_;
	if(exists $Irregolarita{$verbo}{$tempo}{'*'}) {
		if($Irregolarita{$verbo}{$tempo}{'*'} =~ /^~/) {
			eval "\$risultato =".$Irregolarita{$verbo}{$tempo}{'*'}.";"
		} else {
			$risultato = $Irregolarita{$verbo}{$tempo}{'*'};
		}
	}
	return $risultato;
}

sub coniuga_forma {
    my($verbo, $tempo, $persona, $opzioni) = @_;

	my($tema, $coniugazione, $base, $prefisso, $prefisso_tema, $desinenza, $risultato);
	my($ausiliare, $verbo_ausiliare, $tempo_ausiliare, $riflessivo);
	my @aggiustamenti;
	my %opzioni;

	$opzioni = opzioni_default( $opzioni );

	if($verbo =~ s/si$/e/) { $riflessivo = 1; }
	if($verbo =~ /[ou]re$/) {
		my $prova;
		($prova = $verbo) =~ s/re$/rre/;
		$prova =~ s/urre$/ucere/i;
		$prova =~ s/orre$/onere/i;
		if(exists $Simile{$prova} 
		or exists $Regolarizza{$prova}
		or exists $Prefissi{$prova}) {
			$verbo = $prova;
		}
	}

	$verbo =~ s/urre$/ucere/i;
	$verbo =~ s/orre$/onere/i;

	if(exists $Simile{$verbo}) {
		($prefisso_tema = $verbo) =~ s/$Simile{$verbo}$//;
		$verbo = $Simile{$verbo};
	}

	if(exists $Regolarizza{$verbo}) {
		my($forma_regolare, $tempi) = split(/;/, $Regolarizza{$verbo});
		if($tempi eq "*" or $tempi =~ /$tempo/) {
    		$verbo = $forma_regolare;
    	}
    }

	if(exists $Irregolarita{$verbo}{$tempo}{$persona}) {
		$risultato = $Irregolarita{$verbo}{$tempo}{$persona};
		$risultato = $prefisso_tema . $risultato if defined $prefisso_tema;            
		if($riflessivo) {
			$risultato = $Pronome_riflessivo[$persona]." ".$risultato;
		}
		return $risultato;
	}

	foreach (keys %Desinenza) {
        if($verbo =~ /^(.*)$_$/i) {
            $tema = $1;
            $coniugazione = $_;
            last;
        }
    }
    if(defined $coniugazione) {
		if(ref( $Desinenza{$coniugazione}{$tempo} )) {     

			$desinenza = $Desinenza{$coniugazione}{$tempo}[$persona-1];
			($tema, $desinenza) = aggiusta(
				$coniugazione, 
				$tempo,
				$persona,
				$tema, 
				$desinenza,
			);		

			$risultato = $tema . $desinenza;
			$risultato = applica_irregolarita( $risultato, $verbo, $tempo );
			$risultato = $prefisso_tema . $risultato if defined $prefisso_tema;				
			if($riflessivo) {
				$risultato = $Pronome_riflessivo[$persona]." ".$risultato;
			}
		} else {
			($prefisso, $base) = split(/\+/, $Desinenza{$coniugazione}{$tempo});

			if($prefisso =~ /^ausiliare/) {
				($tempo_ausiliare = $prefisso) =~ s/^.*\((.*)\)$/$1/;
				if(grep( /^$verbo$/, @Ausiliari_essere)
				or $riflessivo) {
					$verbo_ausiliare = "essere";
				} else {
					$verbo_ausiliare = "avere";
				}
				$ausiliare = coniuga_forma($verbo_ausiliare, $tempo_ausiliare, $persona);
				$desinenza = $Desinenza{$coniugazione}{$base}[$persona-1];
				($tema, $desinenza) = aggiusta(
					$coniugazione, 
					$base,
					$persona,
					$tema, 
					$desinenza,
				);		
				
				$risultato = $tema . $desinenza;
				$risultato = applica_irregolarita( $risultato, $verbo, $base );
				if($verbo_ausiliare eq "essere" and $persona > 3) {
					$risultato =~ s/o$/i/;
				}                	
				$risultato = $prefisso_tema . $risultato if defined $prefisso_tema;
				$risultato = $ausiliare . " " . $risultato;
				if($riflessivo) {
					$risultato = $Pronome_riflessivo[$persona]." ".$risultato;
				}
			} else {

				($base, @aggiustamenti) = split(/;/, $base);

				my %aggiustamenti;
				map { /(\w+)=(\w+)/; $aggiustamenti{$1} = $2; } @aggiustamenti;

				$desinenza = $Desinenza{$coniugazione}{$base}[$persona-1];

				if( exists $aggiustamenti{$persona} ) {
					$desinenza = $aggiustamenti{$persona};
				}

				($tema, $desinenza) = aggiusta(
					$coniugazione, 
					$tempo,
					$persona,
					$tema, 
					$prefisso . $desinenza,
				);		

				$risultato = $tema . $desinenza;
				$risultato = applica_irregolarita( $risultato, $verbo, $tempo );
				$risultato = $prefisso_tema . $risultato if defined $prefisso_tema;
				if($riflessivo) {
					$risultato = $Pronome_riflessivo[$persona]." ".$risultato;
				}
			}
		}
    	return $risultato;
	} else {
		return "NON LO ".uc(coniuga_forma("sapere", "presente", $persona))." FARE!";
	}
}

sub aggiusta {
	my($coniugazione, $tempo, $persona, $tema, $desinenza) = @_;
	my($prima, $seconda);
	
	if( $coniugazione eq "are" ) {
		if( $tema =~ /[gc]$/ and $desinenza =~ /^[ie]/ ) {
			$tema .= "h";
		} elsif( $tema =~ /[gc]i$/ and $desinenza =~ /^[ie]/ ) {
			chop $tema;
		} elsif( $tema =~ /i$/ and $desinenza =~ /^i/ ) {
			chop $tema;
		}
	} elsif( $coniugazione eq "ere" ) {

		if($tema =~ /g(n|li)$/) {
			if($tempo eq "participio") {
				$tema =~ s/g(l|n)i?$/($1 eq "n") ? "n" : "l"/e;
				$desinenza = "to";
			} elsif($tempo eq "passato_remoto"
			and ($persona == 1 or $persona == 3 or $persona == 6) ) {
				$tema =~ s/g(l|n)i?$/$1s/;	
				$desinenza =~ s/ei/i/;
				$desinenza =~ s/ä/e/;
				$desinenza =~ s/erono/ero/;
			} elsif($tempo eq "presente") {
				if($persona == 1 or $persona == 6) {
					$tema =~ s/g(n|l)i?$/$1g/;
				} else {
					$desinenza =~ s/^i// if $tema =~ /i$/;
				}
			} elsif($tempo eq "congiuntivo_presente") {
				if($desinenza =~ /^a/) {
					$tema =~ s/g(n|l)i?$/$1g/;
				} else {
					$desinenza =~ s/^i// if $tema =~ /i$/;
				}
			}

		} elsif( $tema =~ /n$/ and $desinenza =~ /^[oa]/ ) {
			$tema .= "g";

		} elsif( $tema =~ /[gnr]g$/ and $tempo eq "passato_remoto"
		and ($persona == 1 or $persona == 3 or $persona == 6) ) {
			$tema =~ s/(.)g$/( ($1 eq "g") ? "s" : $1 ) . "s"/e;	
			$desinenza =~ s/ei/i/;
			$desinenza =~ s/ä/e/;
			$desinenza =~ s/erono/ero/;

		} elsif( $tema =~ /[nr]d$/ and $tempo eq "passato_remoto"
		and ($persona == 1 or $persona == 3 or $persona == 6) ) {
			$tema =~ s/(.)d$/( ($1 eq "n") ? "" : $1 ) . "s"/e;	
			$desinenza =~ s/ei/i/;
			$desinenza =~ s/ä/e/;
			$desinenza =~ s/erono/ero/;
		
		} elsif( $tema =~ /isc$/ 
		and ($tempo eq "presente" or $tempo eq "congiuntivo_presente")
		and ($persona == 4 or $persona == 5) ) {
			$tema =~ s/isc$//;
			$desinenza =~ s/^./i/;
			
		} elsif( $tema =~ /[aeious][cg]$/ and $tempo eq "participio") {
			$tema .= "i";

		} elsif( $tema =~ /([^aeiou])([^aeiou])$/ and $tempo eq "participio") {
			($prima, $seconda) = ($1, $2);
			if($seconda eq "g") {
				$prima = "t" if $prima eq $seconda;
				$seconda = "t";
				$desinenza = "o";
			} elsif($prima eq "m" and $seconda eq "p") {
				$prima = "t";
				$seconda = "t";
				$desinenza = "o";
			} elsif($prima eq "r" and $seconda eq "d") {
				$seconda = "s";
				$desinenza = "o";
	
			} elsif($prima eq "n" and $seconda eq "d") {
				if($tema =~ /o..$/) {
					$prima = "s";
					$seconda = "t";
					$desinenza = "o";
				} elsif($tema =~ /[ue]..$/) {
					$prima = "";
					$seconda="s";
					$desinenza = "o";
				}
			}
			$tema =~ s/..$/$prima$seconda/;			
		}
	} 
	return ($tema, $desinenza);
}

sub declina {
    my($verbo, $tempo, $opzioni) = @_;
    $opzioni = opzioni_default( $opzioni );
    my @result;
    for my $persona (1..6) {
    	if($opzioni{pronomi}) {
    		push(@result, $Pronome[$persona] . " " . coniuga_forma($verbo, $tempo, $persona, $opzioni));
    	} else {
    		push(@result, coniuga_forma($verbo, $tempo, $persona, $opzioni));
    	}
    }
    return @result;
}

sub verbo {
    my($forma) = @_;
}

sub verbo_esistente {
	my($verbo) = @_;
	$verbo =~ s/si$/e/;
	if($verbo =~ /[ou]re$/) {
		my $prova;
		($prova = $verbo) =~ s/re$/rre/;
		$prova =~ s/urre$/ucere/i;
		$prova =~ s/orre$/onere/i;
		if(exists $Simile{$prova} 
		or exists $Regolarizza{$prova}
		or exists $Prefissi{$prova}) {
			$verbo = $prova;
		}
	}
	if(open(VERBI, "$FindBin::RealBin/verbi") ) {
		my $conosciuto = 0;
		while(<VERBI>) {
			chomp;
			$_ eq $verbo and $conosciuto = 1, last;
		}
		return $conosciuto;
	} else {
		return 1;
	}
}

sub coniugazione {
	my($verbo, $opzioni) = @_;
	my($tempo, $persona, $risultato);
	
	$opzioni = opzioni_default( $opzioni );

	if( $opzioni->{coniuga_sconosciuti} == 0) {
		if(not verbo_esistente( $verbo )) {
			$Errore = "unknown verb ('$verbo')";
			return "[unknown verb ('$verbo')]";
		}
	}

	$risultato = "";
	foreach ($tempo = 0; $tempo <= $#Tempi; $tempo += 2) {
		$risultato .= centered(uc($Tempi[$tempo]), 35, "-");
		$risultato .= " ";
		$risultato .= centered(uc($Tempi[$tempo+1]), 35, "-");
		$risultato .= "\n";
		for $persona (1..6) {
			$risultato .= sprintf "%-35s %-35s\n", 
				( ($opzioni->{pronomi} == 1) ? $Pronome[$persona]." " : "" ).coniuga_forma($verbo, $Tempi[$tempo], $persona),
				( ($opzioni->{pronomi} == 1) ? $Pronome[$persona]." " : "" ).coniuga_forma($verbo, $Tempi[$tempo+1], $persona);
		}
	}
	return $risultato;
	
	sub centered {
		my($string, $len, $fill) = @_;
		$fill = " " unless defined $fill;
		my $result = $fill x (($len-length($string))/2-1);
		$result .= " ";
		$result .= $string;
		$result .= " ";
		$result .= $fill x ($len-length($result));
		return $result;
	}
}

### TEST_START
if(defined $ARGV[0]) {
	if(not defined $ARGV[1] or $ARGV[1] eq "*") {
		print coniugazione( $ARGV[0] , { pronomi => 1 }), "\n";
	} else {
		print join("\n", declina($ARGV[0], $ARGV[1])), "\n";
	}
}
### TEST_END

1;

__DATA__

=head1 NAME

Lingua::IT::Conjugate - Conjugation of Italian verbs

=head1 SYNOPSIS

    use Lingua::IT::Conjugate qw( coniuga coniugazione );
  
	@amare = coniuga( 'amare', 'presente' );
	print join( "\n", @amare );

    $io_amo = coniuga( 'amare', 'presente', 1 );
	
	print coniugazione( 'amare' );

=head1 DESCRIPTION

This module conjugates italian verbs.

Blah blah blah.

=head2 EXPORT

None by default. You can export the following functions and variables:

    coniuga
	coniugazione
	@Tempi
	@Pronomi


=head1 HISTORY

=over 4

=item 0.50

Original version; created by h2xs 1.20 with options

    -A -C -X -n Lingua::IT::Conjugate -v 0.50

=back


=head1 AUTHOR

Aldo Calpini, dada@perl.it

=head1 SEE ALSO

perl(1).

=cut

[Desinenze]
#declinazione	#tempo					#desinenze
are				presente				o, i, a, iamo, ate, ano
are				imperfetto				avo, avi, ava, avamo, avate, avano
are				futuro_semplice			erï, erai, erÖ, eremo, erete, eranno
are				passato_remoto			ai, asti, ï, ammo, aste, arono
are				congiuntivo_presente	i, i, i, iamo, iate, ino
are				congiuntivo_imperfetto	assi, assi, asse, assimo, aste, assero
are				condizionale_presente	erei, eresti, erebbe, eremmo, ereste, erebbero
are				participio				ato, ato, ato, ato, ato, ato

ere				presente				o, i, e, iamo, ete, ono
ere				imperfetto				evo, evi, eva, evamo, evate, evano
ere				futuro_semplice			erï, erai, erÖ, eremo, erete, eranno
ere				passato_remoto			ei, esti, ä, emmo, este, erono
ere				congiuntivo_presente	a, a, a, iamo, iate, ano
ere				congiuntivo_imperfetto	essi, essi, esse, essimo, este, essero
ere				condizionale_presente	erei, eresti, erebbe, eremmo, ereste, erebbero
ere				participio				uto, uto, uto, uto, uto, uto

ire				presente				o, i, e, iamo, ite, ono
ire				imperfetto				ivo, ivi, iva, ivamo, ivate, ivano
ire				futuro_semplice			irï, irai, irÖ, iremo, irete, iranno
ire				passato_remoto			ii, isti, ç, immo, iste, irono
ire				congiuntivo_presente	a, a, a, iamo, iate, ano
ire				congiuntivo_imperfetto	issi, issi, isse, issimo, iste, issero
ire				condizionale_presente	irei, iresti, irebbe, iremmo, ireste, irebbero
ire				participio				ito, ito, ito, ito, ito, ito

[Composti]
#tempo					#tempo_ausiliare(+participio)
passato_prossimo		presente
futuro_anteriore		futuro_semplice
trapassato_prossimo		imperfetto
trapassato_remoto		passato_remoto
congiuntivo_passato		congiuntivo_presente
congiuntivo_trapassato	congiuntivo_imperfetto
condizionale_passato	condizionale_presente

[Regolarizza]
#verbo			#forma_regolare		#tempi
ardire			ardiscere			presente,congiuntivo_presente
bere    		bevere				*
capire			capiscere			presente,congiuntivo_presente
cepire			cepiscere			presente,congiuntivo_presente
dire    		dicere				*
fare    		facere				*
finire			finiscere			presente,congiuntivo_presente
subire			subiscere			presente,congiuntivo_presente
ordire			ordiscere			presente,congiuntivo_presente
trarre			traere				*

[Prefissi]
#verbo			#prefissi
cepire			con ec per re
cidere			coin de in re uc 
cludere			ac con es in oc pre
conoscere		mis ri
correre			ac con de in ri rin s tras
dire			bene contrad in male pre ri
ducere			ad con de ri tra
fare			dis con putre ri
finire			de ri s
fondere			con dif ef in pro ri
manere			im per ri 
nascere			ri
piacere			com dis s
ponere			ap com contrap de dis frap op ri 
rompere			cor e inter
scindere		pre re
trarre			as at con de dis es pro ri re sot
venire			con contrav di per pre rin sov 
tenere			con de ot ri sos trat 
vertire			av contro di in per sov 
volgere			coin ri stra

[Ausiliari_essere]
andare 
crescere 
diventare 
divenire
entrare
essere
morire 
nascere 
piacere
rimanere
stare 
uscire
venire
vivere 

[Irregolarita]
#verbo		#tempo					#persona	#forma
andare		presente				1			vado
andare		presente				2			vai
andare		presente				3			va
andare		presente				6			vanno
andare		futuro_semplice			*			~ s/ander/andr/
andare		condizionale_presente	*			~ s/ander/andr/

avere		tipo					ere_comune	ebb
avere		presente				1			ho
avere		presente				2			hai
avere		presente				3			ha
avere		presente				4			abbiamo
avere		presente				6			hanno
avere		futuro_semplice			*			~ s/aver/avr/
avere		passato_remoto			1			ebbi
avere		passato_remoto			3			ebbe
avere		passato_remoto			6			ebbero
avere		congiuntivo_presente	*			~ s/av(i?)/'abb'.($1 or 'i')/e
avere		condizionale_presente	*			~ s/aver/avr/

avere		tipo					ere_comune	bevv
bevere		passato_remoto			1			bevvi
bevere		passato_remoto			3			bevve
bevere		passato_remoto			6			bevvero
bevere		futuro_semplice			*			~ s/bever/berr/
bevere		condizionale_presente	*			~ s/bever/berr/

cidere		passato_remoto			1			cisi
cidere		passato_remoto			3			cise
cidere		passato_remoto			6			cisero
cidere		participio				*			ciso

cludere		passato_remoto			1			clusi
cludere		passato_remoto			3			cluse
cludere		passato_remoto			6			clusero
cludere		participio				*			cluso

conoscere	passato_remoto			1			conobbi
conoscere	passato_remoto			3			conobbe
conoscere	passato_remoto			6			conobbero

correre		participio				*			corso

dare		presente				2			dai
dare		presente				3			dÖ
dare		presente				6			danno
dare		passato_remoto			1			diedi(detti)
dare		passato_remoto			2			desti
dare		passato_remoto			3			diede(dette)
dare		passato_remoto			4			demmo
dare		passato_remoto			5			deste
dare		passato_remoto			6			diedero(dettero)
dare		futuro_semplice			*			~ s/der/dar/
dare		congiuntivo_presente	1			dia
dare		congiuntivo_presente	2			dia
dare		congiuntivo_presente	3			dia
dare		congiuntivo_presente	6			diano

dicere		presente				5			dite
dicere		passato_remoto			1			dissi
dicere		passato_remoto			3			disse
dicere		passato_remoto			6			dissero
dicere		futuro_semplice			*			~ s/dicer/dir/
dicere		participio				*			detto

dirigere	passato_remoto			1			diressi
dirigere	passato_remoto			3			diresse
dirigere	passato_remoto			6			diressero
dirigere	participio				*			diretto

dovere		presente				1			devo
dovere		presente				2			devi
dovere		presente				3			deve
dovere		presente				4			dobbiamo
dovere		presente				6			devono
dovere		passato_remoto			1			dovei(dovetti)
dovere		passato_remoto			3			dovä(dovette)
dovere		passato_remoto			6			doverono(dovettero)
dovere		futuro_semplice			*			~ s/dover/dovr/
dovere		congiuntivo_presente	1			debba
dovere		congiuntivo_presente	2			debba
dovere		congiuntivo_presente	3			debba
dovere		congiuntivo_presente	4			dobbiamo
dovere		congiuntivo_presente	5			dobbiate
dovere		congiuntivo_presente	6			debbano
dovere		condizionale_presente	*			~ s/dover/dovr/

ducere		passato_remoto			1			dussi
ducere		passato_remoto			3			dusse
ducere		passato_remoto			6			dussero
ducere		futuro_semplice			*			~ s/ducer/durr/
ducere		condizionale_presente	*			~ s/ducer/durr/
ducere		participio				*			dotto

essere		presente				1			sono
essere		presente				2			sei
essere		presente				3			ä
essere		presente				4			siamo
essere		presente				5			siete
essere		presente				6			sono
essere		imperfetto				4			eravamo
essere		imperfetto				5			eravate
essere		imperfetto				*			~ s/essev/er/
essere		futuro_semplice			*			~ s/esser/sar/
essere		passato_remoto			1			fui
essere		passato_remoto			2			fosti
essere		passato_remoto			3			fu
essere		passato_remoto			4			fummo
essere		passato_remoto			5			foste
essere		passato_remoto			6			furono
essere		congiuntivo_presente	1			sia
essere		congiuntivo_presente	2			sia
essere		congiuntivo_presente	3			sia
essere		congiuntivo_presente	4			siamo
essere		congiuntivo_presente	5			siate
essere		congiuntivo_presente	6			siano
essere		congiuntivo_imperfetto	*			~ s/esses/fos/
essere		condizionale_presente	*			~ s/esser/sar/
essere		participio				*			stato

facere		presente				1			faccio
facere		presente				2			fai
facere		presente				3			fa
facere		presente				4			facciamo
facere		presente				5			fate
facere		presente				6			fanno
facere		passato_remoto			1			feci
facere		passato_remoto			3			fece
facere		passato_remoto			6			fecero

fondere		passato_remoto			1			fusi
fondere		passato_remoto			3			fuse
fondere		passato_remoto			6			fusero
fondere		participio				*			fuso

manere		passato_remoto			1			masi
manere		passato_remoto			3			mase
manere		passato_remoto			6			masero
manere		futuro_semplice			*			~ s/maner/marr/
manere		congiuntivo_presente	1			manga
manere		congiuntivo_presente	2			manga
manere		congiuntivo_presente	3			manga
manere		congiuntivo_presente	6			maniamo
manere		condizionale_presente	*			~ s/maner/marr/
manere		participio				*			masto

morire		presente				1			muoio
morire		presente				2			muori
morire		presente				3			muore
morire		presente				5			morite
morire		presente				6			muoiono
morire		congiuntivo_presente	1			muoia
morire		congiuntivo_presente	2			muoia
morire		congiuntivo_presente	3			muoia
morire		congiuntivo_presente	6			muoiano
morire		participio				*			morto

nascere		passato_remoto			1			nacqui
nascere		passato_remoto			3			nacque
nascere		passato_remoto			6			nacquero
nascere		participio				*			nato

perdere		passato_remoto			1			persi
perdere		passato_remoto			3			perse
perdere		passato_remoto			6			persero
perdere		participio				*			perso(perduto)

piacere		presente				1			piaccio
piacere		presente				4			piacciamo
piacere		presente				6			piacciono
piacere		passato_remoto			1			piacqui
piacere		passato_remoto			3			piacque
piacere		passato_remoto			6			piacquero
piacere		congiuntivo_presente	*			~ s/piac(i?)/'piacc'.($1 or 'i')/e

ponere		passato_remoto			1			posi
ponere		passato_remoto			3			pose
ponere		passato_remoto			6			posero
ponere		futuro_semplice			*			~ s/poner/porr/
ponere		condizionale_presente	*			~ s/poner/porr/
ponere		participio				*			posto

potere		presente				1			posso
potere		presente				2			puoi
potere		presente				3			puï
potere		presente				4			possiamo
potere		presente				6			possono
potere		futuro_semplice			*			~ s/poter/potr/
potere		congiuntivo_presente	*			~ s/pot/poss/
potere		condizionale_presente	*			~ s/poter/potr/

ridere		passato_remoto			1			risi
ridere		passato_remoto			3			rise
ridere		passato_remoto			6			risero
ridere		participio				*			riso

rompere		passato_remoto			1			ruppi
rompere		passato_remoto			3			ruppe
rompere		passato_remoto			6			ruppero

sapere		presente				1			so
sapere		presente				2			sai
sapere		presente				3			sa
sapere		presente				4			sappiamo
sapere		presente				6			sanno
sapere		passato_remoto			1			seppi
sapere		passato_remoto			3			seppe
sapere		passato_remoto			6			seppero
sapere		futuro_semplice			*			~ s/saper/sapr/
sapere		congiuntivo_presente	*			~ s/sap(i?)/'sapp'.($1 or 'i')/e
sapere		condizionale_presente	*			~ s/saper/sapr/

scindere	passato_remoto			1			scissi
scindere	passato_remoto			3			scisse
scindere	passato_remoto			6			scissero
scindere	participio				*			scisso

stare		presente				2			stai
stare		presente				6			stanno
stare		futuro_semplice			*			~ s/ster/star/
stare		passato_remoto			1			stetti
stare		passato_remoto			2			stesti
stare		passato_remoto			3			stette
stare		condizionale_presente	*			~ s/ster/star/
stare		congiuntivo_presente	1			stia
stare		congiuntivo_presente	2			stia
stare		congiuntivo_presente	3			stia
stare		congiuntivo_presente	6			stiano
stare		congiuntivo_imperfetto	*			~ s/stas/stes/

traere		presente				1			traggo
traere		presente				6			traggono
traere		futuro_semplice			*			~ s/traer/trarr/
traere		passato_remoto			1			trassi
traere		passato_remoto			3			trasse
traere		passato_remoto			6			trassero
traere		participio				*			tratto

uscire		presente				1			esco
uscire		presente				2			esci
uscire		presente				3			esce
uscire		presente				5			uscite
uscire		presente				6			escono
uscire		congiuntivo_presente	1			esca
uscire		congiuntivo_presente	2			esca
uscire		congiuntivo_presente	3			esca
uscire		congiuntivo_presente	6			escano

venire		presente				1			vengo
venire		presente				2			vieni
venire		presente				3			viene
venire		presente				5			venite
venire		presente				6			vengono
venire		futuro_semplice			*			~ s/venir/verr/

vivere		passato_remoto			1			vissi
vivere		passato_remoto			3			visse
vivere		passato_remoto			6			vissero
vivere		futuro_semplice			*			~ s/viver/vivr/
vivere    	participio				*			~ s/viv/viss/

volere		presente				1			voglio
volere		presente				2			vuoi
volere		presente				3			vuole
volere		presente				4			vogliamo
volere		presente				6			vogliono
volere		passato_remoto			1			volli
volere		passato_remoto			3			volle
volere		passato_remoto			6			vollero

volere		futuro_semplice			*			~ s/voler/vorr/
volere		congiuntivo_presente	*			~ s/vol(i?)/'vogl'.($1 or 'i')/e
volere		condizionale_presente	*			~ s/voler/vorr/

volgere		passato_remoto			1			volsi
volgere		passato_remoto			3			volse
volgere		passato_remoto			6			volsero
volgere		participio				*			volto
