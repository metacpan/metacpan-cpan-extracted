#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Fri Jun 17 21:31:52 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jun 14 21:56:24 2010
# Update Count    : 102
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

# Package or program libraries, if appropriate.
# $LIBDIR = $ENV{'LIBDIR'} || '/usr/local/lib/sample';
# use lib qw($LIBDIR);
# require 'common.pl';

# Package name.
my $my_package = 'EekBoek';
# Program name and version.
my ($my_name, $my_version) = qw(exirel 1.12);

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $all = 0;		# all
my $verbose = 0;		# verbose processing
my $ac5 = 0;			# DaviDOS compatibility

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use Text::CSV_XS;
use EB::Config qw(EekBoek);
use EB::Globals;

unless ( @ARGV ) {
    foreach ( "DEBITR.CSV", "CREDIT.CSV" ) {
	if ( -s $_ ) {
	    push(@ARGV, $_);
	}
	elsif ( -s lc($_) ) {
	    push(@ARGV, lc($_));
	}
    }
}

# Load field names from __DATA__.

my @debfieldnames;
my @crdfieldnames;
my $fieldnames = \@debfieldnames;
while ( <DATA> ) {
    next if /^#/;
    $fieldnames = \@crdfieldnames, next unless /\S/;
    my @a = split(/\t/);
    push(@$fieldnames, $a[1]);
}

# Load maps, if provided.
my $crdmap = -s "crdmap.pl" ? require "crdmap.pl" : {};
my $debmap = -s "debmap.pl" ? require "debmap.pl" : {} ;

# Find out which codes are actually used.
my %used;
my $csv = new Text::CSV_XS ({binary => 1});
my $db;
if ( open($db, "fmuta6.csv") || open($db, "FMUTA6.CSV") ) {
    my $mut;
    while ( <$db> ) {
	s/0""/0,""/g;
	$csv->parse($_);
	my @a = $csv->fields();
	$used{uc($a[9]||$a[10])}++;
    }
    close($db);
}

$csv = new Text::CSV_XS ({binary => 1});
while ( <> ) {
    s/0""/0,""/g;
    unless ( $csv->parse($_) ) {
	warn("Geen geldige invoer op regel $., file $ARGV\n");
	next;
    }

    my %a;
    my @a = $csv->fields();
    if ( @a == @debfieldnames ) {	# debiteur
	@a{@debfieldnames} = @a;
	$a{debzk} ||= $a{debnr} if $ac5;
	if ( $a{debzk} ) {
	    next unless $all || $used{$a{debzk}};
	}
	elsif ( $debmap->{$a{naam}} ) {
	    $a{debzk} = $debmap->{$a{naam}};
	    next unless $all || $used{$a{debzk}};
	}
	else {
	    warn("Geen relatiecode voor debiteur $a{naam} -- overgeslagen\n");
	    next;
	}
	$a{debzk} = "R_".$a{debzk} if $a{debzk} =~ /^\d+$/;
	print("relatie ",
	      ($a{btw_nummer} ne "" && $a{btw_nummer} eq "0") ? "--btw=extra " : "",
	      '"', $a{debzk}, '"', " ",
	      '"', $a{naam}, '"', " ",
	      "8000C",
	      "\n");
	next;
    }
    if ( @a == @crdfieldnames ) {	# crediteur
	@a{@crdfieldnames} = @a;
	$a{crdzk} ||= $a{crdnr} if $ac5;
	if ( $a{crdzk} ) {
	    next unless $all || $used{$a{crdzk}};
	}
	elsif ( $crdmap->{$a{naam}} ) {
	    $a{crdzk} = $crdmap->{$a{naam}};
	    next unless $all || $used{$a{crdzk}};
	}
	else {
	    warn("Geen relatiecode voor crediteur $a{naam} -- overgeslagen\n");
	    next;
	}
	$a{crdzk} = "R_".$a{crdzk} if $a{crdzk} =~ /^\d+$/;
	print("relatie ",
	      ($a{btw_nummer} ne "" && $a{btw_nummer} eq "0") ? "--btw=extra " : "",
	      '"', $a{crdzk}, '"', " ",
	      '"', $a{naam}, '"', " ",
	      "4990D",
	      "\n");
	next;
    }
    warn("Geen geldige debiteur/crediteur op regel $., file $ARGV\n");
}
continue {
    close(ARGV) if eof;
}

exit 0;

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'ac5'	=> \$ac5,
		     'all'	=> \$all,
		     'ident'	=> \$ident,
		     'verbose'	=> \$verbose,
		     'trace'	=> \$trace,
		     'help|?'	=> \$help,
		     'debug'	=> \$debug,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident() if $ident;
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    -help		this message
    -ident		show identification
    -verbose		verbose information
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}

__END__
# http://www.exact.nl/docs/BDDocument.asp?Action=View&ID={9ED6913F-ABE3-4239-93B0-57431968F516}&ReturnTo=BDSearch%2Easp
1	debnr	Debiteur	Numstr	Verplicht	A20
2	naam	Naam	Text	Verplicht	A50
3	adres1	Adresregel 1	Text		A30
4	adres2	Adresregel 2	Text		A30
5	postcode	Postcode	Text		A8
6	woonpl	Plaats	Text		A30
7	landcode	Land	Text	Verplicht	A3
8	debzk	Zoekcode	Text	Vervallen	A6
9	valcode	Valuta	Text		A3
10	telnr	Telefoonnumer	Text		A15
11	faxnr	Fax	Text		A15
12	cntpers1	Contactpersoon	Text		A30
13	mv1	Man/Vrouw/Onbekend.	Text		A1
14	prdcode1	Predicaatcode	Text		A4
15	vrlttrs1	Initialen	Text		A10
16	functie1	Functie	Text		A15
17	telnrcp1	Telefoonnummer	Text		A15
18	banknr1	Bankrekening	Elfpr		A10
19	banknaam	Banknaam	Text	Vervallen	A20
20	Empty	-	-		A10
21	postbanknrd	Postbankrekening debiteur	Numstr		A10
22	betwijze	Betaalwijze	Text		A1
23	tegreknr	Tegenrekening	Numstr		A9
24	dagbknr	Dagboek	Numstr	 Vervallen	A2
25	aandacht	Aandacht	J/N		A1
26	categorie	Classificatie	Text		A2
27	fakdebnr	Factuurdebiteur	Numstr		A6
28	kredlimiet	kredietlimiet	Number		N8,2
29	bether	Herinneringen	0/1		A1
30	betcond	Betalingsconditie	Text		A2
31	blokkeer	Blokkeren	N/J		A1
32	verteg	Vertegenwoordiger	Text	Niet ondersteund	A3
33	prijslijst	Prijslijstcode	Text		A3
34	ex_artcode	Code extra artikelomschrijving	Text		A2
35	levwijze	Leveringswijze	Text		A3
36	korting	Kortingspercentage	Number		N3,2
37	datlaanm	Datum laatste herinnering	Date		A8
38	layoutcode	Layout code	Text		A1
39	taalcode	Taalcode	Text		A3
40	debsaldolj	Debet saldo huidig jaar	Number	Overbodig	N8,2
41	crdsaldolj	Credit saldo huidig jaar	Number	Overbodig	N8,2
42	debsaldosj	Debet saldo vorig jaar	Number	Overbodig	N8,2
43	crdsaldosj	Credit saldo vorig jaar	Number	Overbodig	N8,2
44	saldontvwd	Debet saldo te verwerken	Number	Overbodig	N8,2
45	saldontwvc	Credit saldo te verwerken	Number	Overbodig	N8,2
46	omz_ex_lj	Omzet excl. BTW huidig boekjaar	Number	Overbodig	N8,2
47	omz_in_lj	Omzet incl. BTW huidig boekjaar	Number	Overbodig	N8,2
48	omz-ex_vj	Omzet excl. BTW vorig boekjaar	Number	Overbodig	N8,2
49	omz_in_vj	Omzet incl. BTW vorig boekjaar	Number	Overbodig	N8,2
50	bedrorder	Bedrag in order	Number	Overbodig	N8,2
51	faktoring	Factoring	N/J	Vervallen	A1
52	btw_nummer	BTW-nummer	Text		A20
53	Datectrl	Controledatum	Date		A6

# http://www.exact.nl/docs/BDDocument.asp?Action=View&ID={7C19DB9F-4B04-4023-822B-FB0D7D049416}&ReturnTo=BDSearch%2Easp
1	crdnr	Crediteurennummer	Numstr	Verplicht	A6
2	naam	Naam	Text	Verplicht	A50
3	adres1	Adres regel 1	Text		A30
4	adres2	Adres regel 2	Text		A30
5	postcode	Postcode	Text		A8
6	woonpl	Woonplaats	Text		A30
7	landcode	Land	Text	Verplicht	A3
8	crdzk	Zoekcode	Text	Overbodig	A6
9	valcode	Valutacode	Text		A3
10	telnr	Telefoonnummer	Text		A15
11	faxnr	Fax	Text		A15
12	cntpers1	Contactpersoon	Text		A30
13	mv1	Man/Vrouw/Onbekend	Text		A1
14	prdcode1	Predicaat/aanspreektitel	Text		A4
15	vrlttrs1	Initialen	Text		A10
16	functie1	Functie	Text		A15
17	telnrcp1	Telefoonnummer contactpersoon	Text		A15
18	banknr1	Bankrekening 1	Text		A10
19	banknr2	G-rekening	Text		A10
20	banknaam	Banknaam	Text	Vervallen	A20
21	Empty	-			A10
22	pstbanknrc	Postbank account creditor.	Numstr		A10
23	betwijze	Payment method	Text		A1
24	tegreknr	Tegenrekening	Numstr		A9
25	dagbknr	Dagboek	Numstr	Vervallen	A2
26	aandacht	Aandacht	Y/N	Vervallen	A1
27	categorie	Classificatie	Text		A2
28	kredlimiet	Kredietlimiet	Number		N8,2
29	bether	Betalingsherinnering	Y/N		A1
30	betcond	Betalingsconditie	Text		A2
31	blokkeer	Blokkeren	N/Y		A1
32	klantcode	Klantcode	Text		A10
33	prijslijst	Prijslijst	Text		A3
34	ex_artcode	Extra artikelcode	Text		A2
35	korting	Kortingspercentage	Number		N3,2
36	layoutcode	Layoutcode	Text	 Vervallen	A1
37	taalcode	Taalcode	Text		A3
38	Empty	-			A10
39	debsaldolj	Debet saldo huidig boekjaar	Number	Overbodig	N8,2
40	crdsaldolj	Credit saldo huidig boekjaar	Number	Overbodig	N8,2
41	debsaldosj	Debet saldo vorig boekjaar	Number	Overbodig	N8,2
42	crdsaldosj	Credit saldo vorig boekjaar	Number	Overbodig	N8,2
43	saldontvwd	Debet saldo te verwerken	Number	Overbodig	N8,2
44	saldontvwc	Credit saldo te verwerken	Number	Overbodig	N8,2
45	omz_ex_lj	Omzet excl. BTW huidig boekjaar	Number	Overbodig	N8,2
46	omz_in_lj	Omzet incl. BTW huidig boekjaar	Number	Overbodig	N8,2
47	omz_ex_vj	Omzet excl BTW vorig boekjaar	Number	Overbodig	N8,2
48	omz_in_vj	Omzet incl. BTW vorig boekjaar	Number	Overbodig	N8,2
49	bedrbest	Bedrag in order	Number	 Vervallen	N8,2
50	btw_nummer	BTW nummer	Text		A20
51	Datectrl 	Controle datum 	Date 	  	A8
