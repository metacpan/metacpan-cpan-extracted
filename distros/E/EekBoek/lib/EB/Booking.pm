#! perl --			-*- coding: utf-8 -*-

use utf8;

# Booking.pm -- Base class for Bookings.
# Author          : Johan Vromans
# Created On      : Sat Oct 15 23:36:51 2005
# Last Modified By: Johan Vromans
# Last Modified On: Fri Aug 31 19:07:41 2012
# Update Count    : 208
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Booking;

use strict;
use warnings;

use EB;
use EB::Format;

sub new {
    my ($class) = @_;
    $class = ref($class) || $class;
    return bless {} => $class;
}

sub adm_open {
    my ($self) = @_;
    unless ( $dbh->adm_open ) {
	warn("?"._T("De administratie is nog niet geopend")."\n");
	return;
    }
    1;
}

sub check_bsk_nr {
    my ($self, $opts) = @_;
    my $bsk_nr = $opts->{boekstuk};
    my $bky = $opts->{boekjaar};
    $bky = $dbh->adm("bky") unless defined($bky);
    my $dbk = $opts->{dagboek};
    my $rr = $dbh->do("SELECT count(*) FROM Boekstukken".
		      " WHERE bsk_nr = ? AND bsk_dbk_id = ? AND bsk_bky = ?",
		      $bsk_nr, $dbk, $bky);
    return 1 if defined($rr) && $rr->[0] == 0;
    warn("?".__x("Boekstuk {bsk} is reeds in gebruik",
		 bsk => join(":",
			     $dbh->lookup($dbk, qw(Dagboeken dbk_id dbk_desc)),
			     $bsk_nr))."\n");
    return;
}

sub bsk_nr {
    my ($self, $opts) = @_;
    my $bsk_nr;
    my $prev = defined($opts->{boekjaar}) && $opts->{boekjaar} ne $dbh->adm("bky");
    if ( $bsk_nr = $opts->{boekstuk} ) {
	unless ( $bsk_nr =~ /^[0-9]+$/ ) {
	    warn("?"._T("Het boekstuknummer moet een geheel getal (volgnummer) zijn")."\n");
	    return;
	}
	return unless $self->check_bsk_nr($opts);
	my $t = $prev ? "0" : $opts->{dagboek};
	$dbh->set_sequence("bsk_nr_${t}_seq", $bsk_nr+1)
#	  if $dbh->get_sequence("bsk_nr_${t}_seq", "noincr") < $bsk_nr;
    }
    elsif ( $prev ) {
	warn("?"._T("Boekstukken in voorafgaande boekjaren moeten verplicht worden voorzien van een boekstuknummer")."\n");
	return;
	#$bsk_nr = $dbh->get_sequence("bsk_nr_0_seq");
    }
    else {
	$bsk_nr = $dbh->get_sequence("bsk_nr_".$opts->{dagboek}."_seq");
	$opts->{boekstuk} = $bsk_nr;
	return unless $self->check_bsk_nr($opts);
    }
    $bsk_nr;
}

sub begindate {
    my ($self) = @_;

    my $begin;
    my $end;
    if ( $self->{bky} ne $dbh->adm("bky") ) {
	my ($b, $e, $c) = @{$dbh->do("SELECT bky_begin, bky_end, bky_closed".
				     " FROM Boekjaren".
				     " WHERE bky_code = ?", $self->{bky})};
	if ( $c ) {
	    warn("?".__x("Boekjaar {code} is gesloten, er kan niet meer in worden gewijzigd",
		       code => $self->{bky})."\n");
	    return;
	}
	$begin = $b;
	$end = $e;
    }
    elsif ( $dbh->adm("closed") ) {
	warn("?"._T("De administratie is gesloten en kan niet meer worden gewijzigd")."\n");
	return;
    }
    $begin ||= $dbh->adm("begin");
    return $begin unless wantarray;
    $end ||= $dbh->adm("end");
    ($begin, $end);
}

sub in_bky {
    my ($self, $date, $begin, $end) = @_;
    if ( $date lt $begin ) {
	warn("?".__x("De boekingsdatum {date} valt vóór aanvang van dit boekjaar",
		     date => datefmt_full($date))."\n");
	return;
    }
    if ( $date gt $end ) {
	warn("?".__x("De boekingsdatum {date} valt na het einde van dit boekjaar",
		     date => datefmt_full($date))."\n");
	return;
    }
    1;
}

sub amount_with_btw {
    my ($self, $amt, $btw_spec) = @_;
    my $explicit;
    if ( $amt =~ /^(.+)\@(.+)$/ ) {
	$amt = $1;
	$btw_spec = $2;
	$explicit = $btw_spec !~ /^[hlgn]?[-+]?[ko]?$/i;
    }
    return (amount($amt), $btw_spec, $explicit);
}

sub parse_btw_spec {
    my ($self, $spec, $btw_id, $kstomz) = @_;
    return (0, undef) unless defined($spec);
    $spec = lc($spec);

    # Quickie for G/N.
    if ( $spec =~ /^([gn])$/ ) {
	return (0, undef);
    }
    # Quickie for K/O.
    elsif ( $spec =~ /^([ko])$/ ) {
	return ($btw_id, $1 eq 'k');
    }
    # Strip off trailing K|O.
    elsif ( $spec =~ /^([hl]|\d+)([-+]?)([ko])$/ || $spec =~ /^(\w+)([-+])([ko])$/ ) {
	$kstomz = $3 eq 'k';
	$spec = $1.$2;
    }

=begin deprecated

    # Deprecated since several years...
    elseif ( $spec =~ /^(.*)([iv])(.*)$/ ) {
	$kstomz = $2 eq 'i';
	$spec = $1.$3;
	warn("!".__x("BTW specificatie {spec}: Gebruik K of O in plaats van I of V",
		     spec => $_[0])."\n");
    }

=cut

    # Examine rest. Numeric -> BTW id.
    if ( $spec =~ /^(\d+)([-+])?$/ ) {
	$btw_id = $1;
	if ( defined $2 ) {
	    my $excl = $2 eq '-';
	    my $res = $dbh->do("SELECT btw_perc, btw_tariefgroep FROM BTWTabel".
			       " WHERE btw_id = ?",
			       $btw_id);
	    return unless $res;
	    $res = $dbh->do("SELECT btw_id FROM BTWTabel".
			    " WHERE btw_perc = ? AND btw_tariefgroep = ?".
			    "  AND ".($excl?"NOT ":"")."btw_incl",
			    $res->[0], $res->[1]);
	    return unless $res;
	    $btw_id = $res->[0];
	}
    }
    # H L H- L- H+ L+
    elsif ( $spec =~ /^([hl])([-+])?$/ ) {
	$btw_id = $1;
	my $excl;
	$excl = $2 eq '-' if defined $2;
	my $res = $dbh->da("SELECT btw_id, btw_alias, btw_desc FROM BTWTabel".
			   " WHERE btw_tariefgroep = ?".
			   " AND ".($excl?"NOT ":"")."btw_incl".
			   " ORDER BY btw_id ASC",
			   $btw_id eq "h" ? BTWTARIEF_HOOG : BTWTARIEF_LAAG);
	warn("!".__x("BTW aanduiding \"{spec}\" kent meerdere tariefcodes: {list} (code {code} \"{desc}\" is gebruikt)",
		     spec => $spec,
		     list => join(" ", map { defined($_->[1]) ? $_->[1] : $_->[0] } @$res),
		     code => $res->[0]->[0],
		     desc => $res->[0]->[2],
		    )."\n") if @$res != 1;
	$btw_id = $res->[0]->[0];
    }
    # alias
    elsif ( $spec =~ /^(\w\w+)([-+])?$/ ) {
	# warn("SPEC: $spec\n"); $dbh->trace(1);
	my $res = $dbh->do("SELECT btw_id, btw_perc, btw_tariefgroep FROM BTWTabel".
			   " WHERE btw_alias = ?",
			   lc $1);
	# $dbh->trace(0);
	return unless $res;

	$btw_id = $res->[0];
	if ( defined $2 ) {
	    my $excl = $2 eq '-';
	    # $dbh->trace(1);
	    $res = $dbh->do("SELECT btw_id FROM BTWTabel".
			    " WHERE btw_perc = ? AND btw_tariefgroep = ?".
			    "  AND ".($excl?"NOT ":"")."btw_incl",
			    $res->[1], $res->[2]);
	    # $dbh->trace(0);
	    return unless $res;
	    $btw_id = $res->[0];
	}
	# warn("SPEC: $spec => $btw_id\n");
    }
    # + -
    elsif ( $spec =~ /^([-+])$/ && $btw_id ) {
	my $res = $dbh->da("SELECT btw_id, btw_desc FROM BTWTabel".
			   " WHERE btw_tariefgroep =".
			   " ( SELECT btw_tariefgroep FROM BTWTabel".
			   " WHERE btw_id = ? )".
			   " AND ".($1 eq '-'?"NOT ":"")."btw_incl",
			   $btw_id);
	warn("!".__x("BTW aanduiding \"{spec}\" kent meerdere tariefcodes: {list} (code {code} \"{desc}\" is gebruikt)",
		     spec => $spec,
		     list => join(" ", map { $_->[0] } @$res),
		     code => $res->[0]->[0],
		     desc => $res->[0]->[1],
		    )."\n") if @$res != 1;
	$btw_id = $res->[0]->[0];
    }
    elsif ( $spec ne '' ) {
	return;
    }
    ($btw_id, $kstomz);
}

#### Class method
sub norm_btw {
    my ($self, $bsr_amt, $bsr_btw_id) = @_;
    my ($btw_perc, $btw_incl);
    if ( $bsr_btw_id ) {
	my $rr = $dbh->do("SELECT btw_perc, btw_incl, btw_tariefgroep".
			  " FROM BTWTabel".
			  " WHERE btw_id = ?", $bsr_btw_id);
	assert($rr, "Unk BTW: $bsr_btw_id");
	($btw_perc, $btw_incl) = @$rr;
    }

    return [ $bsr_amt, 0 ] unless $btw_perc;

    my $bruto = $bsr_amt;
    my $netto = $bsr_amt;

    if ( $btw_incl ) {
	$netto = numround($bruto * (1 / (1 + $btw_perc/BTWSCALE)));
    }
    else {
	$bruto = numround($netto * (1 + $btw_perc/BTWSCALE));
    }

    [ $bruto, $bruto - $netto, $btw_perc ];
}

#### Class method
sub dcfromtd {
    # Calculate a (debet,credit) pair from a (total,debet) pair.
    my ($total, $debet) = @_;
    return ($debet, $debet-$total) if defined($debet);
    return ($total, 0) if $total >= 0;
    (0, -$total);
}

#### Class method
sub journalise {
    my ($self, $bsk_id, $iv, $total) = @_;
    $total = -$total if defined($total) && !$iv;

    # date  bsk_id  bsr_seq(0)   dbk_id  (acc_id) amount debcrd desc(bsk) (rel)
    # date (bsk_id) bsr_seq(>0) (dbk_id)  acc_id  amount debcrd desc(bsr) rel(acc=1200/1600)
    my ($jnl_date, $jnl_bsk_id, $jnl_dbk_id, $jnl_acc_id,
	$jnl_amount, $jnl_desc, $jnl_rel);

    my $rr = $::dbh->do("SELECT bsk_nr, bsk_desc, bsk_dbk_id, bsk_date, bsk_ref".
		      " FROM Boekstukken".
		      " WHERE bsk_id = ?", $bsk_id);
    my ($bsk_nr, $bsk_desc, $bsk_dbk_id, $bsk_date, $bsk_ref) = @$rr;

    my ($dbktype, $dbkdcsplit, $dbk_acc_id) =
      @{$::dbh->do("SELECT dbk_type, dbk_dcsplit, dbk_acc_id".
		 " FROM Dagboeken".
		 " WHERE dbk_id = ?", $bsk_dbk_id)};
    my $sth = $::dbh->sql_exec("SELECT bsr_nr, bsr_date, ".
			     "bsr_desc, bsr_amount, bsr_btw_class, bsr_btw_id, ".
			     "bsr_btw_acc, bsr_type, bsr_acc_id, bsr_rel_code, bsr_dbk_id".
			     " FROM Boekstukregels".
			     " WHERE bsr_bsk_id = ?", $bsk_id);

    my $ret = [];
    my $tot = 0;
    my ($dtot, $ctot) = (0, 0);
    my ($vhtot, $vltot) = (0, 0);
    my $nr = 1;
    my $vat; 			# for automatic rounding VAT calc
    my $g_bsr_rel_code;

    while ( $rr = $sth->fetchrow_arrayref ) {
	my ($bsr_nr, $bsr_date, $bsr_desc, $bsr_amount, $bsr_btw_class,
	    $bsr_btw_id, $bsr_btw_acc, $bsr_type, $bsr_acc_id, $bsr_rel_code,
	    $bsr_rel_dbk) = @$rr;
	my $bsr_bsk_id = $bsk_id;
	my $btw = 0;
	my $amt = $bsr_amount;
	$g_bsr_rel_code = $bsr_rel_code if defined $iv && $bsr_rel_code;

	if ( ($bsr_btw_class & BTWKLASSE_BTW_BIT) && $bsr_btw_id && $bsr_btw_acc ) {
	    ( $bsr_amount, $btw, my $perc ) =
	      @{$self->norm_btw($bsr_amount, $bsr_btw_id)};
	    $amt = $bsr_amount - $btw;
	    $vat->{$bsr_btw_acc}->{amt} += $amt;
	    $vat->{$bsr_btw_acc}->{btw} += $btw;
	    $vat->{$bsr_btw_acc}->{prc} = $perc;
	}
	$tot += $bsr_amount;
	$dtot += $bsr_amount if $bsr_amount < 0;
	$ctot += $bsr_amount if $bsr_amount > 0;
	my $btwtag = _T("BTW ");
	push(@$ret, [$bsk_date, $bsk_dbk_id, $bsk_id, $bsr_date, $bsr_nr, $nr++,
		     0, $bsr_acc_id,
		     $bsr_amount - $btw, undef, $bsr_desc,
		     $bsr_type ? ($bsr_rel_code, $bsr_rel_dbk) : (undef, undef), undef]);
	push(@$ret, [$bsk_date,  $bsk_dbk_id, $bsk_id, $bsr_date, $bsr_nr, $nr++,
		     1, $bsr_btw_acc,
		     $btw, undef, $btwtag.$bsr_desc,
		     undef, undef, undef]) if $btw;
    }

    if ( defined($total) && $tot != $total
	 && $cfg->val(qw(strategy iv_vc), 1)
       ) { # mismatch!
	#warn("=> $tot <-> $total\n");
	# Vaak het gevolg van verschil in BTW berekening per
	# boekingsregel versus per boekstuktotaal.

	while ( my($k,$v) = each(%$vat) ) {
	    # Bereken BTW over totaal van deze tariefgroep.
	    my $t = numround($v->{amt} * ($v->{prc}/BTWSCALE));
	    if ( $t != $v->{btw} ) { # Aha!
		#warn("=> [$k] $v->{btw} <-> $t\n");
		# Corrigeer het totaal, en maak een correctieboekstukregel.
		$tot -= $v->{btw} - $t;
		push(@$ret, [$bsk_date,  $bsk_dbk_id, $bsk_id, $bsk_date, undef, $nr++,
			     1, $k,
			     $t - $v->{btw}, undef, _T("BTW Afr. ").$bsk_desc,
			     undef, undef, undef]);
		warn("!".__x("BTW rek. nr. {acct}, correctie van {amt} uitgevoerd",
			     acct => $k, amt => numfmt($t-$v->{btw}))."\n");
	    }
	}
    }

    if ( $dbk_acc_id ) {
	if ( $dbkdcsplit ) {
	    push(@$ret, [$bsk_date,  $bsk_dbk_id, $bsk_id, $bsk_date, undef, $nr++,
			 0, $dbk_acc_id,
			 -$tot, -$dtot, $bsk_desc, undef, undef, undef]);
	}
	else {
	    push(@$ret, [$bsk_date,  $bsk_dbk_id, $bsk_id, $bsk_date, undef, $nr++,
			 0, $dbk_acc_id,
			 -$tot, undef, $bsk_desc, undef, undef, undef]);
	}
    }

    unshift(@$ret, [$bsk_date, $bsk_dbk_id, $bsk_id, $bsk_date, undef, 0, 0, undef,
		    undef, undef, $bsk_desc, $g_bsr_rel_code, undef, $bsk_ref]);

    $ret;
}

1;
