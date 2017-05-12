#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Tue Jul 19 19:01:33 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Mar  8 15:32:24 2012
# Update Count    : 648
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;
our $dbh;

package EB::Report::BTWAangifte;

use strict;
use warnings;

use EB;
use EB::Format;
use EB::Booking;		# for norm_btw()

use POSIX qw(floor ceil);

my $trace = $cfg->val(__PACKAGE__, "trace", undef);
my $noround;

my @periodetabel;

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    bless $self, $class;
    $self->{"adm_$_"} = $dbh->adm($_)
      for qw(begin btwperiod);
    $self->{adm_btwperiod} ||= 1;

    unless ( $self->{adm_begin} ) {
	die("?"._T("De administratie is nog niet geopend")."\n");
    }

    $self;
}

sub periodetabel {
    my ($self) = (@_);

    unless ( @periodetabel ) {
	@periodetabel = ( [] ) x 13;
	my @m;
	for ( 1 .. 12 ) {
	    push(@m, [ sprintf("%02d-01", $_),
		       sprintf("%02d-%02d", $_, ($_ & 1 xor $_ & 8) ? 31 : 30) ]);
	}
	$m[1][1] = substr($self->{adm_begin}, 0, 4) % 4 ? "02-28" : "02-29";
	$periodetabel[12] = [ _T("per maand"), @m ];
	$periodetabel[1]  = [ _T("per jaar"), [$m[0][0], $m[11][1] ]];
	$periodetabel[4]  = [ _T("per kwartaal"),
			      [$m[0][0], $m[2][1]], [$m[3][0], $m[5][1] ],
			      [$m[6][0], $m[8][1]], [$m[9][0], $m[11][1]]];
    }

    \@periodetabel;
}

use EB::Report::GenBase;

sub perform {
    my ($self, $opts) = @_;

    $noround = $opts->{noround} || 0;

    # Determine the period to be used.

    # BTW report is slightly awkward. It takes the boekjaar into
    # account, also an explicitly specified period. But it can also
    # process a form of symbolic period, like "k1" or "m4".

    # Order of precedence:
    # 1. --period,
    # 2. symbolic period, depending on boekjaar,
    # 3. (default) next (or first) period in boekjaar.

    # Note that a possible --period / symbolic period conflict has
    # already been trapped in the shell.

    my $year = substr($dbh->adm("begin"), 0, 4); # default for now
    my $btwperiod = $self->{adm_btwperiod};

    # Check symbolic period (excludes --period).
    if ( $opts->{compat_periode} ) {
	# Adjust current year, if applicable.
	if ( defined($opts->{boekjaar}) || defined($opts->{d_boekjaar}) ) {
	    my $bky = $opts->{boekjaar};
	    $bky = $opts->{d_boekjaar} unless defined $bky;
	    my $rr = $dbh->do("SELECT bky_begin".
			      " FROM Boekjaren".
			      " WHERE bky_code = ?", $bky);
	    die("?",__x("Onbekend boekjaar: {bky}", bky => $bky)."\n"), return unless $rr;
	    $year = substr($rr->[0], 0, 4);
	}

	# Parse the symbolic period.
	$self->parse_periode($opts->{compat_periode}, $year);

	# Store in --period.
	$opts->{periode} = [ $self->{p_start}, $self->{p_end} ];

	# GenBase backend will disallow --period with boekjaar...
	delete($opts->{boekjaar});
    }

    # No symbolic. So we have either a --period, or nothing.
    # The latter includes a possible --boekjaar ;-).
    elsif ( !defined($opts->{periode}) ) {
	# We have nothing. Adjust year to --boekjaar if applicable.
	if ( defined($opts->{boekjaar}) || defined($opts->{d_boekjaar}) ) {
	    my $bky = $opts->{boekjaar};
	    $bky = $opts->{d_boekjaar} unless defined $bky;
	    my $rr = $dbh->do("SELECT bky_begin".
			      " FROM Boekjaren".
			      " WHERE bky_code = ?", $bky);
	    die("?",__x("Onbekend boekjaar: {bky}", bky => $bky)."\n"), return unless $rr;
	    $year = substr($rr->[0], 0, 4);
	}
	my $tbl = $self->periodetabel->[$btwperiod];

	if ( $btwperiod == 1 ) { # aangifteperiode => jaar
	    $opts->{periode} = [ $year . "-" . $tbl->[1]->[0],
				 $year . "-" . $tbl->[1]->[1] ];
	    $self->{compat_periode} = $self->periode(1, $year);
	}
	elsif ( 0 ) {		# determine period depending on current date.
	    my @tm = localtime(time);
	    $tm[5] += 1900;
	    my $m;
	    if ( $year < 1900+$tm[5] ) {
		$m = $btwperiod;
	    }
	    else {
		$m = 1 + int($tm[4] / (12/$btwperiod));
	    }
	    $opts->{periode} = [ $year . "-" . $tbl->[$m]->[0],
				 $year . "-" . $tbl->[$m]->[1] ];
	    $self->{compat_periode} = $self->periode($btwperiod, $year, $m);
	}
	else {			# determine period depending on previous aangifte
	    my $next = $dbh->adm("btwbegin");
	    my $m;
	    if ( substr($next, 0, 4) gt $year ) {
		$m = $btwperiod;
	    }
	    elsif ( substr($next, 0, 4) lt $year ) {
		$m = 1;
	    }
	    else {
		for ( $m = 1; $m <= 12; $m++ ) {
		    last if substr($next, 5) eq $tbl->[$m]->[0];
		}
	    }
	    $opts->{periode} = [ $year . "-" . $tbl->[$m]->[0],
				 $year . "-" . $tbl->[$m]->[1] ];
	    $self->{compat_periode} = $self->periode($btwperiod, $year, $m);
	}
	delete($opts->{boekjaar});
    }
    # else: we have an explicit --period. Nothing here to do.
    else {
	$self->{compat_periode} = "";
    }

    $opts->{STYLE} = "btwaangifte";

    # my $w = $amount_width + 1;
    # $self->{fh}->printf("%-5s%-40s%${w}s%${w}s\n",

    $opts->{LAYOUT} =
      [ { name   => "_colsep",	# neat? or trick?
	  #sep => "|",
	  width  => 1 },
        { name	 => "num",
	  width	 => 4 },
	{ name	 => "desc",
	  width	 => 40 },
	{ name	 => "col1",
	  width	 => $amount_width,
	  align	 => ">" },
	{ name	 => "col2",
	  width	 => $amount_width,
	  align	 => ">" },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);

    unless ( $rep->{per_begin} eq $dbh->adm("btwbegin") ) {
	my $msg = _T("BTW aangifte periode sluit niet aan bij de vorige aangifte");
	$opts->{close} ? die("?$msg\n") : warn("!$msg\n");
    }

    unless ( $opts->{noreport} ) {
	my $data = $self->collect($rep->{per_begin}, $rep->{per_end});
	$self->report($rep, $data);
    }

    if ( $opts->{close} ) {
	$dbh->adm("btwbegin", scalar parse_date($rep->{per_end}, undef, 1));	# implied commit
    }
}

sub periode {
    my ($self, $p, $year, $v) = @_;
    if ( $p == 1 ) {
	return __x("{year}", year => $year);
    }
    elsif ( $p == 4 ) {
	return __x("{quarter} {year}",
		   quarter => (_T("1e kwartaal"), _T("2e kwartaal"),
			       _T("3e kwartaal"), _T("4e kwartaal"))[$v-1],
		   year => $year);
    }
    elsif ( $p == 12 ) {
	return __x("{month} {year}",
		   month => _T( $EB::Utils::month_names[$v-1] ),
		   year => $year);
    }
    else {
	die("?".__x("Programmafout: Ongeldige BTW periode: {per}", per => $p)."\n");
    }
}

sub parse_periode {
    my ($self, $v, $year) = @_;

    my $pp = sub {
	my ($per, $n) = @_;
	unless ( $self->{adm_btwperiod} == $per ) {
	    warn($self->{close} ? "?" :"!".
		 __x("Aangifte {per} komt niet overeen met de BTW instelling".
		     " van de administratie ({admper})",
		     per => $self->periodetabel->[$per][0],
		     admper => $self->periodetabel->[$self->{adm_btwperiod}][0],
		    )."\n")
	}
	$self->{adm_btwperiod} = $per;
	my $tbl = $self->periodetabel->[$self->{adm_btwperiod}];
	$self->{p_start} = $year . "-" . $tbl->[$n]->[0];
	$self->{p_end}   = $year . "-" . $tbl->[$n]->[1];
	$self->{compat_periode} = $self->periode($per, $year, $n);
	if ( $per == $n ) {
	    $self->{p_next}  = ($year+1) . "-" . $tbl->[1]->[0];
	}
	else {
	    $self->{p_next}  = $year . "-" . $tbl->[$n+1]->[0];
	}
    };

    my $yrpat = _T("j(aar)?");
    if ( $v =~ /^$yrpat$|j(aar)?$/i ) {
	$pp->(1, 1);
	return;
    }
    if ( $v =~ /^[kq](\d)$/i && $1 >= 1 && $1 <= 4) {
	$pp->(4, $1);
	return;
    }
    if ( $v =~ /^(\d+)$/i  && $1 >= 1 && $1 <= 12) {
	$pp->(12, $1);
	return;
    }
    if ( $v =~ /^(\w+)$/i ) {
	my $i;
	for ( $i = 0; $i < 12; $i++ ) {
	    last if lc($EB::Utils::month_names[$i]) eq lc($v);
	    last if lc($EB::Utils::months[$i]) eq lc($v);
	}
	if ( $i < 12 ) {
	    $pp->(12, $i+1);
	    return;
	}
    }
    die("?".__x("Ongeldige waarde voor BTW periode: \"{per}\"",
		per => $v) . "\n");
}

sub collect {
    my ($self, $begin, $end) = @_;

    my $v;

    my $tot = 0;

    # 1. Door mij verrichte leveringen/diensten
    # 1a. Belast met hoog tarief

    my $deb_h = 0;
    my $deb_btw_h = 0;

    # 1b. Belast met laag tarief

    my $deb_l = 0;
    my $deb_btw_l = 0;

    # 1c. Belast met ander, niet-nul tarief

    my $deb_a = 0;
    my $deb_btw_a = 0;

    # 1d. Eigen gebruik.

    my $deb_p = 0;
    my $deb_btw_p = 0;

    # 1e. Belast met 0%/verlegd

    my $deb_0 = 0;
    my $verlegd = 0;

    # 3. Door mij verrichte leveringen
    # 3a. Buiten de EU

    my $extra_deb = 0;

    # 3b. Binnen de EU

    my $intra_deb = 0;
    my $intra_deb_btw = 0;

    # 4. Aan mij verrichte leveringen
    # 4a. Van buiten de EU

    my $extra_crd = 0;

    # 4b. Verwervingen van goederen uit de EU.

    my $intra_crd = 0;
    my $intra_crd_btw = 0;

    # Totaaltellingen.

    my $crd_btw = 0;		# BTW betaald (voorheffingen)
    my $xx = 0;			# ongeclassificeerd (fout, dus)

    # Target: alle boekstukken van type 0 (inkoop/verkoop).
    my $sth = $dbh->sql_exec
      ("SELECT bsr_amount,bsr_acc_id,bsr_btw_id,bsr_btw_acc,bsr_btw_class,rel_debcrd,rel_btw_status".
       " FROM Boekstukregels, Relaties".
       " WHERE bsr_rel_code = rel_code AND bsr_dbk_id = rel_ledger".
       " AND bsr_date >= ? AND bsr_date <= ?".
       " AND bsr_type = 0".
       " UNION ALL ".
       "SELECT bsr_amount,bsr_acc_id,bsr_btw_id,bsr_btw_acc,bsr_btw_class,null as rel_debcrd,0 as rel_btw_status".
       " FROM Boekstukregels".
       " WHERE bsr_rel_code IS NULL".
       " AND bsr_date >= ? AND bsr_date <= ?".
       " AND bsr_type = 0",
       $begin, $end, $begin, $end);

    my $rr;

    my $tr = $trace ? sub {
	warn("BTW " . shift() . " " . join(" ", map { defined $_ ? $_ : "-" } @$rr). "\n");
    } : sub {};

    while ( $rr = $sth->fetchrow_arrayref ) {
	my ($amt, $acc, $btw_id, $btw_acc, $btwclass, $debcrd, $btw_status) = @$rr;

	next unless $btwclass & BTWKLASSE_BTW_BIT;

	my $btg_id = 0;
	my $btw = 0;
	$amt = -$amt;
	if ( $btw_id && $btw_acc ) {
	    # Bepaal tariefgroep en splits bedrag uit.
	    $btg_id = $dbh->lookup($btw_id, qw(BTWTabel btw_id btw_tariefgroep));
	    my $a = EB::Booking::->norm_btw($amt, $btw_id);
	    $amt = $a->[0] - ($btw = $a->[1]); # ex BTW
	}

	unless ( defined $debcrd ) {
	    $debcrd = !($btwclass & BTWKLASSE_KO_BIT);
	}
	if ( $btw_status == BTWTYPE_NORMAAL ) {
	    if ( $debcrd ) {
		if ( $btg_id == BTWTARIEF_HOOG ) {
		    $tr->("Hoog");
		    $deb_h += $amt;
		    $deb_btw_h += $btw;
		}
		elsif ( $btg_id == BTWTARIEF_LAAG ) {
		    $tr->("Laag");
		    $deb_l += $amt;
		    $deb_btw_l += $btw;
		}
		elsif ( $btg_id == BTWTARIEF_NUL ) {
		    $tr->("0%");
		    $deb_0 += $amt;
		}
		elsif ( $btg_id == BTWTARIEF_PRIV ) {
		    $tr->("Privé");
		    $deb_p += $amt;
		    $deb_btw_p += $btw;
		}
		else {
		    assert($btg_id == BTWTARIEF_ANDERS);
		    $tr->("Ander");
		    $deb_a += $amt;
		    $deb_btw_a += $btw;
		}
	    }
	    else {
		$tr->("Voorheffing");
		$crd_btw -= $btw;
	    }
	}
	elsif ( $btw_status == BTWTYPE_VERLEGD ) {
	    if ( $debcrd ) {
		$tr->("Verlegd");
		$verlegd += $amt;
	    }
	}
	elsif ( $btw_status == BTWTYPE_INTRA ) {
	    if ( $debcrd ) {
		$tr->("Intra");
		$intra_deb += $amt;
		$intra_deb_btw += $btw;
	    }
	    else {
		$intra_crd -= $amt;
		$intra_crd_btw -= $btw;
	    }
	}
	elsif ( $btw_status == BTWTYPE_EXTRA ) {
	    if ( $debcrd ) {
		$tr->("Extra D");
		$extra_deb += $amt;
	    }
	    else {
		$tr->("Extra C");
		$extra_crd -= $amt;
	    }
	}
	else {
	    # Foutvanger.
	    $tr->("????");
	    $xx += $amt;
	}
    }

    my %data;
    my $delta = 0;

    my $ad = sub {
	my ($a, $b) = @_;
	$b *= AMTSCALE unless $noround;
	$delta += $a - $b;
    };

    # 1. Door mij verrichte leveringen/diensten
    # 1a. Belast met hoog tarief
    $v = rounddown($deb_btw_h);
    $data{deb_btw_h} = $v;
    $ad->($deb_btw_h, $v);
    $data{deb_h} = rounddown($deb_h);
    $tot += $v;

    # 1b. Belast met laag tarief
    $v = rounddown($deb_btw_l);
    $data{deb_l} = rounddown($deb_l);
    $data{deb_btw_l} = $v;
    $ad->($deb_btw_l, $v);
    $tot += $v;

    # 1c. Belast met ander, niet-nul tarief
    $v = rounddown($deb_btw_a);
    $data{deb_a} = rounddown($deb_a);
    $data{deb_btw_a} = $v;
    $ad->($deb_btw_a, $v);
    $tot += $v;

    # 1d. Eigen gebruik
    $v = rounddown($deb_btw_p);
    $data{deb_p} = rounddown($deb_p);
    $data{deb_btw_p} = $v;
    $ad->($deb_btw_p, $v);
    $tot += $v;

    # 1e. Belast met 0%/verlegd
    $data{deb_0} = rounddown($deb_0 + $verlegd);
    #$data{deb_0} = roundtozero($deb_0 + $verlegd);

    # Buitenland
    # 3. Door mij verrichte leveringen
    # 3a. Buiten de EU
    $data{extra_deb} = rounddown($extra_deb);

    # 3b. Binnen de EU
    $data{intra_deb} = rounddown($intra_deb);
    $v = rounddown($intra_deb_btw);
    $data{intra_deb_btw} = $v; # TODO
    $ad->($intra_deb_btw, $v);

    # 4. Aan mij verrichte leveringen
    # 4a. Van buiten de EU
    $data{extra_crd} = rounddown($extra_crd);

    # 4b. Verwervingen van goederen uit de EU.
    $data{intra_crd} = rounddown($intra_crd);
    $v = roundup($intra_crd_btw);
    $data{intra_crd_btw} = $v;
    $ad->($intra_crd_btw, $v);
    $tot += $v;

    # 5 Berekening totaal
    # 5a. Subtotaal
    $data{sub0} = $tot;

    # 5b. Voorbelasting
    my ($vb) = @{$dbh->do("SELECT SUM(jnl_amount)".
			  " FROM Journal".
			  " WHERE ( jnl_acc_id = ? OR jnl_acc_id = ?".
			  "         OR jnl_acc_id = ? OR jnl_acc_id = ? )".
			  " AND jnl_bsr_date >= ? AND jnl_bsr_date <= ?",
			  $dbh->std_acc("btw_ih"), $dbh->std_acc("btw_il"),
			  $dbh->std_acc("btw_ia",0), $dbh->std_acc("btw_ip",0),
			  $begin, $end)};
    $vb ||= 0;	# prevent warnings
    my $btw_i_delta = $vb - $crd_btw - $intra_crd_btw;
    $v = roundup($vb);
    $data{vb} = $v;
    $tot -= $v;
    $ad->(-$vb, -$v);

    # 5c Subtotaal / 5g Totaal
    $data{sub1} = $data{tot} = $tot;
    $data{onbekend} = $xx if $xx;

    # 5d Kleine Ondernemers
    if ( $self->{compat_periode} =~ /^\d\d\d\d$/ ) { # aangifte per jaar
	if ( $data{ko} = kleine_ondernemers($self->{compat_periode}, $data{sub1}) ) {
	    $data{tot} -= $data{ko};
	}
    }

    # Check op afgedragen BTW.

    foreach my $acc ( @{$dbh->std_accs} ) {
	next unless $acc =~ /^btw_v(.)$/;
	my $t = $1;
	($vb) = @{$dbh->do("SELECT SUM(jnl_amount)".
			   " FROM Journal".
			   " WHERE ( jnl_acc_id = ? )".
			   " AND jnl_bsr_date >= ? AND jnl_bsr_date <= ?",
			   $dbh->std_acc($acc), $begin, $end)};
	next unless defined($vb);
	$vb = -$vb;
	if ( $data{"deb_btw_$t"} != ($v = rounddown($vb)) ) {
	    $data{"btw_v${t}_delta"} = $v - $data{"deb_btw_$t"};
	    $data{"deb_btw_$t"} = $v;
	}
    }

    $data{btw_i_delta} = $btw_i_delta if $btw_i_delta;
    $data{delta} = $delta if $delta;

    return \%data;
}

sub report {
    my ($self, $rep, $data) = @_;

    my $outline = sub {
	my ($column, $desc, $sub, $amt) = @_;
	$rep->add({ _style => 'd',
		     num => $column,
		     desc   => $desc,
		     defined($sub)
		     ? ( col1 => $noround
			 ? numfmt($sub)
			 : $sub)
		     : (),
		     defined($amt)
		     ? (col2 => $noround
			? numfmt($amt)
			: $amt)
		     : (),
		   });
    };

    $rep->start(_T("BTW Aangifte"),
		$self->{compat_periode}
		? __x("Periode: {per}", per => $self->{compat_periode})
		: __x("Periode: {from} t/m {to}",
		      from => datefmt_full($rep->{per_begin}),
		      to   => datefmt_full($rep->{per_end})));

    # Binnenland
    $rep->add({ _style => 'h1', num  => "Binnenland" });

    # 1. Door mij verrichte leveringen/diensten
    $rep->add({ _style => 'h2',
		num => "1. Door mij verrichte leveringen/diensten",
	      });

    # 1a. Belast met hoog tarief
    $outline->("1a", "Belast met hoog tarief",
		  $data->{deb_h}, $data->{deb_btw_h});

    # 1b. Belast met laag tarief
    $outline->("1b", "Belast met laag tarief",
		  $data->{deb_l}, $data->{deb_btw_l});

    # 1c. Belast met ander, niet-nul tarief
    $outline->("1c", "Belast met ander tarief",
		  $data->{deb_a}, $data->{deb_btw_a})
      if $data->{deb_a} || $data->{deb_btw_a};

    # 1d. Eigen gebruik
    $outline->("1d", "Eigen gebruik",
    		  $data->{deb_p}, $data->{deb_btw_p})
      if $data->{deb_p} || $data->{deb_btw_p};

    # 1e. Belast met 0%/verlegd
    $outline->("1e", "Belast met 0% / verlegd",
		  $data->{deb_0}, undef);

    # Buitenland
    $rep->add({ _style => 'h1', num => "Buitenland" });

    # 3. Door mij verrichte leveringen
    $rep->add({ _style => 'h2',
		num => "3. Door mij verrichte leveringen" });
    # 3a. Buiten de EU
    $outline->("3a", "Buiten de EU", $data->{extra_deb}, undef);

    # 3b. Binnen de EU
    $outline->("3b", "Binnen de EU", $data->{intra_deb}, undef);

    # 4. Aan mij verrichte leveringen
    $rep->add({ _style => 'h2',
		num => "4. Aan mij verrichte leveringen" });

    # 4a. Van buiten de EU
    $outline->("4a", "Van buiten de EU",
		  $data->{extra_crd}, 0);

    # 4b. Verwervingen van goederen uit de EU.
    $outline->("4b", "Verwervingen van goederen uit de EU",
		  $data->{intra_crd}, $data->{intra_crd_btw});

    # 5 Berekening totaal
    $rep->add({ _style => 'h1', num => "Berekening" });
    $rep->add({ _style => 'h2',
		num => "5. Berekening totaal" });

    # 5a. Subtotaal
    $outline->("5a", "Subtotaal", undef, $data->{sub0});

    # 5b. Voorbelasting
    $outline->("5b", "Voorbelasting", undef, $data->{vb});

    # 5c Subtotaal
    $outline->("5c", "Subtotaal", undef, $data->{sub1});

    if ( $self->{compat_periode} =~ /^\d\d\d\d$/ ) { # aangifte per jaar
	if ( defined($data->{ko}) ) {
	    # 5d Subtotaal
	    $outline->("5d", "Vermindering kleineondernemersregeling", undef, $data->{ko});
	}
	else {
	    $outline->("5d", "Geen gegevens voor kleineondernemersregeling", undef, undef);
	}
    }

    # 5g Subtotaal
    if ( $data->{tot} >= 0 ) {
	$outline->("5g", "Totaal te betalen", undef, $data->{tot});
	if ( $data->{delta} ) {
	    $outline->("", "Totaal te betalen (onafgerond)", numfmt($data->{sub1}*AMTSCALE+$data->{delta}));
	    $outline->("", "Afrondingsverschil", numfmt($data->{delta}));
	}
    }
    else {
	$outline->("5g", "Totaal terug te vragen", undef, 0-$data->{tot});
	if ( $data->{delta} ) {
	    $outline->('', "Totaal terug te vragen (onafgerond)",
			  numfmt(-($data->{sub1}*AMTSCALE+$data->{delta})));
	    $outline->('', "Afrondingsverschil", numfmt($data->{delta}));
	}
    }
    $outline->("?", "Onbekend", undef, numfmt($data->{onbekend}))
	      if $data->{onbekend};

    my @msg;
    if ( $data->{btw_i_delta} ) {
	push(@msg,
	     __x("Er is een verschil van {round}{amount}".
		 " tussen de berekende en werkelijk ingehouden BTW.".
		 " Voor de aangifte is de werkelijk ingehouden waarde gebruikt.",
		 round  => $noround ? "" : "(afgerond) ",
		 amount => numfmt($noround ? $data->{btw_i_delta}
				 : AMTSCALE*roundup($data->{btw_i_delta}))));
    }

    foreach my $type ( @{BTWTARIEVEN()} ) {
	my $t = lc(substr($type, 0, 1));
	if ( $data->{"btw_v".$t."_delta"} ) {
	    push(@msg,
		 __x("Er is een verschil van {round}{amount}".
		     " tussen de berekende en werkelijk afgedragen BTW {type}.".
		     " Voor de aangifte is de werkelijk afgedragen waarde gebruikt.",
		     type   => $type,
		     round  => $noround ? "" : "(afgerond) ",
		     amount => numfmt(($noround ? 1 : AMTSCALE) * $data->{"btw_v".$t."_delta"})));
	}
    }

    $rep->finish(@msg);

}

################ Subroutines ################

sub rounddown {
    my ($vb) = @_;
    return 0 unless $vb;
    return $vb if $noround;
    $vb /= AMTSCALE;
    if ( $vb >= 0 ) {
	$vb = floor($vb);
    }
    else {
	$vb = -ceil(abs($vb));
    }
    $vb;
}

sub roundup {
    my ($vb) = @_;
    return 0 unless $vb;
    return $vb if $noround;
    $vb /= AMTSCALE;
    if ( $vb >= 0 ) {
	$vb = ceil($vb);
    }
    else {
	$vb = -floor(abs($vb));
    }
    $vb;
}

sub roundtozero {
    my ($vb) = @_;
    return 0 unless $vb;
    return $vb if $noround;
    $vb /= AMTSCALE;
    if ( $vb >= 0 ) {
	$vb = floor($vb);
    }
    else {
	$vb = 0-floor(abs($vb));
    }
    $vb;
}

sub kleine_ondernemers {
    my ($year, $amount) = @_;

    return 0 if $amount < 0;

    # Formule lijkt linds 1995 ongwijzigd, alleen de bedragen
    # veranderen. Sinds 2002 zijn de bedragen ongewijzigd. Alle
    # officiële documentatie spreeekt over "Als de afdracht van
    # omzetbelasting beneden de 1.345 per jaar blijft, ...".

    # Code change: beschouw de huidige bedragen als vaststaand.

    return if $year < 2002;

    # my %mmtab = ( 2002 => [ 1345, 1883 ],
    #		  2003 => [ 1345, 1883 ],
    #		  2004 => [ 1345, 1883 ],
    #		  2005 => [ 1345, 1883 ],
    #		  2006 => [ 1345, 1883 ],
    #		  2007 => [ 1345, 1883 ],
    #		);
    #
    # $mmtab{$year} ||= [ 1345, 1883 ] if $year >= 2002;
    #
    # return unless exists $mmtab{$year};
    #
    # my ($min, $max) = @{$mmtab{$year}};

    my ($min, $max) = ( 1345, 1883 );

    if ( $noround ) {
	$min *= AMTSCALE;
	$max *= AMTSCALE;
    }

    return $amount if $amount <= $min;
    return 0       if $amount >  $max;

    my $kko = ($min / ($max - $min)) * ($max - $amount);
    return $noround ? $kko : roundup($kko*AMTSCALE);
}

sub warnings {
    my $self = shift;
    return unless @_;
    my (@msgs) = @_;
    foreach ( @msgs ) {
	warn("!".$_."\n");
    }
}

package EB::Report::BTWAangifte::Text;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Text);

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	h1  => {
	    _style => { skip_before => 1,
			skip_after => 1 },
	    num => { colspan => 2 },
	},
	h2  => {
	    _style => { skip_before => 1,
			skip_after => 1 },
	    num => { colspan => 2 },
	},
	d => {
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

sub finish {
    shift->SUPER::finish;
    EB::Report::BTWAangifte::warnings(undef, @_);
}

package EB::Report::BTWAangifte::Html;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Html);

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	h1  => {
	    num => { class => "heading", colspan => 2 },
	},
	h2  => {
	    num => { class => "subheading", colspan => 2 },
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

sub finish {
    my $self = shift;
    if ( @_ ) {
	print { $self->{fh} } ("</table>\n");
	print { $self->{fh} } ("<p class=\"warning\">\n");
	print { $self->{fh} } (join("<br>\n", map { $self->html($_) } @_) );
	print { $self->{fh} } ("</p>\n");
	print { $self->{fh} } ("<table>\n");
    }
    $self->SUPER::finish;
}

package EB::Report::BTWAangifte::Csv;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Csv);

sub finish {
    shift->SUPER::finish;
    EB::Report::BTWAangifte::warnings(undef, @_);
}

1;
