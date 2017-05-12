#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Sun Aug 14 18:10:49 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Sep  6 14:38:33 2012
# Update Count    : 934
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;
our $dbh;

package EB::Tools::Schema;

use strict;
use warnings;

our $sql = 0;			# load schema into SQL files
my $trace = $cfg->val(__PACKAGE__, "trace", 0);

################ The Process ################

use EB;
use EB::Format;
use EB::DB;
use Encode;

################ Subroutines ################

################ Schema Loading ################

my $schema;
my %km;				# keyword map

sub create {
    shift;			# singleton class method
    my ($name) = @_;
    my $file;
    if ( $name !~ /^\w+$/) {
	$file = $name;
    }
    else {
	foreach my $dir ( ".", "schema" ) {
	    foreach my $ext ( ".dat" ) {
		next unless -s "$dir/$name$ext";
		$file = "$dir/$name$ext";
		last;
	    }
	}
	$file = findlib("schema/$name.dat") unless $file;
    }

    die("?".__x("Onbekend schema: {schema}", schema => $name)."\n") unless $file;
    open(my $fh, "<", $file)
      or die("?".__x("Toegangsfout schema data: {err}", err => $!)."\n");
    $schema = $name;
    _create1(undef, sub { <$fh> });
    seek( $fh, 0, 0 );
    _create2(undef, sub { <$fh> });
    __x("Schema {schema} geïnitialiseerd", schema => $name);
}

sub _create1 {			# 1st pass
    shift;			# singleton class method
    my ($rl) = @_;
    $dbh = EB::DB->new(trace => $trace) unless $sql;
    load_schema1($rl);
}
sub _create2 {			# 2nd pass
    shift;			# singleton class method
    my ($rl) = @_;
    load_schema2($rl);
}

my @hvdi;			# hoofdverdichtingen
my @vdi;			# verdichtingen
my $max_hvd;			# hoogste waarde voor hoofdverdichting
my $max_vrd;			# hoogste waarde voor verdichting
my %acc;			# grootboekrekeningen
my $chvdi;			# huidige hoofdverdichting
my $cvdi;			# huidige verdichting
my %std;			# standaardrekeningen
my %dbk;			# dagboeken
my @dbk;			# dagboeken
my @btw;			# btw tarieven
my %btw;			# btw aliases
my $btw_auto;			# btw auto code
my %btwmap;			# btw type/incl -> code
my $fail;			# any errors

sub init_vars {
    @hvdi = ();			# hoofdverdichtingen
    @vdi = ();			# verdichtingen
    undef $max_hvd;		# hoogste waarde voor hoofdverdichting
    undef $max_vrd;		# hoogste waarde voor verdichting
    %acc = ();			# grootboekrekeningen
    undef $chvdi;		# huidige hoofdverdichting
    undef $cvdi;		# huidige verdichting
    %std = ();			# standaardrekeningen
    %dbk = ();			# dagboeken
    @dbk = ();			# dagboeken
    @btw = ();			# btw tarieven
    %btw = ();			# btw aliases
    $btw_auto = BTW_CODE_AUTO;	# btw auto code
    %btwmap = ();		# btw type/incl -> code
    undef $fail;		# any errors
    init_kmap();
}

sub init_kmap {
    %km = ();

    ####FIXME: Use N__ and __XN and friends.

    # BTW tariefgroepen.
    $km{tg_hoog}	 = __xt("scm:tg:hoog");
    $km{tg_laag}	 = __xt("scm:tg:laag");
    $km{tg_nul}		 = __xt("scm:tg:nul");
    $km{tg_geen}	 = __xt("scm:tg:geen");
    $km{tg_privé}	 = __xt("scm:tg:privé");
    $km{tg_anders}	 = __xt("scm:tg:anders");

    # Koppelingen.
    $km{winst}		 = __xt("scm:std:winst");
    $km{crd}		 = __xt("scm:std:crd");
    $km{deb}		 = __xt("scm:std:deb");
    $km{btw_il}		 = __xt("scm:std:btw_il");
    $km{btw_vl}		 = __xt("scm:std:btw_vl");
    $km{btw_ih}		 = __xt("scm:std:btw_ih");
    $km{btw_vp}		 = __xt("scm:std:btw_vp");
    $km{btw_ip}		 = __xt("scm:std:btw_ip");
    $km{btw_va}		 = __xt("scm:std:btw_va");
    $km{btw_ia}		 = __xt("scm:std:btw_ia");
    $km{btw_ok}		 = __xt("scm:std:btw_ok");
    $km{btw_vh}		 = __xt("scm:std:btw_vh");

    # Section headings.
    $km{hdr_verdichting} = __xt("scm:hdr:Verdichting");
    $km{hdr_balans}      = __xt("scm:hdr:Balansrekeningen");
    $km{balans}		 = __xt("scm:balans");
    $km{hdr_resultaat}   = __xt("scm:hdr:Resultaatrekeningen");
    $km{result}		 = __xt("scm:result");
    $km{hdr_dagboeken}	 = __xt("scm:hdr:Dagboeken");
    $km{dagboeken}	 = __xt("scm:dagboeken");
    $km{hdr_btwtarieven} = __xt("scm:hdr:BTW Tarieven");

    # Daybook Types.
    $km{inkoop}		 = __xt("scm:dbk:inkoop");
    $km{verkoop}	 = __xt("scm:dbk:verkoop");
    $km{bank}		 = __xt("scm:dbk:bank");
    $km{kas}		 = __xt("scm:dbk:kas");
    $km{memoriaal}	 = __xt("scm:dbk:memoriaal");

    # Misc.
    $km{inclusief}	 = __xt("scm:inclusief");
    $km{exclusief}	 = __xt("scm:exclusief");
    $km{incl}		 = __xt("scm:incl");
    $km{excl}		 = __xt("scm:excl");
    $km{btw}		 = __xt("scm:btw");
    $km{vanaf}		 = __xt("scm:vanaf");
    $km{tot}		 = __xt("scm:tot");
    $km{kosten}		 = __xt("scm:kosten");
    $km{kostenrekening}	 = __xt("scm:kostenrekening");
    $km{omzet}		 = __xt("scm:omzet");
    $km{omzetrekening}	 = __xt("scm:omzetrekening");
    $km{koppeling}	 = __xt("scm:koppeling");
    $km{type}		 = __xt("scm:type");
    $km{rek}		 = __xt("scm:rek");
    $km{rekening}	 = __xt("scm:rekening");
    $km{percentage}	 = __xt("scm:percentage");
    $km{perc}		 = __xt("scm:perc");
    $km{tariefgroep}	 = __xt("scm:tariefgroep");
}

sub _xt {			# scm:btw -> scm:vat -> vat
    my $t = _T(shift);
    $t =~ s/^.*://;
    $t;
}

sub _xtr {			# scm:vat -> scm:btw -> btw
    my $t = shift;
    (my $pfx, $t) = ( $1, $2 ) if $t =~ /^(.*):(.*)/;
    keys(%km);			# reset iteration
    while ( my ($k, $v) = each %km ) {
	next unless $t eq $v;
	return $1 if $k =~ /^tg_(.*)/;
	return $k;
    }
    undef;
}

sub error { warn('?', @_); $fail++; }

my $dbkid;

sub scan_dagboeken {
    return 0 unless /^\s+(\w{1,4})\s+(.*)/ && $1;
    $dbkid++;

    my ($id, $desc) = ($1, $2);
    error(__x("Dubbel: dagboek {dbk}", dbk => $id)."\n") if defined($dbk{$id});

    my $type;
    my $dcsplit,
    my $rek = 0;
    my $extra;
    while ( $desc =~ /^(.+?)\s+:([^\s:]+)\s*$/ ) {
	$desc = $1;
	$extra = $2;
	if ( $extra =~ m/^$km{type}=(\S+)$/i ) {
	    my $t = DBKTYPES;
	    for ( my $i = 0; $i < @$t; $i++ ) {
		next unless lc($1) eq lc(_xt("scm:dbk:".lc($t->[$i])));
		$type = $i;
		last;
	    }
	    error(__x("Dagboek {id} onbekend type \"{type}\"",
		      id => $id, type => $1)."\n") unless defined($type);
	}
	elsif ( $extra =~ m/^(?:$km{rek}|$km{rekening})?=(\d+)$/i ) {
	    $rek = $1;
	}
	elsif ( $extra =~ m/^dc$/i ) {
	    $dcsplit = 1;
	}
	else {
	    error(__x("Dagboek {id}: onbekende info \"{info}\"",
		      id => $id, info => $extra)."\n");
	}
    }

    error(__x("Dagboek {id}: het :type ontbreekt", id => $id)."\n") unless defined($type);
    error(__x("Dagboek {id}: het :rekening nummer ontbreekt", id => $id)."\n")
      if ( $type == DBKTYPE_KAS || $type == DBKTYPE_BANK ) && !$type;
    error(__x("Dagboek {id}: :dc is alleen toegestaan voor Kas en Bankboeken", id => $id)."\n")
      if $dcsplit && !( $type == DBKTYPE_KAS || $type == DBKTYPE_BANK );

    my $t = lc(_T($desc));
    $t =~ s/\s+/_/g;
    error(__x("Dagboek naam \"{dbk}\" is niet toegestaan.", dbk => $desc)."\n")
      if $desc =~ /^adm[ _]/i || defined &{"EB::Shell::do_$t"};


    $dbk{$id} = $dbkid;
    $dbk[$dbkid] = [ $id, $desc, $type, $dcsplit, $rek||undef ];
}

sub scan_btw {
    return 0 unless /^\s+(\w+-?)\s+(.*)/;

    my ($id, $desc) = ($1, $2);
    my $id0 = $id;		# for messages
    my $alias;

    unless ( $id =~ /^\d+$/ ) {
	error(__x("Ongeldige code voor BTW tarief: {id} (moet minstens twee tekens zijn)", id => $id0)."\n")
	  if length($id) < 3;	# prevent clash with HK and such.
	error(__x("Dubbel: BTW tarief {id}", id => $id0)."\n")
	  if exists($btw{lc $id});
	$btw_auto += 2;
	$btw{lc $id} = $btw_auto;
	$alias = lc $id;
	$id = $btw_auto;
    }
    else {
	error(__x("Ongeldige code voor BTW tarief: {id}", id => $id0)."\n")
	  if $id > BTW_CODE_AUTO;
    }
    error(__x("Dubbel: BTW tarief {id}", id => $id0)."\n") if defined($btw[$id]);

    my $perc;
    my $groep = 0;
    my $incl = 1;
    my $sdate;
    my $edate;
    my $extra;
    while ( $desc =~ /^(.+?)\s+:([^\s:]+)\s*$/ ) {
	$desc = $1;
	$extra = $2;
	if ( $extra =~ m/^(?:$km{perc}|$km{percentage})?=(\S+)$/i ) {
	    $perc = amount($1);
	    if ( AMTPRECISION > BTWPRECISION-2 ) {
		$perc = substr($perc, 0, length($perc) - (AMTPRECISION - BTWPRECISION-2))
	    }
	    elsif ( AMTPRECISION < BTWPRECISION-2 ) {
		$perc .= "0" x (BTWPRECISION-2 - AMTPRECISION);
	    }
	}
	elsif ( $extra =~ m/^$km{tariefgroep}=$km{tg_hoog}$/i ) {
	    $groep = BTWTARIEF_HOOG;
	}
	elsif ( $extra =~ m/^$km{tariefgroep}=$km{tg_laag}$/i ) {
	    $groep = BTWTARIEF_LAAG;
	}
	elsif ( $extra =~ m/^$km{tariefgroep}=($km{tg_nul}|$km{tg_geen})$/i ) {
	    $groep = BTWTARIEF_NUL;
	    warn("!"._T("Gelieve BTW tariefgroep \"Geen\" te vervangen door \"Nul\"")."\n")
	      if lc($1) eq $km{tg_geen};
	}
	elsif ( $extra =~ m/^$km{tariefgroep}=(prive|$km{tg_privé})$/i ) {
	    $groep = BTWTARIEF_PRIV;
	}
	elsif ( $extra =~ m/^$km{tariefgroep}=$km{tg_anders}$/i ) {
	    $groep = BTWTARIEF_ANDERS;
	}
	elsif ( $extra =~ m/^(?:$km{incl}|$km{inclusief})$/i ) {
	    $incl = 1;
	}
	elsif ( $extra =~ m/^(?:$km{excl}|$km{exclusief})$/i ) {
	    $incl = 0;
	}
	elsif ( $extra =~ m/^(?:$km{vanaf})=(.+)$/i ) {
	    $sdate = $1;
	    error("Ongeldige datumaanduiding in {key}: {value}",
		  key => $km{vanaf}, value => $sdate)
	      unless $sdate =~ /^(\d{4}-\d\d-\d\d)$/;
	    $sdate = parse_date($1)
	      or error(__x("Ongeldige datumaanduiding in {key}: {value}",
			   key => $km{vanaf}, value => $1));
	}
	elsif ( $extra =~ m/^(?:$km{tot})=(.+)$/i ) {
	    $edate = $1;
	    error("Ongeldige datumaanduiding in {key}: {value}",
		  key => $km{tot}, value => $sdate)
	      unless $edate =~ /^(\d{4}-\d\d-\d\d)$/;
	    $edate = parse_date($1, undef, -1)
	      or error(__x("Ongeldige datumaanduiding in {key}: {value}",
			   key => $km{tot}, value => $1));
	}
	else {
	    error(__x("BTW tarief {id}: onbekende info \"{info}\"",
		      id => $id0, info => $extra)."\n");
	}
    }

    error(__x("BTW tarief {id}: geen percentage en de tariefgroep is niet \"{none}\"",
	      id => $id0, none => _T("geen"))."\n")
      unless defined($perc) || $groep == BTWTARIEF_NUL;

    # Add the definition. Automatically add one for the non-$incl variant if it is named.
    $btw[$id]   = [ $id,  $alias, $desc,
		    $groep, $perc, $incl,  $sdate, $edate ];
    $btw[$id+1] = [ $id+1, undef, $alias.($incl?'-':'+'),
		    $groep, $perc, !$incl, $sdate, $edate ]
      if $id > BTW_CODE_AUTO;

    if ( $groep == BTWTARIEF_NUL && !defined($btwmap{n}) ) {
	$btwmap{n} = $id;
    }
    else {
	my $pfx = $incl ? "" : "-";
	if ( $groep == BTWTARIEF_HOOG && !defined($btwmap{"h$pfx"}) ) {
	    $btwmap{"h$pfx"} = $id;
	}
	elsif ( $groep == BTWTARIEF_LAAG && !defined($btwmap{"l$pfx"}) ) {
	    $btwmap{"l$pfx"} = $id;
	}
	elsif ( $groep == BTWTARIEF_PRIV && !defined($btwmap{"p$pfx"}) ) {
	    $btwmap{"p$pfx"} = $id;
	}
	elsif ( $groep == BTWTARIEF_ANDERS && !defined($btwmap{"a$pfx"}) ) {
	    $btwmap{"a$pfx"} = $id;
	}
    }
    $btwmap{$id} = $id;
    $btwmap{$alias} = $id if defined($alias) && $alias !~ /^\d+$/;
    1;
}

sub scan_balres {
    my ($balres) = shift;
    if ( /^\s*(\d+)\s+(.+)/ && length($1) <= length($max_hvd) && $1 <= $max_hvd ) {
	error(__x("Dubbel: hoofdverdichting {vrd}", vrd => $1)."\n") if exists($hvdi[$1]);
	$hvdi[$chvdi = $1] = [ $2, $balres ];
    }
    elsif ( /^\s*(\d+)\s+(.+)/ && length($1) <= length($max_vrd) && $1 <= $max_vrd ) {
	error(__x("Dubbel: verdichting {vrd}", vrd => $1)."\n") if exists($vdi[$1]);
	error(__x("Verdichting {vrd} heeft geen hoofdverdichting", vrd => $1)."\n") unless defined($chvdi);
	$vdi[$cvdi = $1] = [ $2, $balres, $chvdi ];
    }
    elsif ( /^\s*(\d+)\s+(\S+)\s+(.+)/ ) {
	my ($id, $flags, $desc) = ($1, $2, $3);
	error(__x("Dubbel: rekening {acct}", acct => $1)."\n") if exists($acc{$id});
	error(__x("Rekening {id} heeft geen verdichting", id => $id)."\n") unless defined($cvdi);
	my $debcrd;
	my $kstomz;
	my $dcfixed;
	if ( ($balres ? $flags =~ /^[dc]\!?$/i : $flags =~ /^[kon]$/i)
	     ||
	     $flags =~ /^[dc][ko]$/i ) {
	    $debcrd = $flags =~ /d/i;
	    $kstomz = $flags =~ /k/i if $flags =~ /[ko]/i;
	    $dcfixed = $flags =~ /\!/;
	}
	else {
	    error(__x("Rekening {id}: onherkenbare vlaggetjes {flags}",
		      id => $id, flags => $flags)."\n");
	}

	my $btw_type = 'n';
	my $btw_ko;
	my $extra;

	while ( $desc =~ /^(.+?)\s+:([^\s:]+)\s*$/ ) {
	    $desc = $1;
	    $extra = $2;
	    if ( $extra =~ m/^$km{btw}=(.+)$/i ) {
		my $spec = $1;
		my @spec = split(/,/, lc($spec));

		my $btw_inex = 1;

		foreach ( @spec ) {
		    if ( $balres && /^($km{kosten}|$km{omzet})$/ ) {
			$btw_ko = $1 eq $km{kosten};
		    }
		    # elsif ( defined $btwmap{$_} ) {
		    # 	$btw_type = $btwmap{$_};
		    # }
		    elsif ( /^($km{tg_hoog}|$km{tg_laag}|$km{tg_nul}|prive|$km{tg_privé}|$km{tg_anders})$/ ) {
			$btw_type = substr(_xtr("scm:tg:$1"), 0, 1);
		    }
		    elsif ( /^\d+$/ ) {
			$btw_type = $_;
			warn("!".__x("Rekening {id}: gelieve BTW tariefcode {code} te vervangen door een tariefgroep",
				    id => $id,
				    code => $_)."\n")
		    }
		    elsif ( $_ eq $km{tg_geen} ) {
			$btw_type = 0;
			$kstomz = $btw_ko = undef;
		    }
		    elsif ( /^($km{incl}|$km{excl}|$km{inclusief}|$km{exclusief})?$/ ) {
			$btw_inex = $1 eq $km{incl} || $1 eq $km{inclusief};
		    }
		    else {
			error(__x("Foutieve BTW specificatie: {spec}",
				  spec => $spec)."\n");
			last;
		    }
		}

		$btw_type .= "-" unless $btw_inex;
	    }
	    elsif ( $extra =~ m/$km{koppeling}=(\S+)/i ) {
		my $t = _xtr("scm:std:$1");
		error(__x("Rekening {id}: onbekende koppeling \"{std}\"",
			  id => $id, std => $1)."\n")
		  unless exists($std{$t});
		error(__x("Rekening {id}: extra koppeling voor \"{std}\"",
			  id => $id, std => $1)."\n")
		  if $std{$t};
		$std{$t} = $id;
	    }
	}
	if ( $btw_type ne 'n' ) {
	    error(__x("Rekening {id}: BTW koppeling '{ko}' met een {acc} is niet toegestaan",
		      id => $id, ko => ($km{omzet}, $km{kosten})[$btw_ko],
		      acc => ($km{omzetrekening}, $km{kostenrekening})[$kstomz])."\n")
	      if !$balres && defined($kstomz) && defined($btw_ko) && $btw_ko != $kstomz;
	    error(__x("Rekening {id}: BTW koppeling met neutrale resultaatrekening is niet toegestaan",
		      id => $id)."\n") unless defined($kstomz) || defined($btw_ko);
	    error(__x("Rekening {id}: BTW koppeling met een balansrekening vereist kosten/omzet specificatie",
		      id => $id)."\n")
	      if $balres && !defined($btw_ko);
	}
	$desc =~ s/\s+$//;
	$kstomz = $btw_ko unless defined($kstomz);
	$acc{$id} = [ $desc, $cvdi, $balres, $debcrd, $kstomz, $btw_type, $dcfixed ];
	1;
    }
    else {
	0;
    }
}

sub scan_balans {
    unshift(@_, 1);
    goto &scan_balres;
}

sub scan_result {
    unshift(@_, 0);
    goto &scan_balres;
}

sub scan_ignore { 1 }

sub load_schema1 {
    my ($rl) = shift;

    init_vars();
    my $scanner;		# current scanner

    %std = map { $_ => 0 }
      qw(btw_ok btw_vh winst crd deb btw_il btw_vl btw_ih btw_vp btw_ip btw_va btw_ia);
    while ( $_ = $rl->() ) {
	if ( /^\# \s*
	      content-type: \s*
              text (?: \s* \/ \s* plain)? \s* ; \s*
              charset \s* = \s* (\S+) \s* $/ix ) {
	    my $charset = lc($1);
	    if ( $charset =~ /^(?:utf-?8)$/i ) {
		next;
	    }
	    error(_T("Invoer moet Unicode (UTF-8) zijn.")."\n");
	}

	my $s = "".$_;
	eval {
	    $_ = decode('utf8', $s, 1);
	};
	if ( $@ ) {
	    warn("?".__x("Geen geldige UTF-8 tekens in regel {line} van de invoer",
			 line => $.)."\n".$s."\n");
	    warn($@);
	    $fail++;
	    next;
	}

	next if /^\s*#/;
	next unless /\S/;

	# Scanner selectie.
	if ( /^($km{balans}|$km{hdr_balans})/i ) {
	    $scanner = \&scan_ignore;
	    next;
	}
	if ( /^($km{result}|$km{hdr_resultaat})/i ) {
	    $scanner = \&scan_ignore;
	    next;
	}
	if ( /^($km{dagboeken}|$km{hdr_dagboeken})/i ) {
	    $scanner = \&scan_ignore;
	    next;
	}
	if ( /^$km{hdr_btwtarieven}/i ) {
	    $scanner = \&scan_btw;
	    next;
	}

	# Overige settings.
	if ( /^$km{hdr_verdichting}\s+(\d+)\s+(\d+)/i && $1 < $2 ) {
	    next;
	}

	# Anders: Scan.
	if ( $scanner ) {
	    chomp;
	    $scanner->() or
	      error(__x("Ongeldige invoer in schema bestand, regel {lno}:\n{line}",
			line => $_, lno => $.)."\n");
	    next;
	}

	error(__x("Ongeldige invoer in schema bestand, regel {lno}:\n{line}",
		  line => $_, lno => $.)."\n");

    }

}

sub load_schema2 {
    my ($rl) = shift;

    my $scanner;		# current scanner
    $max_hvd = 9;
    $max_vrd = 99;

    while ( $_ = $rl->() ) {
	if ( /^\# \s*
	      content-type: \s*
              text (?: \s* \/ \s* plain)? \s* ; \s*
              charset \s* = \s* (\S+) \s* $/ix ) {
	    my $charset = lc($1);
	    if ( $charset =~ /^(?:utf-?8)$/i ) {
		next;
	    }
	    error(_T("Invoer moet Unicode (UTF-8) zijn.")."\n");
	}

	my $s = "".$_;
	eval {
	    $_ = decode('utf8', $s, 1);
	};
	if ( $@ ) {
	    warn("?".__x("Geen geldige UTF-8 tekens in regel {line} van de invoer",
			 line => $.)."\n".$s."\n");
	    warn($@);
	    $fail++;
	    next;
	}

	next if /^\s*#/;
	next unless /\S/;

	# Scanner selectie.
	if ( /^($km{balans}|$km{hdr_balans})/i ) {
	    $scanner = \&scan_balans;
	    next;
	}
	if ( /^($km{result}|$km{hdr_resultaat})/i ) {
	    $scanner = \&scan_result;
	    next;
	}
	if ( /^($km{dagboeken}|$km{hdr_dagboeken})/i ) {
	    $scanner = \&scan_dagboeken;
	    next;
	}
	if ( /^$km{hdr_btwtarieven}/i ) {
	    $scanner = \&scan_ignore;
	    next;
	}

	# Overige settings.
	if ( /^$km{hdr_verdichting}\s+(\d+)\s+(\d+)/i && $1 < $2 ) {
	    $max_hvd = $1;
	    $max_vrd = $2;
	    next;
	}

	# Anders: Scan.
	if ( $scanner ) {
	    chomp;
	    $scanner->() or
	      error(__x("Ongeldige invoer in schema bestand, regel {lno}:\n{line}",
			line => $_, lno => $.)."\n");
	    next;
	}

	error(__x("Ongeldige invoer in schema bestand, regel {lno}:\n{line}",
		  line => $_, lno => $.)."\n");

	# This is here for historical reasons.
	# If you weren't at the THE in 1977 this will mean nothing to you...
	# error("?"._T("Men beginne met \"Balansrekeningen\", \"Resultaatrekeningen\",".#
	#	     " \"Dagboeken\" of \"BTW Tarieven\"")."\n");
    }

    # Bekijk alle dagboeken om te zien of er inkoop/verkoop dagboeken
    # zijn die een tegenrekening nodig hebben. In dat geval moet de
    # betreffende koppeling in het schema gemaakt zijn.
    my ($need_deb, $need_crd) = (0,0);
    foreach ( @dbk ) {
	next unless defined($_); # sparse
	my ($id, $desc, $type, $dc, $rek) = @$_;
	next if defined($rek);
	if ( $type == DBKTYPE_INKOOP ) {
	    $need_crd++;
	    $_->[4] = $std{"crd"};
	    #### Verify that it's a C acct.
	}
	elsif ( $type == DBKTYPE_VERKOOP ) {
	    $need_deb++;
	    $_->[4] = $std{"deb"};
	    #### Verify that it's a D acct.
	}
	elsif ( $type != DBKTYPE_MEMORIAAL ) {
	    error(__x("Dagboek {id} heeft geen tegenrekening", id => $id)."\n");
	    $fail++;
	}
    }
    # Verwijder onnodige koppelingen.
    delete($std{crd}) unless $need_crd;
    delete($std{deb}) unless $need_deb;

    unless (defined($btwmap{p}) || defined($btwmap{"p-"}) ) {
	delete($std{"btw_ip"}) unless $std{"btw_ip"};
	delete($std{"btw_vp"}) unless $std{"btw_vp"};
    }
    unless (defined($btwmap{a}) || defined($btwmap{"a-"}) ) {
	delete($std{"btw_ia"}) unless $std{"btw_ia"};
	delete($std{"btw_va"}) unless $std{"btw_va"};
    }

    my %mapbtw = ( n => "Nul", h => "Hoog", "l" => "Laag" );
    if ( @btw ) {
	foreach ( keys(%mapbtw) ) {
	    next if defined($btwmap{$_});
	    error(__x("Geen BTW tarief gevonden met tariefgroep {gr}, inclusief",
		      gr => $mapbtw{$_})."\n");
	}
    }
    else {
	for ( qw(ih il ip ia vh vl vp va ok) ) {
	    delete($std{"btw_$_"}) unless $std{"btw_$_"};
	}
	$btwmap{n} = undef;
	$btw[0] = [ 0, "BTW Nul", BTWTARIEF_NUL, 0, 0 ];
    }
    while ( my($k,$v) = each(%std) ) {
	next if $v;
	error(__x("Geen koppeling gevonden voor \"{std}\"", std => $k)."\n");
    }

    die("?"._T("FOUTEN GEVONDEN IN SCHEMA BESTAND, VERWERKING AFGEBROKEN")."\n") if $fail;

    if ( $sql ) {
	gen_schema();
    }
    else {
	create_schema();
    }
}

sub create_schema {
    use EB::Tools::SQLEngine;
    my $engine = EB::Tools::SQLEngine->new(trace => $trace);
    $engine->callback(map { $_, __PACKAGE__->can("sql_$_") } qw(constants vrd acc std btw dbk) );
    $dbh->begin_work;
    $engine->process(sql_eekboek());
    $dbh->commit;
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

sub sql_eekboek {
    my $f = findlib("schema/eekboek.sql");
    open (my $fh, '<:encoding(utf-8)', $f)
      or die("?"._T("Installatiefout -- geen database schema")."\n");

    local $/;
    my $sql = <$fh>;
    close($fh);
    $sql;
}

sub sql_constants {
    my $out = "COPY Constants (name, value) FROM stdin;\n";

    foreach my $key ( sort(@EB::Globals::EXPORT) ) {
	no strict;
	next if ref($key->());
	$out .= "$key\t" . $key->() . "\n";
    }
    $out . "\\.\n";
}

sub sql_vrd {
    my $out = <<ESQL;
-- Hoofdverdichtingen
COPY Verdichtingen (vdi_id, vdi_desc, vdi_balres, vdi_kstomz, vdi_struct) FROM stdin;
ESQL

    for ( my $i = 0; $i < @hvdi; $i++ ) {
	next unless exists $hvdi[$i];
	my $v = $hvdi[$i];
	$out .= _tsv($i, $v->[0], _tf($v->[1]), _tfn(undef), "\\N");
    }
    $out .= "\\.\n";

    $out .= <<ESQL;

-- Verdichtingen
COPY Verdichtingen (vdi_id, vdi_desc, vdi_balres, vdi_kstomz, vdi_struct) FROM stdin;
ESQL

    for ( my $i = 0; $i < @vdi; $i++ ) {
	next unless exists $vdi[$i];
	my $v = $vdi[$i];
	$out .= _tsv($i, $v->[0], _tf($v->[1]), _tfn(undef), $v->[2]);
    }
    $out . "\\.\n";
}

sub sql_acc {
    my $out = <<ESQL;
-- Grootboekrekeningen
COPY Accounts
     (acc_id, acc_desc, acc_struct, acc_balres, acc_debcrd, acc_dcfixed,
      acc_kstomz, acc_btw, acc_ibalance, acc_balance)
     FROM stdin;
ESQL

    for my $i ( sort { $a <=> $b } keys(%acc) ) {
	my $g = $acc{$i};
	croak(__x("Geen BTW tariefgroep voor code {code}",
		  code => $g->[5]))
	  unless exists $btwmap{$g->[5]}
	    || exists $btwmap{$g->[5]."-"};
	$out .= _tsv($i, $g->[0], $g->[1],
		     _tf($g->[2]),
		     _tf($g->[3]),
		     _tfn($g->[2] ? $g->[6] : undef),
		     _tfn($g->[4]),
		     defined($btwmap{$g->[5]}) ? $btwmap{$g->[5]} : "\\N",
		     0, 0);
    }
    $out . "\\.\n";
}

sub sql_std {
    my $out = <<ESQL;
-- Standaardrekeningen
INSERT INTO Standaardrekeningen
ESQL
    $out .= "  (" . join(", ", map { "std_acc_$_" } keys(%std)) . ")\n";
    $out .= "  VALUES (" . join(", ", values(%std)) . ");\n";

    $out;
}

sub sql_btw {
    my $out = <<ESQL;
-- BTW Tarieven
COPY BTWTabel (btw_id, btw_alias, btw_desc, btw_tariefgroep, btw_perc, btw_incl, btw_start, btw_end) FROM stdin;
ESQL

    foreach ( @btw ) {
	next unless defined;
	$_->[1] = "\\N" unless defined($_->[1]);
	$_->[6] = "\\N" unless defined($_->[6]);
	$_->[7] = "\\N" unless defined($_->[7]);
	if ( $_->[3] == BTWTARIEF_NUL ) {
	    $_->[4] = 0;
	    $_->[5] = "\\N";
	}
	else {
	    $_->[5] = _tf($_->[5]);
	}
	$out .= _tsv(@$_);
    }
    $out . "\\.\n";
}

sub sql_dbk {
    my $out = <<ESQL;
-- Dagboeken
COPY Dagboeken (dbk_id, dbk_desc, dbk_type, dbk_dcsplit, dbk_acc_id) FROM stdin;
ESQL

    foreach ( @dbk ) {
	next unless defined;
	$_->[4] ||= $std{deb} if $_->[2] == DBKTYPE_VERKOOP;
	$_->[4] ||= $std{crd} if $_->[2] == DBKTYPE_INKOOP;
	$out .= join("\t",
		     map { defined($_) ? $_ : "\\N" } @$_).
		       "\n";
    }
    $out .= "\\.\n";

    $out .= "\n-- Sequences for Boekstuknummers, one for each Dagboek\n";
    foreach ( @dbk ) {
	next unless defined;
	$out .= "CREATE SEQUENCE bsk_nr_$_->[0]_seq;\n";
    }
    $out;
}

use Encode;
sub gen_schema {
    foreach ( qw(eekboek vrd acc dbk btw std) ) {
	warn('%'.__x("Aanmaken {sql}...",
		     sql => "$_.sql")."\n");

	# Careful. Data is utf8.
	open(my $f, ">:encoding(utf-8)", "$_.sql")
	  or die("Cannot create $_.sql: $!\n");
	my $cmd = "sql_$_";
	no strict 'refs';
	print $f decode_utf8($cmd->());
	close($f);
    }
}

sub _tf {
    qw(f t)[shift];
}

sub _tfn {
    defined($_[0]) ? qw(f t)[$_[0]] : "\\N";
}

################ Subroutines ################

sub dump_sql {
    my ($self, $schema) = @_;
    local($sql) = 1;
    create(undef, $schema);
}

my %kopp;
my $fh;

sub dump_schema {
    my ($self, $fh) = @_;
    $fh ||= *STDOUT;

    # Only generate comments when translated.
    my $preamble = <<EOD;

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

EOD
    my $comment = $preamble ne ( $preamble = _T($preamble) );

    $dbh = EB::DB->new(trace => $trace);
    $dbh->connectdb;		# can't wait...
    init_kmap();

    my @t = localtime(time);
    print {$fh} ( "# ",
		  __x( "{pkg} Rekeningschema voor {db}",
		       pkg => $EekBoek::PACKAGE,
		       db => $dbh->dbh->{Name} ),
		  "\n",
		  "# ",
		  __x( "Aangemaakt door {pkg} {version} op {ts}",
		       pkg => $EekBoek::PACKAGE,
		       version => $EekBoek::VERSION,
		       ts => sprintf( "%02d-%02d-%04d %02d:%02d:%02d",
				      $t[3], 1+$t[4], 1900+$t[5], @t[2,1,0] ),
		     ),
		  "\n",
		  "# Content-Type: text/plain; charset = UTF-8\n" );

    print {$fh} $preamble if $comment;

    my $sth = $dbh->sql_exec("SELECT * FROM Standaardrekeningen");
    my $rr = $sth->fetchrow_hashref;
    $sth->finish;
    while ( my($k,$v) = each(%$rr) ) {
	next unless defined $v;
	$k =~ s/^std_acc_//;
	$kopp{$v} = $k;
    }

print {$fh}  <<EOD if $comment;
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
# informatie. Voor grootboekrekeningen kan op deze wijze de BTW
# tariefstelling worden aangegeven die op deze rekening van toepassing
# is:
#
#   :btw=nul
#   :btw=hoog
#   :btw=laag
#   :btw=privé
#   :btw=anders
#
# Ook is het mogelijk aan te geven dat een rekening een koppeling
# (speciale betekenis) heeft met :koppeling=xxx. De volgende koppelingen
# zijn mogelijk:
#
#   crd		de standaard tegenrekening (Crediteuren) voor inkoopboekingen
#   deb		de standaard tegenrekening (Debiteuren) voor verkoopboekingen
#   btw_ih	de rekening voor BTW boekingen voor inkopen, hoog tarief
#   btw_il	idem, laag tarief
#   btw_vh	idem, verkopen, hoog tarief
#   btw_vl	idem, laag tarief
#   btw_ph	idem, privé, hoog tarief
#   btw_pl	idem, laag tarief
#   btw_ah	idem, anders, hoog tarief
#   btw_al	idem, laag tarief
#   btw_ok	rekening voor de betaalde BTW
#   winst	rekening waarop de winst wordt geboekt
#
# De koppeling winst is verplicht en moet altijd in een administratie
# voorkomen in verband met de jaarafsluiting.
# De koppelingen voor BTW moeten worden opgegeven indien BTW
# van toepassing is op de administratie.
# De koppelingen voor Crediteuren en Debiteuren moeten worden
# opgegeven indien er inkoop dan wel verkoopdagboeken zijn die gebruik
# maken van de standaardwaarden (dus zelf geen tegenrekening hebben
# opgegeven).
EOD

$max_hvd = $dbh->do("SELECT MAX(vdi_id) FROM Verdichtingen WHERE vdi_struct IS NULL")->[0];
$max_vrd = $dbh->do("SELECT MAX(vdi_id) FROM Verdichtingen WHERE NOT vdi_struct IS NULL")->[0];

    print {$fh}  <<EOD if $comment;

# Normaal lopen hoofdverdichtingen van 1 t/m 9, en verdichtingen
# van 10 t/m 99. Indien daarvan wordt afgeweken kan dit worden opgegeven
# met de opdracht "Verdichting". De twee getallen geven het hoogste
# nummer voor hoofdverdichtingen resp. verdichtingen.
EOD

    printf {$fh} ( "\n$km{hdr_verdichting} %d %d\n\n",
		   ( $max_hvd > 9 || $max_vrd > 99 )
		  ? ( $max_hvd, $max_vrd )
		  : ( 9, 99 ) );

    print {$fh}  <<EOD if $comment;
# De nummers van de grootboekrekeningen worden geacht groter te zijn
# dan de maximale verdichting. Daarvan kan worden afgeweken door
# middels voorloopnullen de _lengte_ van het nummer groter te maken
# dan de lengte van de maximale verdichting. Als bijvoorbeeld 99 de
# maximale verdichting is, dan geeft 001 een grootboekrekening met
# nummer 1 aan.
EOD

    dump_acc(1, $fh);		# Balansrekeningen
    dump_acc(0, $fh);		# Resultaatrekeningen

print {$fh}  <<EOD if $comment;

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
EOD

    dump_dbk($fh);			# Dagboeken

    if ( $dbh->does_btw ) {
	print {$fh}  <<EOD if $comment;

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
EOD

	dump_btw($fh);			# BTW tarieven
    }

    print {$fh} ( "\n",
		  "# ", __x( "Einde {pkg} schema",
			     pkg => $EekBoek::PACKAGE ), "\n" );
}

sub dump_acc {
    my ($balres, $fh) = @_;

    print {$fh} ("\n", $balres ? $km{hdr_balans} : $km{hdr_resultaat}, "\n");

    my $sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc".
			     " FROM Verdichtingen".
			     " WHERE ".($balres?"":"NOT ")."vdi_balres".
			     " AND vdi_struct IS NULL".
			     " ORDER BY vdi_id");
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($id, $desc) = @$rr;
	printf {$fh} ("\n  %d  %s\n", $id, $desc);
	print {$fh} ("# ".__x("HOOFDVERDICHTING MOET TUSSEN {min} EN {max} (INCL.) LIGGEN",
		       min => 1, max => $max_hvd)."\n")
	  if $id > $max_hvd;
	my $sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc".
				 " FROM Verdichtingen".
				 " WHERE vdi_struct = ?".
				 " ORDER BY vdi_id", $id);
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($id, $desc) = @$rr;
	    printf {$fh} ("     %-2d  %s\n", $id, $desc);
	    print {$fh} ("# ".__x("VERDICHTING MOET TUSSEN {min} EN {max} (INCL.) LIGGEN",
			   min => $max_hvd+1, max => $max_vrd)."\n")
	      if $id <= $max_hvd || $id > $max_vrd;
	    my $sth = $dbh->sql_exec("SELECT acc_id, acc_desc, acc_balres,".
				     " acc_debcrd, acc_dcfixed, acc_kstomz,".
				     " acc_btw, btw_tariefgroep, btw_incl".
				     " FROM Accounts, BTWTabel ".
				     " WHERE acc_struct = ?".
				     " AND (btw_id = acc_btw".
				     " OR btw_id = 0 AND acc_btw IS NULL)".
				     " ORDER BY acc_id", $id);
	    while ( my $rr = $sth->fetchrow_arrayref ) {
		my ($id, $desc, $acc_balres, $acc_debcrd, $acc_dcfixed, $acc_kstomz, $btw_id, $btw, $btwincl) = @$rr;
		my $flags = "";
		if ( $balres ) {
		    $flags .= $acc_debcrd ? "D" : "C";
		    $flags .= '!' if $acc_dcfixed;
		}
		else {
		    $flags .= defined($acc_kstomz)
		      ? ($acc_kstomz ? "K" : "O")
			: "N";
		}
		my $extra = "";
		if ( $btw == BTWTARIEF_HOOG ) {
		    $extra .= " :$km{btw}=$km{tg_hoog}";
		    $extra .= ",$km{excl}" unless $btwincl;
		    if ( $balres ) {
			$extra .= ",$km{kosten}" if $acc_kstomz;
			$extra .= ",$km{omzet}"  if !$acc_kstomz;
		    }
		}
		elsif ( $btw == BTWTARIEF_LAAG ) {
		    $extra .= " :$km{btw}=$km{tg_laag}";
		    $extra .= ",$km{excl}" unless $btwincl;
		    if ( $balres ) {
			$extra .= ",$km{kosten}" if $acc_kstomz;
			$extra .= ",$km{omzet}"  if !$acc_kstomz;
		    }
		}
		elsif ( $btw == BTWTARIEF_PRIV ) {
		    $extra .= " :$km{btw}=$km{tg_privé}";
		    $extra .= ",$km{excl}" unless $btwincl;
		    if ( $balres ) {
			$extra .= ",$km{kosten}" if $acc_kstomz;
			$extra .= ",$km{omzet}"  if !$acc_kstomz;
		    }
		}
		elsif ( $btw == BTWTARIEF_ANDERS ) {
		    $extra .= " :$km{btw}=$km{tg_anders}";
		    $extra .= ",$km{excl}" unless $btwincl;
		    if ( $balres ) {
			$extra .= ",$km{kosten}" if $acc_kstomz;
			$extra .= ",$km{omzet}"  if !$acc_kstomz;
		    }
		}
		elsif ( $btw != BTWTARIEF_NUL ) {
		    $extra .= " :$km{btw}=$btw_id";
		}
		else {
		    if ( $balres && defined($acc_kstomz) ) {
			$extra .= " :$km{btw}=$km{kosten}" if $acc_kstomz;
			$extra .= " :$km{btw}=$km{omzet}"  if !$acc_kstomz;
		    }
		}
		$extra .= " :$km{koppeling}=".$km{$kopp{$id}} if exists($kopp{$id});
		$desc =~ s/^\s+//;
		$desc =~ s/\s+$//;
		my $t = sprintf("         %-4s  %-2s  %-40.40s  %s",
				$id < $max_vrd ? (("0" x (length($max_vrd)-length($id)+1)) . $id) : $id,
				$flags, $desc, $extra);
		$t =~ s/\s+$//;
		print {$fh} ($t, "\n");
		print {$fh} ("# ".__x("{id} ZOU EEN BALANSREKENING MOETEN ZIJN", id => $id)."\n")
		  if $acc_balres && !$balres;
		print {$fh} ("# ".__x("{id} ZOU EEN RESULTAATREKENING MOETEN ZIJN", id => $id)."\n")
		  if !$acc_balres && $balres;
	    }
	}
    }
}

sub dump_btw {
    my $fh = shift;
    print {$fh} ("\n$km{hdr_btwtarieven}\n\n");
    my $sth = $dbh->sql_exec("SELECT btw_id, btw_alias, btw_desc, btw_perc, btw_tariefgroep,".
			     "btw_incl, btw_start, btw_end".
			     " FROM BTWTabel".
			     " ORDER BY btw_id");
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($id, $alias, $desc, $perc, $btg, $incl, $start, $end) = @$rr;
	my $extra = "";
	$extra .= " :$km{tariefgroep}=" . $km{"tg_".lc(BTWTARIEVEN->[$btg])};
	if ( $btg != BTWTARIEF_NUL ) {
	    $extra .= " :$km{perc}=".btwfmt($perc);
	    $extra .= " :$km{exclusief}" unless $incl;
	}
	$extra .= " :$km{vanaf}=$start" if $start;
	$extra .= " :$km{tot}=".parse_date($end, undef, 1) if $end;
	if ( $id >= BTW_CODE_AUTO ) {
	    next unless $alias;
	    $alias = sprintf("%-10s", $alias);
	}
	else {
	    $alias = sprintf("%3d", $id);
	}
	my $t = sprintf("  %s  %-20s  %s",
			$alias, $desc, $extra);
	$t =~ s/\s+$//;
	print {$fh} ($t, "\n");
    }
}

sub dump_dbk {
    my $fh = shift;
    print {$fh} ("\n$km{hdr_dagboeken}\n\n");
    my $sth = $dbh->sql_exec("SELECT dbk_id, dbk_desc, dbk_type, dbk_dcsplit, dbk_acc_id".
			     " FROM Dagboeken".
			     " ORDER BY dbk_id");
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($id, $desc, $type, $dc, $acc_id) = @$rr;
	$acc_id = 0 if $type == DBKTYPE_INKOOP  && $dbh->std_acc("crd", 0) == $acc_id;
	$acc_id = 0 if $type == DBKTYPE_VERKOOP && $dbh->std_acc("deb", 0) == $acc_id;
	my $t = sprintf("  %-4s  %-20s  :type=%-10s %s",
			$id, $desc, _xt("scm:dbk:".lc(DBKTYPES->[$type])),
			($acc_id ? ":$km{rekening}=$acc_id" : "").
			($dc ? " :dc" : ""),
		       );
	$t =~ s/\s+$//;
	print {$fh} ($t, "\n");
    }
}

################ API functions ################

sub new {
    bless \my $x, shift;
}

sub add_gbk {
    my ($self, @args) = @_;

    my $opts = pop(@args);	# currently unused
    my $in_transaction;
    my $anyfail;
    my $ret = "";

    while ( @args ) {
	my ($gbk, $flags, $desc, $vrd) = splice( @args, 0, 4 );
	if ( defined($flags) and defined($desc) and defined($vrd) ) {
	    my ( $balres, $debcrd, $kstomz, $fixed );
	    ( $flags, $fixed ) = ( $1, !!$2 ) if $flags =~ /^(.)(!)$/;
	    $flags = lc($flags);

	    my $t = $dbh->lookup($gbk, qw(Accounts acc_id acc_desc));
	    if ( $t ) {
		warn "?".
		  __x("Grootboekrekening {gbk} ({desc}) bestaat reeds",
		      gbk => $gbk, desc => $t)."\n";
		$anyfail++;
		next;
	    }
	    $balres = $dbh->lookup($vrd, qw(Verdichtingen vdi_id vdi_balres));
	    unless ( defined $balres ) {
		warn "?".__x("Onbekende verdichting: {vrd}",
			     vrd => $vrd)."\n";
		$anyfail++;
		next;
	    }
	    if ( $balres ) {
		if ( $flags =~ /^[dc]$/ ) {
		    $debcrd = $flags eq 'd';
		}
		else {
		    warn "?"._T("Ongeldig type voor balansrekening (alleen D / C toegestaan)")."\n";
		    $anyfail++;
		    next;
		}
	    }
	    else {
		if ( $flags =~ /^[kon]$/ ) {
		    $kstomz = $flags eq 'k' ? 1 : $flags eq 'o' ? 0 : undef;
		}
		else {
		    warn "?"._T("Ongeldig type voor resultaatrekening (alleen K / O / N toegestaan)")."\n";
		    $anyfail++;
		    next;
		}
	    }
	    $dbh->begin_work unless $in_transaction++;
	    $t = $dbh->sql_insert("Accounts",
				  [qw(acc_id acc_desc acc_struct acc_balres
				      acc_debcrd acc_dcfixed acc_kstomz
				      acc_btw acc_ibalance acc_balance)],
				  $gbk, $desc, $vrd,
				  $balres,
				  $debcrd,
				  $fixed,
				  $kstomz,
				  undef, 0, 0);
	    unless ( $t ) {
		warn "?".__x("Fout tijdens het opslaan van grootboekrekening {gbk}",
			     gbk => $gbk)."\n";
		$anyfail++;
		next;
	    }
	}

	unless ( $anyfail ) {
	    my $rr = $dbh->do("SELECT acc_desc, acc_balres, acc_debcrd,".
			      "       acc_kstomz, acc_dcfixed, vdi_id, vdi_desc, vdi_struct".
			      " FROM Accounts, Verdichtingen".
			      " WHERE acc_id = ?".
			      " AND acc_struct = vdi_id", $gbk);
	    unless ( $rr ) {
		warn "!".__x("Onbekende grootboekrekening: {gbk}",
			     gbk => $gbk)."\n";
		#$anyfail++;
		next;
	    }

	    my $t = $dbh->lookup($rr->[7], qw(Verdichtingen vdi_id vdi_desc));
	    $ret .=
	      __x("{balres} {gbk} {debcrd}{fixed}{kstomz} ({desc});".
		  " Verdichting {vrd} ({vdesc});".
		  " Hoofdverdichting {hvrd} ({hdesc})",
		  balres => ($rr->[1] ? "Balansrekening" : "Resultaatrekening"),
		  gbk => $gbk, desc => $rr->[0],
		  debcrd => ($rr->[1] ? ($rr->[2] ? "Debet" : "Credit") : ""),
		  kstomz => ($rr->[1] ? "" : defined($rr->[3]) ? $rr->[3] ? " Kosten" : " Omzet" : " Neutraal"),
		  fixed => $rr->[4] ? "!" : "",
		  vrd => $rr->[5], vdesc => $rr->[6],
		  hvrd => $rr->[7], hdesc => $t,
		 )."\n";
	}
    }

    if ( $in_transaction ) {
	$anyfail ? $dbh->rollback : $dbh->commit;
    }
    return $ret;
}

1;
