#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Fri Jun 17 21:31:52 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jun 14 21:55:45 2010
# Update Count    : 253
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
my ($my_name, $my_version) = qw(emimut 1.16);

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 0;		# verbose processing
my $ac5 = 0;			# DaviDOS compatible
my $auto = 0;			# auto gen missing relations
my $renumber = 0;		# renumber per dagboek

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

use EB::Config qw(EekBoek);
use EB::DB;

our $trace = $ENV{EB_SQL_TRACE};

our $dbh = EB::DB->new(trace => $trace);

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

use Text::CSV_XS;
use EB::Format;

@ARGV = (-s "FMUTA6.CSV" ? "FMUTA6.CSV" : "fmuta6.csv") unless @ARGV;

my @fieldnames0;
my @fieldnames;
my $f = \@fieldnames0;
while ( <DATA> ) {
    next if /^#/;
    $f = \@fieldnames, next unless /\S/;
    my @a = split(/\t/);
    push(@$f, $a[1]);
}

my @dagboeken;
my @dbkvolgnr;
my $sth = $dbh->sql_exec("SELECT dbk_id,dbk_desc FROM Dagboeken");
my $rr;
while ( $rr = $sth->fetchrow_arrayref ) {
    $dagboeken[$rr->[0]] = lc($rr->[1]);
    $dbkvolgnr[$rr->[0]] = 1;
}

my $csv = new Text::CSV_XS ({binary => 1});
open (my $db, $ARGV[0])
  or die("Missing: $ARGV[0]\n");

# Collect and split into IV and others.
# This is to prevent BGK bookings to preceede the corresponding IV booking.
my @prim;
my @sec;
while ( <$db> ) {
    s/0""/0,""/g;
    $csv->parse($_);
    my @a = $csv->fields();
    if ( $a[1] =~ /^[iv]$/i ) {
	push(@prim, [@a]);
    }
    else {
	push(@sec, [@a]);
    }
}

# Process bookings.
my $mut;
foreach ( @prim, @sec) {
    my @a = @$_;
    my %a;
    if ( $a[0] == 0 ) {
	flush($mut) if $mut && @$mut > 1;
	@a{@fieldnames0} = @a;
	$mut = [ \%a ];
	next;
    }
    @a{@fieldnames} = @a;
    warn("OOPS: $a[0] should be " . scalar(@$mut) . "\n")
      unless $a[0] == @$mut;
    push(@$mut, \%a);

}
flush($mut) if $mut;

sub flush {
    my ($mut) = @_;
    my $r0 = shift(@$mut);
    my $dbk = $r0->{dagbknr};
    my $dbktype = $r0->{dagb_type};

    my $cmd = $dagboeken[$dbk];
    $cmd =~ s/\s+/_/g if $cmd;		# you won't believe it

    $r0->{crdnr} = "R_".$r0->{crdnr} if $r0->{crdnr} =~ /^\d+$/;
    $r0->{debnr} = "R_".$r0->{debnr} if $r0->{debnr} =~ /^\d+$/;

    if ( $dbktype eq 'I' ) {	# Inkoop
	$cmd ||= "Onbekend_InkoopDagboek";
	foreach my $r ( @$mut ) {
	    check_rel($r0->{crdnr}, $r->{reknr}, "D");
	}
	my $bkstnr = $renumber ? $dbkvolgnr[$dbk]++ : $mut->[0]->{bkstnr};
	print($cmd, ":", $bkstnr, " ", dd($mut->[0]->{Date}),
	      ' "' . ($r0->{oms25}||$mut->[0]->{oms25}) . '"',
	      ' "' . uc($r0->{crdnr}) . '" --totaal=' . (0+$r0->{bedrag}));
	foreach my $r ( @$mut ) {
	    print join(" ", "", '"' . $r->{oms25} . '"',
		       # ($ac5 ? 0-$r->{bedrag} : $r->{bedrag}). ?????
		       $r->{bedrag}.
		       fixbtw($r),
		       $r->{reknr});
	}
	print("\n");
    }
    elsif ( $dbktype eq 'V' ) {	# Verkoop
	$cmd ||= "Onbekend_VerkoopDagboek";
	foreach my $r ( @$mut ) {
	    check_rel($r0->{debnr}, $r->{reknr}, "C");
	}
	my $bkstnr = $renumber ? $dbkvolgnr[$dbk]++ : $mut->[0]->{bkstnr};
	print($cmd, ":", $bkstnr, " ", dd($mut->[0]->{Date}),
	      ' "' . ($r0->{oms25}||$mut->[0]->{oms25}) . '"',
	      ' "' . uc($r0->{debnr}) . '" --totaal=' . ($ac5 ? 0+$r0->{bedrag} : 0-$r0->{bedrag}));
	foreach my $r ( @$mut ) {
	    print join(" ", "", '"' . $r->{oms25} . '"',
		       ($ac5 ? $r->{bedrag} : 0-$r->{bedrag}).
		       fixbtw($r),
		       $r->{reknr});
	}
	print("\n");
    }
#    elsif ( $dbktype eq 'M' ) {	# Memoriaal
#	return unless @$mut;
#	print($cmd, " ", dd($mut->[0]->{Date}));
#	foreach my $r ( @$mut ) {
#	    print join(" ", "",
#		       '"' . $r->{oms25} . '"',
#		       debcrd($r->{reknr}) ? $r->{bedrag} : 0-$r->{bedrag},
#		       $r->{reknr});
#	}
#	print("\n");
#    }
    elsif ( $dbktype =~ /^[GB]$/ ) {	# Bank/Giro
	return unless @$mut;
	$cmd ||= "Onbekend_BankDagboek";

	foreach my $r ( @$mut ) {
	    $r->{crdnr} = "R_".$r->{crdnr} if $r->{crdnr} =~ /^\d+$/;
	    $r->{debnr} = "R_".$r->{debnr} if $r->{debnr} =~ /^\d+$/;
	    if ( $r->{crdnr} ) {
		check_rel($r->{crdnr}, 4990, "D");
	    }
	    elsif ( $r->{debnr} ) {
		check_rel($r->{debnr}, 8000, "C");
	    }
	}

	my $bkstnr = $renumber ? $dbkvolgnr[$dbk]++ : $r0->{bkstnr};
	print($cmd, ":", $bkstnr, " ", dd($mut->[0]->{Date}), ' "', $r0->{oms25} ||"Diverse boekingen", '"');
	my $tot = 0;
	foreach my $r ( @$mut ) {
	    if ( $r->{crdnr} ) {
		print join(" ", " crd",
			   '"'.uc($r->{crdnr}).'"',
			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
#			   sprintf("%.2f", 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    elsif ( $r->{debnr} ) {
		print join(" ", " deb",
			   '"'.uc($r->{debnr}).'"',
			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    else {
		print join(" ", " std",
			   '"'.$r->{oms25}.'"',
			   sprintf("%.2f",
#				   debcrd($r->{reknr}) ? $r->{bedrag} : 0-$r->{bedrag}).
				   $ac5 ? $r->{bedrag} : 0-$r->{bedrag}).
#				   0-$r->{bedrag}).
			   fixbtw($r, 1),
			   $r->{reknr}# . (debcrd($r->{reknr}) ? 'D' : 'C'),
			  );
		$tot += $r->{bedrag};

	    }
	}
	print("\n");
	warn("!!BOEKSTUK ".$r0->{bkstnr}.
	     " IS NIET IN BALANS ($tot)\n")
	  if $dbktype eq "M" && abs($tot) >= 0.01;
    }
    elsif ( $dbktype =~ /^[K]$/ ) {	# Kas
	return unless @$mut;
	$cmd ||= "Onbekend_BankDagboek";

	foreach my $r ( @$mut ) {
	    $r->{crdnr} = "R_".$r->{crdnr} if $r->{crdnr} =~ /^\d+$/;
	    $r->{debnr} = "R_".$r->{debnr} if $r->{debnr} =~ /^\d+$/;
	    if ( $r->{crdnr} ) {
		check_rel($r->{crdnr}, 4990, "D");
	    }
	    elsif ( $r->{debnr} ) {
		check_rel($r->{debnr}, 8000, "C");
	    }
	}

	my $bkstnr = $renumber ? $dbkvolgnr[$dbk]++ : $r0->{bkstnr};
	print($cmd, ":", $bkstnr, " ", dd($mut->[0]->{Date}), ' "', $r0->{oms25} ||"Diverse boekingen", '"');
	my $tot = 0;
	foreach my $r ( @$mut ) {
	    if ( $r->{crdnr} ) {
		print join(" ", " crd",
			   '"'.uc($r->{crdnr}).'"',
			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
#			   sprintf("%.2f", 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    elsif ( $r->{debnr} ) {
		print join(" ", " deb",
			   '"'.uc($r->{debnr}).'"',
			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    else {
		print join(" ", " std",
			   '"'.$r->{oms25}.'"',
			   sprintf("%.2f",
#				   debcrd($r->{reknr}) ? $r->{bedrag} : 0-$r->{bedrag}).
				   $ac5 ? $r->{bedrag} : 0-$r->{bedrag}).
#				   0-$r->{bedrag}).
			   fixbtw($r, 1),
			   $r->{reknr}# . (debcrd($r->{reknr}) ? 'D' : 'C'),
			  );
		$tot += $r->{bedrag};

	    }
	}
	print("\n");
	warn("!!BOEKSTUK ".$r0->{bkstnr}.
	     " IS NIET IN BALANS ($tot)\n")
	  if $dbktype eq "M" && abs($tot) >= 0.01;
    }
    elsif ( $dbktype =~ /^[M]$/ ) {	# Memoriaal;
	return unless @$mut;
	$cmd ||= "Onbekend_Memoriaal";

	foreach my $r ( @$mut ) {
	    $r->{crdnr} = "R_".$r->{crdnr} if $r->{crdnr} =~ /^\d+$/;
	    $r->{debnr} = "R_".$r->{debnr} if $r->{debnr} =~ /^\d+$/;
	    if ( $r->{crdnr} ) {
		check_rel($r->{crdnr}, 4990, "D");
	    }
	    elsif ( $r->{debnr} ) {
		check_rel($r->{debnr}, 8000, "C");
	    }
	}

	my $bkstnr = $renumber ? $dbkvolgnr[$dbk]++ : $r0->{bkstnr};
	print($cmd, ":", $bkstnr, " ", dd($mut->[0]->{Date}), ' "', $r0->{oms25} ||"Diverse boekingen", '"');
	my $tot = 0;
	foreach my $r ( @$mut ) {
	    if ( $r->{crdnr} ) {
		print join(" ", " crd",
			   '"'.uc($r->{crdnr}).'"',
#			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
			   sprintf("%.2f", 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    elsif ( $r->{debnr} ) {
		print join(" ", " deb",
			   '"'.uc($r->{debnr}).'"',
			   sprintf("%.2f", $ac5 ? $r->{bedrag} : 0-$r->{bedrag}),
			  );
		$tot += $r->{bedrag};
	    }
	    else {
		print join(" ", " std",
			   '"'.$r->{oms25}.'"',
			   sprintf("%.2f",
#				   debcrd($r->{reknr}) ? $r->{bedrag} : 0-$r->{bedrag}).
#				   $ac5 ? $r->{bedrag} : 0-$r->{bedrag}).
				   0-$r->{bedrag}).
			   fixbtw($r, 1),
			   $r->{reknr}# . (debcrd($r->{reknr}) ? 'D' : 'C'),
			  );
		$tot += $r->{bedrag};

	    }
	}
	print("\n");
	warn("!!MEMORIAAL BOEKSTUK ".$r0->{bkstnr}.
	     " IS NIET IN BALANS ($tot)\n")
	  if $dbktype eq "M" && abs($tot) >= 0.01;
    }


    #use Data::Dumper;
    #print Dumper($mut);

    $mut = 0;
    #exit;
}

sub fixbtw {
    # Correctie BTW code indien niet conform de grootboekrekening.
    my $r = shift;
    my $must = shift;
    my $b = $r->{btw_code};

    unless ( $r->{btw_bdr} && 0 + $r->{btw_bdr}) {
	return btw_code($r->{reknr}) ? "\@0" : "";
    }
    return "" if $b eq "";

    # FMUTA6.CSV heeft alle bedragen altijd inclusief BTW.
    $b = btwmap($b) unless $ac5;

    my $br = btw_code($r->{reknr});
    return "" if $b == $br && !$must;

    '@'.$b;
}

sub dd {
    my ($date) = @_;

    # Kantelpunt is willekeurig gekozen.
    # 
    sprintf("%04d-%02d-%02d",
	    $3 < 90 ? 2000 + $3 : 1900 + $3, $2, $1)
      if $date =~ /^(\d\d)(\d\d)(\d\d\d?)$/;
}
exit 0;

################ Subroutines ################

my %debcrd;
sub debcrd {
    my($acct) = @_;
    return $debcrd{$acct} if defined $debcrd{$acct};
    _lku($acct);
    $debcrd{$acct};
}

my %btw_code;
sub btw_code {
    my($acct) = @_;
    return $btw_code{$acct} if defined $btw_code{$acct};
    _lku($acct);
    $btw_code{$acct};
}

my %kstomz;
sub kstomz {
    my($acct) = @_;
    return $kstomz{$acct} if defined $kstomz{$acct};
    _lku($acct);
    $kstomz{$acct};
}

sub _lku {
    my ($acct) = @_;
    my $rr = $dbh->do("SELECT acc_debcrd,acc_kstomz,acc_btw".
		      " FROM Accounts".
		      " WHERE acc_id = ?", $acct);
    die("Onbekend rekeningnummer $acct\n")
      unless $rr;
    $debcrd{$acct} = $rr->[0];
    $kstomz{$acct} = $rr->[1];
    $btw_code{$acct} = $rr->[2];
}

my %rel;
sub check_rel {
    my ($code, $acc, $debcrd) = @_;
    $rel{$code} ||= 
      do {
	  my $r = $dbh->do("SELECT rel_acc_id FROM Relaties WHERE rel_code = ?", $code);
	  unless ( $r && $r->[0] ) {
	      print("relatie \"$code\" \"Automatisch aangemaakt voor code $code\" ",
		    $acc, $debcrd, "\n") if $auto;
	      $rel{$code} = $acc;
	  }
	  else {
	      $r->[0];
	  }
      };
}

# Map BTW excl -> incl.
my @btwmap;
sub btwmap {
    my ($code) = @_;
    unless ( defined $btwmap[$code] ) {
	$btwmap[$code] = $dbh->do("SELECT b.btw_id".
				  " FROM BTWTabel a, BTWTabel b".
				  " WHERE a.btw_perc = b.btw_perc".
				  " AND (b.btw_incl OR b.btw_perc = 0)".
				  " AND a.btw_id = ?", $code)->[0];
    }
    $btwmap[$code];
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'ident'	=> \$ident,
		     'ac5'	=> \$ac5,
		     'auto'	=> \$auto,
		     'renumber'	=> \$renumber,
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
# http://www.exact.nl/docs/BDDocument.asp?Action=VIEW&ID=%7B2E238404%2DB177%2D4444%2DA192%2DEF8C037D5704%7D
1	regelnummer	Regelnummer	Number	 Verplicht	N3
2	dagb_type	Dagboektype	Text	 Verplicht	A1
3	dagbknr	Dagboek	Numstr	 Verplicht	A3
4	periode	Periode	Numstr	 niet gebr	A3
5	bkjrcode	Boekjaar	Numstr	 niet gebr	A2
6	bkstnr	Boekstuknummer	Numstr		A8
7	oms25	Omschrijving	Text		A60
8	Date	Datum	Date		A8
9	Empty	-			A9
10	debnr	Debiteur	Numstr	 verkoop	A6
11	crdnr	Crediteur	Numstr	 inkoop	A6
12	Empty	-			A8
13	bedrag	Bedrag	Number	 niet gebr	N8.2
14	drbk_in_val	Journaliseren in VV	Text		A1
15	valcode	Valuta (optioneel)	Text		A3
16	koers	Wisselkoers (optioneel)	Number		N5.6
17	kredbep	Kredietbeperking / Betalingskorting	Text		A1
18	bdrkredbep	Bedrag Kredietbeperking / Betalingskorting	Number		N8.2
19	vervdatfak	Vervaldatum factuur	Date		A8
20	vervdatkrd	Vervaldatum Kredietbeperking / Betalingskorting	Date		A8
21	Empty	-			A3
22	Empty	-			N8.2
23	weeknummer	Weeknummer	Numstr	 niet gebr	A2
24	betaalref	Betaalreferentie	Text		A20
25	betwijze	Betaalwijze	Text		A1
26	grek_bdr	Bedrag G-rekening	Number		N8.2
27	Empty	-			A4
28	Empty	-			A4
29	Empty	-			8.2
30	Empty	-			A1
31	Empty	-			A2
32	storno	Stornoboeking	Text		A1
33	Empty	-			A8
34	Empty	-			N8.2
35	Empty	-			N8.2
36	Empty	-			N6.2
37	Empty	-			N6.2
38	Empty	-			A8
39	Empty	-			A25
40	Empty	-		 Verplicht	A8

1	regelnummer	regelnummer	Number	 Verplicht	N3
2	dagb_type	Dagboektype	Text	 Verplicht	A1
3	dagbknr	Dagboek	Numstr	 Verplicht	A3
4	periode	Periode	Numstr	 niet gebr	A3
5	bkjrcode	Boekjaar	Numstr	 niet gebr	A2
6	bkstnr	Boekstuknummer	Numstr		A8
7	oms25	Omschrijving	Text		A60
8	Date	Datum	Date		A8
9	reknr	Grootboekrekening	Numstr	 Verplicht	A9
10	debnr	Debiteur	Numstr	 Memoriaal	A6
11	crdnr	Crediteur	Numstr	 Memoriaal	A6
12	faktuurnr	Onze referentie	Numstr		A8
13	bedrag	Bedrag	Number	 Verplicht	N8.2
14	Empty	-			A1
15	valcode	Valuta	Text		A3
16	koers	Wisselkoers	Number		N5.6
17	Empty	-			A1
18	Empty	-			N8.2
19	Empty	-			A8
20	Empty	-			A8
21	btw_code	BTW-code	Text		A3
22	btw_bdr	BTW-bedrag	Number		N8.2
23	Empty	-			A2
24	Empty	-			A20
25	Empty	-			A1
26	Empty	-			N8.2
27	kstplcode	Kostenplaatscode	Text		A8
28	kstdrcode	Kostendragercode	Text		A8
29	aantal	Aantal	Number		N8.2
30	Empty	-			A1
31	Empty	-			A2
32	storno	Stornoboeking	Text		A1
33	Empty	-			A8
34	Empty	-			N8.2
35	Empty	-			N8.2
36	Empty	-			N6.2
37	Empty	-			N6.2
38	Empty	-			A8
39	Empty	-			A25
40	Empty	-		 Verplicht	A8
