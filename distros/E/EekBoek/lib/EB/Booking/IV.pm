#! perl --			-*- coding: utf-8 -*-

use utf8;

package main;

our $cfg;
our $dbh;

package EB::Booking::IV;

# Author          : Johan Vromans
# Created On      : Thu Jul  7 14:50:41 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 27 13:23:24 2012
# Update Count    : 343
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Dagboek type 1: Inkoop
# Dagboek type 2: Verkoop

use EB;
use EB::Format;
use EB::Report::Journal;
use base qw(EB::Booking);

my $trace_updates = $cfg->val(__PACKAGE__, "trace_updates", 0);	# for debugging

sub perform {
    my ($self, $args, $opts) = @_;

    return unless $self->adm_open;

    my $dagboek = $opts->{dagboek};
    my $dagboek_type = $opts->{dagboek_type};
    my $bsk_ref = $opts->{ref};

    if ( defined $bsk_ref && $bsk_ref =~ /^\d+$/ ) {
	warn("?".__x("Boekingsreferentie moet tenminste één niet-numeriek teken bevatten: {ref}", ref => $bsk_ref)."\n");
	return;
    }

    unless ( $dagboek_type == DBKTYPE_INKOOP || $dagboek_type == DBKTYPE_VERKOOP) {
	warn("?".__x("Ongeldige operatie (IV) voor dagboek type {type}",
		     type => $dagboek_type)."\n");
	return;
    }

    my $iv = $dagboek_type == DBKTYPE_INKOOP;
    my $totaal = $opts->{totaal};
    my $does_btw = $dbh->does_btw;

    my $bky = $self->{bky} ||= $opts->{boekjaar} || $dbh->adm("bky");

    if ( defined($totaal) ) {
	my $t = amount($totaal);
	return "?".__x("Ongeldig totaal: {total}", total => $totaal)
	  unless defined $t;
	$totaal = $t;
    }

    my ($begin, $end);
    return unless ($begin, $end) = $self->begindate;

    my $date;
    if ( $date = parse_date($args->[0], substr($begin, 0, 4)) ) {
	shift(@$args);
    }
    else {
	return "?".__x("Onherkenbare datum: {date}",
		       date => $args->[0])."\n"
	  if ($args->[0]||"") =~ /^[[:digit:]]+-/;
	$date = iso8601date();
    }

    return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
      unless @$args >= 3;

    return unless $self->in_bky($date, $begin, $end);

    if ( $does_btw && $dbh->adm("btwbegin") && $date lt $dbh->adm("btwbegin") ) {
	warn("?"._T("De boekingsdatum valt in de periode waarover al BTW aangifte is gedaan")."\n");
	return;
    }

    my $gdesc = "";
    my $debcode;
    my $rr;

    if ( $cfg->val(qw(general ivdesc), undef) ) {
	$gdesc  = shift(@$args);
	$debcode = shift(@$args);
	$rr = $dbh->do("SELECT rel_code, rel_acc_id, rel_btw_status FROM Relaties" .
		       " WHERE UPPER(rel_code) = ?" .
		       "  AND " . ($iv ? "NOT " : "") . "rel_debcrd" .
		       "  AND rel_ledger = ?",
		       uc($debcode), $dagboek);
	unless ( defined($rr) ) {
	    unshift(@$args, $debcode);
	    $debcode = $gdesc;
	    $gdesc = "";
	    $rr = $dbh->do("SELECT rel_code, rel_acc_id, rel_btw_status FROM Relaties" .
			   " WHERE UPPER(rel_code) = ?" .
			   "  AND " . ($iv ? "NOT " : "") . "rel_debcrd" .
			   "  AND rel_ledger = ?",
			   uc($debcode), $dagboek);
	    unless ( defined($rr) ) {
		warn("?".__x("Onbekende {what}: {who}",
			     what => lc($iv ? _T("Crediteur") : _T("Debiteur")),
			     who => $debcode)."\n");
		return;
	    }
	}
    }
    else {
	$debcode = shift(@$args);
	$rr = $dbh->do("SELECT rel_code, rel_acc_id, rel_btw_status FROM Relaties" .
		       " WHERE UPPER(rel_code) = ?" .
		       "  AND " . ($iv ? "NOT " : "") . "rel_debcrd" .
		       "  AND rel_ledger = ?",
		       uc($debcode), $dagboek);
	unless ( defined($rr) ) {
	    $gdesc = $debcode;
	    $debcode = shift(@$args);
	    $rr = $dbh->do("SELECT rel_code, rel_acc_id, rel_btw_status FROM Relaties" .
			   " WHERE UPPER(rel_code) = ?" .
			   "  AND " . ($iv ? "NOT " : "") . "rel_debcrd" .
			   "  AND rel_ledger = ?",
			   uc($debcode), $dagboek);
	    unless ( defined($rr) ) {
		warn("?".__x("Onbekende {what}: {who}",
			     what => lc($iv ? _T("Crediteur") : _T("Debiteur")),
			     who => $debcode)."\n");
		return;
	    }
	}
    }

    my ($rel_acc_id, $rel_btw);
    ($debcode, $rel_acc_id, $rel_btw) = @$rr;

    my $btw_adapt = $cfg->val(qw(strategy btw_adapt), 0);
    my $nr = 1;
    my $bsk_id;
    my $bsk_nr;
    my $did = 0;

    while ( @$args ) {
	return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
	  unless @$args >= 2;
	my ($desc, $amt, $acct) = splice(@$args, 0, 3);
	my $bsr_ref;
	$desc = $gdesc if $desc !~ /\S/;
	$gdesc = $desc if $gdesc !~ /\S/;
	$acct ||= $rel_acc_id;
	if ( $opts->{verbose} ) {
	    my $t = $desc;
	    $t = '"' . $desc . '"' if $t =~ /\s/;
	    warn(" "._T("boekstuk").": $t $amt $acct\n");
	}
	unless ( $desc =~ /\S/ ) {
	    warn("?"._T("De omschrijving van de boekstukregel ontbreekt")."\n");
	    return;
	}

	if  ( $acct !~ /^\d+$/ ) {
	    if ( $acct =~ /^(\d*)([cd])/i ) {
		warn("?"._T("De \"D\" of \"C\" toevoeging aan het rekeningnummer is hier niet toegestaan")."\n");
		return;
	    }
	    warn("?".__x("Ongeldig grootboekrekeningnummer: {acct}", acct => $acct )."\n");
	    return;
	}
	my $rr = $dbh->do("SELECT acc_desc,acc_balres,acc_kstomz,acc_debcrd,acc_btw".
			  " FROM Accounts".
			  " WHERE acc_id = ?", $acct);
	unless ( $rr ) {
	    warn("?".__x("Onbekende grootboekrekening: {acct}",
			 acct => $acct)."\n");
	    $dbh->rollback if $dbh->in_transaction;
	    return;
	}
	my ($adesc, $balres, $kstomz, $debcrd, $btw_id) = @$rr;
	if ( $balres ) {
	    warn("!".__x("Grootboekrekening {acct} ({desc}) is een balansrekening",
			 acct => $acct, desc => $adesc)."\n") if 0;
	    #$dbh->rollback;
	    #return;
	}
	if ( $btw_id && !$does_btw ) {
	    croak("INTERNAL ERROR: ".
		  __x("Grootboekrekening {acct} heeft BTW in een BTW-vrije administratie",
		      acct => $acct));
	}

	if ( $nr == 1 ) {
	    $bsk_nr = $self->bsk_nr($opts);
	    return unless defined($bsk_nr);
	    $bsk_id = $dbh->get_sequence("boekstukken_bsk_id_seq");
	    if ( $bsk_ref and $dbh->do("SELECT count(*)".
				       " FROM Boekstukken, Boekstukregels".
				       " WHERE bsk_id = bsr_bsk_id".
				       " AND upper(bsk_ref) = ?".
				       " AND upper(bsr_rel_code) = ?".
				       " AND bsk_bky = ?",
				       uc($bsk_ref), uc($debcode), $bky)->[0] ) {
		warn("?".__x("Referentie {ref} bestaat al voor relatie {rel}",
			     rel => $debcode, ref => $bsk_ref)."\n");
		return;
	    }


	    $dbh->begin_work;
	    $dbh->sql_insert("Boekstukken",
			     [qw(bsk_id bsk_nr bsk_ref bsk_desc bsk_dbk_id bsk_date bsk_bky)],
			     $bsk_id, $bsk_nr, $bsk_ref, $gdesc, $dagboek, $date, $bky);
	}

	# Amount can override BTW id with @X postfix.
	my ($namt, $btw_spec, $btw_explicit) =
	  $does_btw ? $self->amount_with_btw($amt, $btw_id) : amount($amt);
	unless ( defined($namt) ) {
	    warn("?".__x("Ongeldig bedrag: {amt}", amt => $amt)."\n");
	    return;
	}

	$amt = $iv ? $namt : -$namt;

	if ( $does_btw ) {
	    ($btw_id, $kstomz) = $self->parse_btw_spec($btw_spec, $btw_id, $kstomz);
	    unless ( defined($btw_id) ) {
		warn("?".__x("Ongeldige BTW-specificatie: {spec}", spec => $btw_spec)."\n");
		return;
	    }
	}

	# Bepalen van de BTW.
	# Voor neutrale boekingen (@N, of op een neutrale rekening) wordt geen BTW
	# toegepast. Op _alle_ andere wel. De BTW kan echter nul zijn, of void.
	# Het eerste wordt bewerkstelligd door $btw_id op 0 te zetten, het tweede
	# door $btw_acc geen waarde te geven.
	my $btwclass = 0;
	my $btw_acc;
	if ( defined($kstomz) ) {
	    # BTW toepassen.
	    if ( $kstomz ? !$iv : $iv ) {
		#warn("?".__x("U kunt geen {ko} boeken in een {iv} dagboek",
		warn("!".__x("Pas op! U boekt {ko} in een {iv} dagboek",
			     ko => $kstomz ? _T("kosten") : _T("omzet"),
			     iv => $iv ? _T("inkoop") : _T("verkoop"),
			    )."\n");
		#return;
	    }
	    # Void BTW voor non-EU en verlegd.
	    if ( $btw_id && ($rel_btw == BTWTYPE_NORMAAL || $rel_btw == BTWTYPE_INTRA) ) {

		my $res = $dbh->do( "SELECT btw_tariefgroep, btw_start, btw_end, btw_alias, btw_desc, btw_incl".
				    " FROM BTWTabel".
				    " WHERE btw_id = ?",
				    $btw_id );
		my $incl = $res->[5];

		my $tg;
		unless ( defined($res) && defined( $tg = $res->[0] ) ) {
		    warn("?".__x("Onbekende BTW-code: {code}", code => $btw_id)."\n");
		    return;
		}
		if ( defined( $res->[1] ) && $res->[1] gt $date ) {
		    my $ok = 0;
		    if ( $btw_adapt && !$btw_explicit ) {
			my $rr = $dbh->do( "SELECT btw_id, btw_desc".
					   " FROM BTWTabel".
					   " WHERE btw_tariefgroep = ?".
					   " AND btw_end >= ?".
					   " AND " . ( $incl ? "" : "NOT " ) . "btw_incl".
					   " ORDER BY btw_id",
					   $tg, $date );
			if ( $rr && $rr->[0] ) {
			    warn("%".__x("BTW-code: {code} aangepast naar {new} i.v.m. de boekingsdatum",
					 code => $res->[3]||$res->[4]||$btw_id,
					 new => $rr->[1]||$rr->[0],
					)."\n");
			    $btw_id = $rr->[0];
			    $ok++;
			}
		    }
		    unless ( $ok ) {
			warn("!".__x("BTW-code: {code} is nog niet geldig op de boekingsdatum",
				     code => $res->[3]||$res->[4]||$btw_id)."\n");
		    }
		}
		if ( defined( $res->[2] ) && $res->[2] lt $date ) {
		    my $ok = 0;
		    if ( $btw_adapt && !$btw_explicit ) {
			my $rr = $dbh->do( "SELECT btw_id, btw_desc".
					   " FROM BTWTabel".
					   " WHERE btw_tariefgroep = ?".
					   " AND btw_start <= ?".
					   " AND " . ( $incl ? "" : "NOT " ) . "btw_incl".
					   " ORDER BY btw_id",
					   $tg, $date );
			if ( $rr && $rr->[0] ) {
			    warn("%".__x("BTW-code: {code} aangepast naar {new} i.v.m. de boekingsdatum",
					 code => $res->[3]||$res->[4]||$btw_id,
					 new => $rr->[1]||$rr->[0],
					)."\n");
			    $btw_id = $rr->[0];
			    $ok++;
			}
		    }
		    unless ( $ok ) {
			warn("!".__x("BTW-code: {code} is niet meer geldig op de boekingsdatum",
				     code => $res->[3]||$res->[4]||$btw_id)."\n");
		    }
		}
		my $tp = BTWTARIEVEN->[$tg];
		my $t = qw(v i)[$iv] . lc(substr($tp, 0, 1));
		$btw_acc = $dbh->std_acc("btw_$t");
	    }
	}
	elsif ( $btw_id ) {
	    warn("?"._T("BTW toepassen is niet mogelijk op een neutrale rekening")."\n");
	    return;
	}
	# ASSERT: $btw_id != 0 implies defined($kstomz).

	$dbh->sql_insert("Boekstukregels",
			 [qw(bsr_nr bsr_date bsr_bsk_id bsr_desc bsr_amount
			     bsr_btw_id bsr_btw_acc bsr_btw_class bsr_type bsr_acc_id
			     bsr_rel_code bsr_dbk_id bsr_ref)],
			 $nr++, $date, $bsk_id, $desc, $amt,
			 $btw_id, $btw_acc,
			 BTWKLASSE($does_btw ? defined($kstomz) : 0, $rel_btw, defined($kstomz) ? $kstomz : $iv),
			 0, $acct, $debcode, $dagboek, $bsr_ref);
    }

    my $ret = $self->journalise($bsk_id, $iv, $totaal);
#    $rr = [ @$ret ];
#    shift(@$rr);
#    $rr = [ sort { $a->[5] <=> $b->[5] } @$rr ];
#    foreach my $r ( @$rr ) {
#	my (undef, undef, undef, undef, $nr, $ac, $amt) = @$r;
#	next unless $nr;
#	warn("update $ac with ".numfmt($amt)."\n") if $trace_updates;
#	$dbh->upd_account($ac, $amt);
#    }
    my $tot = $ret->[$#{$ret}]->[8]; # ERROR PRONE
    $dbh->sql_exec("UPDATE Boekstukken SET bsk_amount = ?, bsk_open = ? WHERE bsk_id = ?",
		   $tot, $tot, $bsk_id)->finish;

    $dbh->store_journal($ret);

    $tot = -$tot if $iv;
    my $fail = defined($totaal) && $tot != $totaal;
    if ( $opts->{journal} ) {
	warn("?"._T("Dit overzicht is ter referentie, de boeking is niet uitgevoerd!")."\n") if $fail;
	EB::Report::Journal->new->journal
	    ({select => $bsk_id,
	      d_boekjaar => $bky,
	      detail => 1});
    }

    if ( $fail ) {
	$dbh->rollback;
	return "?"._T("Boeking ".
		      join(":", $dbh->lookup($dagboek, qw(Dagboeken dbk_id dbk_desc)), $bsk_nr).
		      " is niet uitgevoerd!")." ".
	  __x(" Boekstuk totaal is {act} in plaats van {exp}",
	      act => numfmt($tot), exp => numfmt($totaal)) . ".";
    }
    else {
	$dbh->commit;
    }

    # TODO -- need this to get a current booking.
    $opts->{verbose} || 1
      ? join(":", $dbh->lookup($dagboek, qw(Dagboeken dbk_id dbk_desc)), $bsk_nr)
	: "";
}

1;
