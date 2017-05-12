#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : June 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jun 14 21:54:46 2010
# Update Count    : 323
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;

# Package name.
my $my_package = 'EekBoek';
# Program name and version.
my ($my_name, $my_version) = qw(dvimport 1.22);

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 0;		# verbose processing
my $ac5 = 0;			# DaviDOS compatible

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

use POSIX qw(tzset strftime);
tzset();
my @tm = localtime(time);
my $tsdate = strftime("%Y-%m-%d %k:%M:%S +0100", @tm[0..5], -1, -1, -1);

################ The Process ################

use EB::Config qw(EekBoek);
use EB::Globals;
use EB::Format;

read_exact_data();

write_rekeningschema();

exit 0;

################ Subroutines ################

use Data::Dumper;
use Encode;

my $db;

sub read_exact_data {

    open ($db, "<EXACT61.TXT") ||
      open ($db, "<exact61.txt") || die("Missing: EXACT61.TXT\n");
    my $next;
    while ( <$db> ) {
	if ( /^ ?HOOFDVERDICHTINGEN/ ) {
	    $next = \&read_hoofdverdichtingen;
	}
	elsif ( /^ ?VERDICHTINGEN/ ) {
	    $next = \&read_verdichtingen;
	}
	elsif ( /^ ?BTW-TARIEVEN/ ) {
	    $next = \&read_btw;
	}
	elsif ( /^ ?DAGBOEKEN/ ) {
	    $next = \&read_dagboeken;
	}
	elsif ( /^-{40}/ ) {
	    next unless $next;
	    $next->(0);
	}
	elsif ( /^ Í{40}/ ) {
	    next unless $next;
	    $next->(1);
	}
	elsif ( /^ \201{40}/ ) {
	    next unless $next;
	    $next->(1);
	}
    }
    close($db);
    read_grootboek();
    sql_constants();
}

sub sql_constants {
    my $out = "-- Constants. DO NOT MODIFY.\n".
      "COPY Constants (name, value) FROM stdin;\n";

    foreach my $key ( sort(@EB::Globals::EXPORT) ) {
	no strict;
	next if prototype($key);
	next if ref($key->());
	#next unless $key->() =~ /^\d+$/ || $key->() =~ /^\[.*\]$/;
	$out .= "$key\t" . $key->() . "\n";
    }
    $out .= "KO_OK\t0\n";
    $out .= "\\.\n";
    open(my $f, ">constants.sql") or die("Cannot create constants.sql: $!\n");
    print $f $out;
    close($f);
}

sub _trim {
    my ($t) = @_;
    for ( $t ) {
	s/\s+/ /g;
	s/^\s+//;
	s/\s+$//;
	return $_;
    }
}

sub _tsv {
    join("\t", map { _trim($_) } @_) . "\n";
}

sub read_dagboeken {
    my ($off) = @_;
    my @dagboeken;
    while ( <$db> ) {
	last unless $_ =~ /\S/;
	substr($_, 0, $off) = "" if $off;

	my @a = split(' ', $_);
	my ($id, $desc, $type, $aux);
	$id = shift(@a);
	$aux = pop(@a);
	$type = pop(@a);
	$desc = "@a";
	$desc =~ s/\s+/_/g;

	$dagboeken[0+$id] = [ $desc, $type, lc($aux) eq "n.v.t." ? "\\N" : 0+$aux ];

#	# 1     Kas                                      Kas                 1000
#	#my @a = unpack("a6a41a20a6", $_);
#	my @a = /^(\d+)\s+(\S+)\s+(\S+)\s+(\d+|n\.v\.t\.)\s*$/i;
#	for ( @a[1,2] ) {
#	    s/\s+$//;
#	}
#	$dagboeken[0+$a[0]] = [ @a[1,2], lc($a[3]) eq "n.v.t." ? "\\N" : 0+$a[3] ];
    }

    open(my $f, ">dbk.sql") or die("Cannot create dbk.sql: $!\n");

    print $f ("-- Dagboeken\n\n",
	      "COPY Dagboeken (dbk_id, dbk_desc, dbk_type, dbk_acc_id) FROM stdin;\n");
    my %dbmap = ("Kas"	      => DBKTYPE_KAS,
		 "Bank/Giro"  => DBKTYPE_BANK,
		 "Bank"       => DBKTYPE_BANK,
		 "Giro"       => DBKTYPE_BANK,
		 "Inkoop"     => DBKTYPE_INKOOP,
		 "Verkoop"    => DBKTYPE_VERKOOP,
		 "Memoriaal"  => DBKTYPE_MEMORIAAL );

    for ( my $i = 0; $i < @dagboeken; $i++ ) {
	next unless exists $dagboeken[$i];
	my $db = $dagboeken[$i];
	print $f (_tsv($i, $db->[0], $dbmap{$db->[1]}, $db->[2]));
    }
    print $f ("\\.\n\n");

    print $f("-- Sequences for Boekstuknummers, one for each Dagboek\n\n");

    for ( my $i = 0; $i < @dagboeken; $i++ ) {
	next unless exists $dagboeken[$i];
	print $f ("CREATE SEQUENCE bsk_nr_${i}_seq;\n");
    }
    print $f ("\n");
    close($f);
}

my @hoofdverdichtingen;

sub read_hoofdverdichtingen {
    my ($off) = @_;
    while ( <$db> ) {
	last unless $_ =~ /\S/;
	substr($_,0,$off) = "" if $off;
	# 2        Vlottende activa
	my @a = m/(\d+)\s+(.*)/;
	for ( $a[1] ) {
	    s/\s+$//;
	}
	$hoofdverdichtingen[$a[0]] = [ $a[1], undef ]; # desc balres
    }
}

my @verdichtingen;

sub read_verdichtingen {
    my ($off) = @_;
    while ( <$db> ) {
	last unless $_ =~ /\S/;
	substr($_,0,$off) = "" if $off;
	# 21       Handelsvoorraden                             2
	my @a = m/^(\d+)\s+(.*?)\s+(\d+)\s*$/;
	for ( $a[1] ) {
	    s/\s+$//;
	}
	$verdichtingen[$a[0]] = [ $a[1], undef, undef, 0+$a[2] ]; # desc balres kstomz hoofdverdichting
    }
}

my %grootboek;
my @transactions;
my $op_deb;
my $op_crd;
INIT {
    $op_deb = $op_crd = 0;
}

sub read_grootboek {
    use Text::CSV_XS;
    my $csv = new Text::CSV_XS ({binary => 1});
    my $db;
    open ($db, "<GRTBK.CSV") ||
      open ($db, "<grtbk.csv")
	|| die("Missing: GRTBK.CSV\n");
    while ( <$db> ) {
	if ( $csv->parse($_) ) {
	    my @a = $csv->fields();
	    $grootboek{0+$a[0]} =
	      [ @a[1,3,4,5,6,7,12] ]; # desc B/W D/C N/.. struct btw N/J(omzet)?
	    my $balance = $a[17] - $a[16];
	    if ( $balance ) {
		$balance = -$balance if $a[4] eq 'D';
		push(@transactions, [0+$a[0], $balance]);
		if ( $balance < 0 ) {
		    $a[4] = ($a[4] eq 'D') ? 'C' : 'D';
		    $balance = -$balance;
		}
		if ( $a[4] eq 'C' ) {
		    $op_crd += $balance;
		}
		else {
		    $op_deb += $balance;
		}
	    }
	    $balance = $a[19] - $a[18];
	    if ( $balance ) {
		warn(sprintf("GrbRk $a[0]: saldo = %.2f\n", $balance));
	    }
	    $verdichtingen[$a[6]][1] = $a[3];  # balres
	    $verdichtingen[$a[6]][2] = $a[12]; # kstomz
	}
	else {
	    warn("Parse error at line $.\n");
	}
    }
    # print Dumper(\%grootboek);
    foreach ( @verdichtingen ) {
	next unless $_;
	$hoofdverdichtingen[$_->[3]][1] = $_->[1];
	$hoofdverdichtingen[$_->[3]][2] = $_->[2];
    }
}

sub read_btw {
    my ($off) = @_;
    my $hi;
    my $lo;
    my $btw_acc_hi_i;
    my $btw_acc_hi_v;
    my $btw_acc_lo_i;
    my $btw_acc_lo_v;
    my @btwtable;

    while ( <$db> ) {
	last unless $_ =~ /\S/;
	substr($_, 0, $off) = "" if $off;

	# Nr.   Omschrijving                             Perc.  Type  Ink.reknr. Verk.reknr.
	# ----------------------------------------------------------------------------------
	# 1     BTW 17,5% incl.                          17,50  Incl. 1520       1500       
	# 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	#          1         2         3         4         5         6         7         8         9
	#my @a = unpack("a6a41a7a6a11a*", $_);
	my @a = m/^(\d+)\s+(.+?)\s+(\d\d?[.,]\d\d)\s+((?:In|Ex)cl(?:\.|usief))\s+(?:$|(\d+)\s+(\d+))\s*$/;
	warn("? $_"), next unless $a[1];

	# 3 - BTW 6% -> code 3 -- NOT!
	if ( $a[1] =~ /^(\d+) - (.*)/ ) {
	    #$a[0] = $1;
	    $a[1] = $2;
	}
	for ( @a[1,2,3] ) {
	    s/\s+$//;
	}

	my $btw = amount($a[2]);
	if ( AMTPRECISION > BTWPRECISION-2 ) {
	    $btw = substr($btw, 0, length($btw) - (AMTPRECISION - BTWPRECISION-2))
	}
	elsif ( AMTPRECISION < BTWPRECISION-2 ) {
	    $btw .= "0" x (BTWPRECISION-2 - AMTPRECISION);
	}
	$btwtable[$a[0]] = [ $a[1], $btw,
			     $a[3] =~ /^I/ ? 't' : 'f' ];

	if ( $btw ) {
	    if ( !$lo || $btw < $lo ) {
		$lo = $btw;
		undef $btw_acc_lo_i;
		undef $btw_acc_lo_v;
	    }
	    if ( !$hi || $btw > $hi ) {
		$hi = $btw;
		undef $btw_acc_hi_i;
		undef $btw_acc_hi_v;
	    }
	}
	next unless $btw;

	if ( $btw == $hi ) {
	    if ( $btw_acc_hi_i && ($btw_acc_hi_i != $a[4] || $btw_acc_hi_v != $a[5]) ) {
		warn("BTW probleem 1\n");
	    }
	    else {
		$btw_acc_hi_i = 0+$a[4];
		$btw_acc_hi_v = 0+$a[5];
	    }
	}
	elsif ( $btw == $lo ) {
	    if ( $btw_acc_lo_i && ($btw_acc_lo_i != $a[4] || $btw_acc_lo_v != $a[5]) ) {
		warn("BTW probleem 2\n");
	    }
	    else {
		$btw_acc_lo_i = 0+$a[4];
		$btw_acc_lo_v = 0+$a[5];
	    }
	}
    }
    foreach ( @btwtable ) {
	push(@$_, $_->[1] == 0 ? BTWTARIEF_NUL :
	     $_->[1] == $hi ? BTWTARIEF_HOOG :
	     $_->[1] == $lo ? BTWTARIEF_LAAG : warn("Onbekende BTW group: $_->[1]\n"));
    }

    open(my $f, ">btw.sql") or die("Cannot create btw.sql: $!\n");

    print $f ("-- BTW Tabel\n\n",
	      "COPY BTWTabel (btw_id, btw_desc, btw_perc, btw_incl, btw_tariefgroep) FROM stdin;\n");

    for ( my $i = 0; $i < @btwtable; $i++ ) {
	next unless exists $btwtable[$i];
	my $b = $btwtable[$i];
	print $f (_tsv($i, @$b));
    }

    print $f ("\\.\n\n");
    close($f);

}

sub write_rekeningschema {

    open(my $f, ">vrd.sql") or die("Cannot create vrd.sql: $!\n");

    print $f ("-- Hoofdverdichtingen\n\n",
	      "COPY Verdichtingen (vdi_id, vdi_desc, vdi_balres, vdi_kstomz, vdi_struct)".
	      " FROM stdin;\n");
    for ( my $i = 0; $i < @hoofdverdichtingen; $i++ ) {
	next unless exists $hoofdverdichtingen[$i];
	my $v = $hoofdverdichtingen[$i];
	# Skip unused verdichtingen.
	next unless defined($v->[1]) && defined($v->[2]);
	$v->[0] = decode("cp-850", $v->[0]) if $ac5;
	print $f (_tsv($i,
		       $v->[0],
		       $v->[1] eq 'B' ? 't' : 'f',
		       $v->[2] eq 'N' ? 't' : 'f',
		       "\\N"));
    }
    print $f ("\\.\n\n");

    print $f ("-- Verdichtingen\n\n",
	      "COPY Verdichtingen (vdi_id, vdi_desc, vdi_balres, vdi_kstomz, vdi_struct) FROM stdin;\n");
    for ( my $i = 0; $i < @verdichtingen; $i++ ) {
	next unless exists $verdichtingen[$i];
	my $v = $verdichtingen[$i];
	# Skip unused verdichtingen.
	next unless defined($v->[1]) && defined($v->[2]);
	$v->[0] = decode("cp-850", $v->[0]) if $ac5;
	print $f (_tsv($i,
		       $v->[0],
		       $v->[1] eq 'B' ? 't' : $v->[1] eq 'W' ? 'f' : '?',
		       $v->[2] eq 'N' ? 't' : $v->[2] eq 'J' ? 'f' : '?',
		       $v->[3]));
    }
    print $f ("\\.\n\n");
    close($f);

    open($f, ">acc.sql") or die("Cannot create acc.sql: $!\n");

    print $f ("-- Grootboekrekeningen\n\n",
	      "COPY Accounts (acc_id, acc_desc, acc_struct, acc_balres, acc_debcrd,".
	      " acc_kstomz, acc_btw, acc_ibalance, acc_balance) FROM stdin;\n");

    for my $i ( sort { $a <=> $b } keys(%grootboek) ) {
	my $g = $grootboek{$i};
	# desc B/W D/C N/.. struct btw N/J(omzet)?
	$g->[0] = decode("cp-850", $g->[0]) if $ac5;
	print $f (_tsv($i,
		       $g->[0],
		       $g->[4],
		       $g->[1] eq 'B' ? 't' : 'f',
		       $g->[2] eq 'D' ? 't' : 'f',
		       $g->[6] eq 'N' ? 't' : 'f',
		       $g->[5],
		       0,
		       0));
    }
    print $f ("\\.\n\n");
    close($f);

    open($f, ">std.sql") or die("Cannot create std.sql: $!\n");

    print $f ("-- Standaardrekeningen\n",
	      "INSERT INTO Standaardrekeningen\n",
	      " (std_acc_crd, std_acc_winst, std_acc_btw_il, std_acc_deb,".
	      " std_acc_btw_vh, std_acc_btw_ok, std_acc_btw_vl, std_acc_btw_ih)\n",
	      "VALUES (1600, 500, 1530, 1200, 1500, 1560, 1510, 1520);\n");
    close($f);

    die("Openingsbalans is niet in balans: $op_deb <> $op_crd\n")
      unless sprintf("%.2f", $op_deb) == sprintf("%.2f", $op_crd);

    open($f, ">opening.eb") or die("Cannot create opening.eb: $!\n");

    print $f ("# Data voor openingsbalans:\n\n");
    printf $f ("adm_balanstotaal %10.2f\n", $op_deb);
    foreach ( @transactions ) {
	printf $f ("adm_balans %5d %10.2f\n", @$_);
    }
    print $f ("\n");

    close($f);

}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions('ident'	=> \$ident,
		   'verbose'	=> \$verbose,
		   'ac5'	=> \$ac5,
		   'trace'	=> \$trace,
		   'help|?'	=> \$help,
		   'man'	=> \$man,
		   'debug'	=> \$debug)
	  or pod2usage(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	# Load Pod::Usage only if needed.
	require "Pod/Usage.pm";
	import Pod::Usage;
	pod2usage(1) if $help;
	pod2usage(VERBOSE => 2) if $man;
    }
}
