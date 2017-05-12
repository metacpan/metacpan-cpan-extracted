#! perl

package main;

our $cfg;
our $dbh;

package EB::Booking::BKM;

# Author          : Johan Vromans
# Created On      : Thu Jul  7 14:50:41 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 27 13:24:53 2012
# Update Count    : 547
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Dagboek type 3: Bank
# Dagboek type 4: Kas
# Dagboek type 5: Memoriaal

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
    my $totaal = $opts->{totaal};
    my $saldo = $opts->{saldo};
    my $beginsaldo = $opts->{beginsaldo};
    my $does_btw = $dbh->does_btw;
    my $verbose = $opts->{verbose};

    if ( defined($totaal) ) {
	my $t = amount($totaal);
	return "?".__x("Ongeldig totaal: {total}", total => $totaal)
	  unless defined $t;
	$totaal = $t;
    }

    if ( defined($saldo) ) {
	my $t = amount($saldo);
	return "?".__x("Ongeldig saldo: {saldo}", saldo => $saldo)
	  unless defined $t;
	$saldo = $t;
    }

    if ( defined($beginsaldo) ) {
	my $t = amount($beginsaldo);
	return "?".__x("Ongeldig beginsaldo: {saldo}", saldo => $beginsaldo)
	  unless defined $t;
	$beginsaldo = $t;
    }

    my $bky = $self->{bky} ||= $opts->{boekjaar} || $dbh->adm("bky");

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
      unless @$args;

    return unless $self->in_bky($date, $begin, $end);

    my $gdesc = shift(@$args);

    my $bsk_nr = $self->bsk_nr($opts);
    return unless defined($bsk_nr);

    my $nr = 1;
    my $bsk_id;
    my $gacct = $dbh->lookup($dagboek, qw(Dagboeken dbk_id dbk_acc_id));
    my $btw_adapt = $cfg->val(qw(strategy btw_adapt), 0);

    if ( $gacct ) {
	my $vsaldo = saldo_for($dagboek, $bsk_nr-1, $bky);
	if ( defined $beginsaldo ) {
	    return "?".__x("Beginsaldo komt niet overeen met het eindsaldo van de voorgaande boeking",
			   s1 => numfmt($beginsaldo), s2 => numfmt($vsaldo))."\n"
			     if defined($vsaldo) && $vsaldo != $beginsaldo;
	    print(__x("Beginsaldo: {bal}", bal => numfmt($beginsaldo)), "\n")
	      if $verbose;
	}
	elsif ( defined $vsaldo ) {
	    $beginsaldo = $vsaldo;
	    print(__x("Saldo voorgaande boeking: {bal}", bal => numfmt($beginsaldo)), "\n")
	      if $verbose;
	}
	else {
	    $beginsaldo = $dbh->lookup($gacct, qw(Accounts acc_id acc_balance));
	    print(__x("Huidig saldo: {bal}", bal => numfmt($beginsaldo)), "\n")
	      if $verbose;
	}
    }

    $bsk_id = $dbh->get_sequence("boekstukken_bsk_id_seq");
    $dbh->begin_work;
    $dbh->sql_insert("Boekstukken",
		     [qw(bsk_id bsk_nr bsk_desc bsk_dbk_id bsk_date bsk_bky)],
		     $bsk_id, $bsk_nr, $gdesc, $dagboek, $date, $bky);
    my $tot = 0;
    my $did = 0;
    my $fail = 0;

  ENTRY:
    while ( @$args ) {
	my $type = shift(@$args);
	my $bsr_ref;

	if ( $type eq "std" ) {
	    return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
	      unless @$args >= 3;
	    my $dd = parse_date($args->[0], substr($begin, 0, 4));
	    if ( $dd ) {
		shift(@$args);
		return unless $self->in_bky($dd, $begin, $end);
		if ( $does_btw && $dbh->adm("btwbegin") && $dd lt $dbh->adm("btwbegin") ) {
		    warn("?"._T("De boekingsdatum valt in de periode waarover al BTW aangifte is gedaan")."\n");
		    return;
		}
	    }
	    else {
		return "?".__x("Onherkenbare datum: {date}",
			       date => $args->[0])."\n"
		  if ($args->[0]||"") =~ /^[[:digit:]]+-/;
		$dd = $date;
	    }
	    return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
	      unless @$args >= 3;

	    my ($desc, $amt, $acct) = splice(@$args, 0, 3);
	    if ( $opts->{verbose} ) {
		my $t = $desc;
		$t = '"' . $desc . '"' if $t =~ /\s/;
		warn(" "._T("boekstuk").": std $t $amt $acct\n");
	    }

	    if  ( $acct !~ /^\d+$/ ) {
		if ( $acct =~ /^(\d+)([cd])/i ) {
		    warn("?"._T("De \"D\" of \"C\" toevoeging aan het rekeningnummer is hier niet toegestaan")."\n");
		}
		else {
		    warn("?".__x("Ongeldig grootboekrekeningnummer: {acct}", acct => $acct )."\n");
		}
		$fail++;
		next;
	    }

	    my $rr = $dbh->do("SELECT acc_desc,acc_balres,acc_kstomz,acc_btw".
			      " FROM Accounts".
			      " WHERE acc_id = ?", $acct);
	    unless ( $rr ) {
		warn("?".__x("Onbekende grootboekrekening: {acct}",
			     acct => $acct)."\n");
		$fail++;
		next;
	    }
	    my ($adesc, $balres, $kstomz, $btw_id) = @$rr;

	    if ( $balres && $dagboek_type != DBKTYPE_MEMORIAAL ) {
		warn("!".__x("Grootboekrekening {acct} ({desc}) is een balansrekening",
			     acct => $acct, desc => $adesc)."\n") if 0;
	    }
	    if ( $btw_id && !$does_btw ) {
		croak("INTERNAL ERROR: ".
		      __x("Grootboekrekening {acct} heeft BTW in een BTW-vrije administratie",
			  acct => $acct));
	    }

	    my $bid;
	    my $oamt = $amt;
	    my $btw_explicit;
	    ($amt, $bid, $btw_explicit) =
	      $does_btw ? $self->amount_with_btw($amt, undef) : amount($amt);
	    unless ( defined($amt) ) {
		warn("?".__x("Ongeldig bedrag: {amt}", amt => $oamt)."\n");
		$fail++;
		next;
	    }
	    $btw_id = 0, undef($bid) if defined($bid) && !$bid; # override: @0

	    # For memorials, if there's BTW associated, it must be explicitly confirmed.
	    if ( $btw_id && !defined($bid) && $dagboek_type == DBKTYPE_MEMORIAAL ) {
		warn("?"._T("Boekingen met BTW zijn niet mogelijk in een memoriaal.".
			    " De BTW is op nul gesteld.")."\n");
		$btw_id = 0;
	    }

	    my $btw_acc;
	    if ( defined($bid) ) {

		($btw_id, $kstomz) = $self->parse_btw_spec($bid, $btw_id, $kstomz);
		unless ( defined($btw_id) ) {
		    warn("?".__x("Ongeldige BTW-specificatie: {spec}", spec => $bid)."\n");
		    $fail++;
		    next;
		}

		if ( !defined($kstomz) && $btw_id ) {
		    warn("?"._T("BTW toepassen is niet mogelijk op een neutrale rekening")."\n");
		    $fail++;
		    next;
		}
	    }
	    if ( $btw_id ) {
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
		croak("INTERNAL ERROR: btw code $btw_id heeft tariefgroep $tg")
		  unless $tg;
		if ( defined( $res->[1] ) && $res->[1] gt $dd ) {
		    my $ok = 0;
		    if ( $btw_adapt && !$btw_explicit ) {
			my $rr = $dbh->do( "SELECT btw_id, btw_desc".
					   " FROM BTWTabel".
					   " WHERE btw_tariefgroep = ?".
					   " AND btw_end >= ?".
					   " AND " . ( $incl ? "" : "NOT " ) . "btw_incl".
					   " ORDER BY btw_id",
					   $tg, $dd );
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
		if ( defined( $res->[2] ) && $res->[2] lt $dd ) {
		    my $ok = 0;
		    if ( $btw_adapt && !$btw_explicit ) {
			my $rr = $dbh->do( "SELECT btw_id, btw_desc".
					   " FROM BTWTabel".
					   " WHERE btw_tariefgroep = ?".
					   " AND btw_start <= ?".
					   " AND " . ( $incl ? "" : "NOT " ) . "btw_incl".
					   " ORDER BY btw_id",
					   $tg, $dd );
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
		my $t = qw(v i)[$kstomz] . lc(substr($tp, 0, 1));
		$btw_acc = $dbh->std_acc("btw_$t");
	    }

	    my $btw = 0;
	    my $bsr_amount = $amt;
	    my $orig_amount = $amt;
	    my ($btw_ink, $btw_verk);
	    if ( $btw_id ) {
		( $bsr_amount, $btw, $btw_ink, $btw_verk ) =
		  @{$self->norm_btw($bsr_amount, $btw_id)};
		$amt = $bsr_amount - $btw;
	    }
	    $orig_amount = -$orig_amount;

	    $dbh->sql_insert("Boekstukregels",
			     [qw(bsr_nr bsr_date bsr_bsk_id bsr_desc bsr_amount
				 bsr_btw_id bsr_btw_acc bsr_btw_class bsr_type
				 bsr_acc_id bsr_rel_code bsr_dbk_id bsr_ref)],
			     $nr++, $dd, $bsk_id, $desc, $orig_amount,
			     $btw_id, $btw_acc,
			     BTWKLASSE($does_btw ? defined($kstomz) : 0, BTWTYPE_NORMAAL, $kstomz||0),
			     0, $acct, undef, undef, $bsr_ref);

#	    warn("update $acct with ".numfmt(-$amt)."\n") if $trace_updates;
#	    $dbh->upd_account($acct, -$amt);
	    $tot += $amt;

	    if ( $btw ) {
#		my $btw_acct =
#		  $dbh->lookup($acct, qw(Accounts acc_id acc_debcrd)) ? $btw_ink : $btw_verk;
#		warn("update $btw_acct with ".numfmt(-$btw)."\n") if $trace_updates;
#		$dbh->upd_account($btw_acct, -$btw);
		$tot += $btw;
	    }


	}
	elsif ( $type eq "deb" || $type eq "crd" ) {
	    my $debcrd = $type eq "deb" ? 1 : 0;
	    return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
	      unless @$args >= 2;
	    my $dd = parse_date($args->[0], substr($begin, 0, 4));
	    if ( $dd ) {
		shift(@$args);
		return unless $self->in_bky($dd, $begin, $end);
		if ( $does_btw && $dbh->adm("btwbegin") && $dd lt $dbh->adm("btwbegin") ) {
		    warn("?"._T("De boekingsdatum valt in de periode waarover al BTW aangifte is gedaan")."\n");
		    return;
		}
	    }
	    else {
		return "?".__x("Onherkenbare datum: {date}",
			       date => $args->[0])."\n"
		  if ($args->[0]||"") =~ /^[[:digit:]]+-/;
		$dd = $date;
	    }
	    return "?"._T("Deze opdracht is onvolledig. Gebruik de \"help\" opdracht voor meer aanwijzingen.")."\n"
	      unless @$args >= 2;

	    my ($rel, $amt) = splice(@$args, 0, 2);
	    warn(" "._T("boekstuk").": $type $rel $amt\n")
	      if $verbose;

	    my $oamt = $amt;
	    $amt = amount($amt);
	    unless ( defined($amt) ) {
		warn("?".__x("Ongeldig bedrag: {amt}", amt => $oamt)."\n");
		$fail++;
		next;
	    }

	    my ($rr, $sql, @sql_args);
	    if ( $rel =~ /:/ ) {
		$bsr_ref = $rel; # store in db
		my ($id, $bsk, $err) = $dbh->bskid($rel, $bky);
		unless ( defined($id) ) {
		    warn("?$err\n");
		    $fail++;
		    next;
		}
		$sql = "SELECT bsk_nr, bsk_id, dbk_id, dbk_acc_id, bsk_desc, bsk_amount, bsr_rel_code".
		  " FROM Boekstukken, Boekstukregels, Dagboeken" .
		    " WHERE bsk_id = ?".
		      "  AND bsk_dbk_id = dbk_id".
			"  AND bsr_bsk_id = bsk_id".
			  " AND bsr_nr = 1".
			    "  AND dbk_type = ?";
		@sql_args = ( $id, $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP);
		$rr = $dbh->do($sql, @sql_args);
		unless ( defined($rr) ) {
		    # Can this happen???
		    warn("?".__x("Geen post gevonden voor boekstuk {bsk}",
				 bsk => $rel)."\n");
		    $fail++;
		    next;
		}
	    }
	    elsif ( 1 ) {
		# Lookup rel code.
		$rr = $dbh->do("SELECT rel_code FROM Relaties" .
			       " WHERE upper(rel_code) = ?" .
			       "  AND " . ($debcrd ? "" : "NOT ") . "rel_debcrd",
			       uc($rel));
		unless ( defined($rr) ) {
		    warn("?".__x("Onbekende {what}: {who}",
				 what => lc($type eq "deb" ? _T("Debiteur") : _T("Crediteur")),
				 who => $rel)."\n");
		    $fail++;
		    next;
		}
		# Get actual code.
		$rel = $rr->[0];

		# Zoek open posten.
		my $ddd;
		my $delta = $cfg->val(qw(strategy bkm_multi_delta), 0);
		$delta = undef;	# disable for now.
		$ddd = parse_date($dd, substr($begin, 0, 4), $delta) if $delta;
		$sql = "SELECT bsk_open, bsk_nr, bsk_id, dbk_id, dbk_acc_id, bsk_desc, bsk_amount ".
		  " FROM Boekstukken, Boekstukregels, Dagboeken" .
		    " WHERE bsk_open != 0".
			"  AND dbk_type = ?".
			  "  AND bsk_dbk_id = dbk_id".
			    "  AND bsr_bsk_id = bsk_id".
			      "  AND bsr_rel_code = ?".
				" AND bsr_nr = 1".
				  ( $delta ? " AND bsr_date <= ?" : "" ).
				    " ORDER BY bsr_date";
		@sql_args = ( $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP,
			      $rel, $delta ? $ddd : () );

		# Resultset of candidates.
		my $res = [];
		my $sth = $dbh->sql_exec($sql, @sql_args);
		while ( $rr = $sth->fetchrow_arrayref ) {
		    if ( $rr->[0] == $amt ) { # exact match
			$res = [[@$rr]];
			last;
		    }
		    else {
			# Add.
			push(@$res, [@$rr]);
		    }
		}
		$sth->finish;

		my $wmsg;
		if ( @$res == 0 ) {
		    # Nothing.
		    undef $rr;
		}
		elsif ( @$res == 1 && $res->[0]->[0] == $amt ) {
		    # Exact match. Use it.
		    $rr = $res->[0];
		}
		# Knapsack slows down terribly with large search sets. Limit it.
		elsif ( @$res <= $cfg->val(qw(strategy bkm_multi_max), 15) ) {
		    # Use exact knapsack matching to find possible components.
		    my @amts = map { $_->[0] } @$res;
		    if ( my @k = partition($amt, \@amts) ) {
			# We found something. Check strategy.
			if ( $cfg->val(qw(strategy bkm_multi), 0) ) {
			    # We may split.
			    my @t; # for reporting
			    foreach ( @{$k[0]} ) {
				push(@t, numfmt($amts[$_]));
				# Push back the data in the input queue.
				unshift(@$args, $type, $dd, $rel, numfmt_plain($amts[$_]));
			    }
			    # Inform the user.
			    my $t = shift(@t);
			    warn("!".__x("Betaling {rel} {amt} voldoet de open posten {amtss} en {amts}",
					 rel => $rel,
					 amt => numfmt($amt),
					 amtss => join(", ", @t),
					 amts => $t)."\n");
			    next ENTRY;
			}
			else {
			    undef $rr;
			    foreach my $k ( @k ) {
				my @t; # for reporting
				foreach ( @{$k} ) {
				    push(@t, numfmt($amts[$_]));
				}
				my $t = shift(@t);
				$wmsg .= "\n%" if $wmsg;
#				$wmsg .= __x("Wellicht de betaling van de open posten {amtss} en {amts}?",
#					     amtss => join(", ", @t),
#					     amts => $t);
				$wmsg .= _T("Wellicht de betaling van de volgende open posten:");
				foreach ( @{$k} ) {
				    my ($open, $bsknr, $bskid, $dbk_id, $bsk_desc, $bsk_amount) = @{$res->[$_]};
				    $wmsg .= sprintf("\n%% %s %s %s",
						     join(":",
							  $dbh->lookup($dbk_id,
								       qw(Dagboeken dbk_id dbk_desc)),
							  $bsknr), numfmt($open), $bsk_desc);
				}
			    }
			}
		    }
		    # Punt it.
		    else {
			undef $rr;
		    }
		}
		else {
		    $wmsg = __x("Geen alternatieven beschikbaar (teveel open posten)");
		    undef $rr;
		}

		unless ( defined($rr) ) {
		    warn("?".__x("Geen open post van {amt} gevonden voor relatie {rel}",
				 amt => numfmt($amt),
				 rel => $rel)."\n");
		    if ( $wmsg) {
			warn("%".$wmsg."\n");
		    }
		    elsif ( @$res ) {
			warn("%".__x("Open posten voor relatie {rel}:", rel => $rel)."\n");
			foreach ( @$res ) {
			    my ($open, $bsknr, $bskid, $dbk_id, $dbk_acc_id, $bsk_desc, $bsk_amount) = @$_;
			    warn(sprintf("%% %s %s %s\n",
					 join(":",
					      $dbh->lookup($dbk_id,
							   qw(Dagboeken dbk_id dbk_desc)),
					      $bsknr), numfmt($open), $bsk_desc));
			}
		    }
		    $fail++;
		    next;
		}
		$rr = [@$rr, $rel];
		shift(@$rr);
	    }
	    else {
		# Lookup rel code.
		$rr = $dbh->do("SELECT rel_code FROM Relaties" .
			       " WHERE upper(rel_code) = ?" .
			       "  AND " . ($debcrd ? "" : "NOT ") . "rel_debcrd",
			       uc($rel));
		unless ( defined($rr) ) {
		    warn("?".__x("Onbekende {what}: {who}",
				 what => lc($type eq "deb" ? _T("Debiteur") : _T("Crediteur")),
				 who => $rel)."\n");
		    $fail++;
		    next;
		}
		# Get actual code.
		$rel = $rr->[0];

		# Find associated booking.
		$sql = "SELECT bsk_id, dbk_id, dbk_acc_id, bsk_desc, bsk_amount ".
		  " FROM Boekstukken, Boekstukregels, Dagboeken" .
		    " WHERE bsk_open != 0".
		      ($amt ? "  AND bsk_open = ?" : "").
			"  AND dbk_type = ?".
			  "  AND bsk_dbk_id = dbk_id".
			    "  AND bsr_bsk_id = bsk_id".
			      "  AND bsr_rel_code = ?".
				" ORDER BY bsr_date";
		@sql_args = ( $amt ? $amt : (),
			       $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP,
			      $rel);
		$rr = $dbh->do($sql, @sql_args);
		unless ( defined($rr) ) {
		    warn("?".__x("Geen open post van {amt} gevonden voor relatie {rel}",
				amt => numfmt($amt),
				rel => $rel)."\n");
		    $fail++;
		    next;
		}
		$rr = [@$rr, $rel];
	    }

	    my ($bsknr, $bskid, $dbk_id, $dbk_acc_id, $bsk_desc, $bsk_amount, $bsr_rel) = @$rr;
	    #my $acct = $dbh->std_acc($debcrd ? "deb" : "crd");
	    my $acct = $dbk_acc_id;

	    $dbh->sql_insert("Boekstukregels",
			     [qw(bsr_nr bsr_date bsr_bsk_id bsr_desc bsr_amount
				 bsr_btw_id bsr_type bsr_acc_id bsr_btw_class
				 bsr_rel_code bsr_dbk_id bsr_paid bsr_ref)],
			     $nr++, $dd, $bsk_id, "*".$bsk_desc, -$amt, 0,
			     $type eq "deb" ? 1 : 2, $acct, 0, $bsr_rel, $dbk_id,
			     $bskid, $bsr_ref);
	    $dbh->sql_exec("UPDATE Boekstukken".
			   " SET bsk_open = bsk_open - ?".
			   " WHERE bsk_id = ?",
			   $amt, $bskid);

#	    warn("update $acct with ".numfmt(-$amt)."\n") if $trace_updates;
#	    $dbh->upd_account($acct, -$amt);
	    $tot += $amt;
	}
	else {
	    warn("?".__x("Onbekend transactietype: {type}", type => $type)."\n");
	    $fail++;
	    next;
	}
    }

    if ( $gacct ) {
	warn("update $gacct with ".numfmt($tot)."\n") if $trace_updates;
	$dbh->upd_account($gacct, $tot);
#	my $new = $dbh->lookup($gacct, qw(Accounts acc_id acc_balance));
	my $new = $beginsaldo + $tot;
	print(__x("Nieuw saldo: {bal}", bal => numfmt($new)), "\n")
	  if $verbose;
	$dbh->sql_exec("UPDATE Boekstukken".
		       " SET bsk_saldo = ?, bsk_isaldo = ?".
		       " WHERE bsk_id = ?",
		       $new, $beginsaldo, $bsk_id)->finish;
	if ( defined $saldo ) {
	    unless ( $saldo == $new ) {
		warn("?".__x("Saldo {new} klopt niet met de vereiste waarde {act}",
			     new => numfmt($new), act => numfmt($saldo))."\n");
		$fail++;
	    }
	}
	if ( defined($totaal) and $tot != $totaal ) {
	    $fail++;
	    warn("?".__x(" Boekstuk totaal is {act} in plaats van {exp}",
			 act => numfmt($tot), exp => numfmt($totaal)) . "\n");
	}
	my $isaldo = saldo_for($dagboek, $bsk_nr+1, $bky, "isaldo");
	if ( defined($isaldo) and $isaldo != $new ) {
	    $fail++;
	    warn("?".__x("Saldo {new} klopt niet met beginsaldo eropvolgende boekstuk {isaldo}",
			 new => numfmt($new), isaldo => numfmt($isaldo)) . "\n");
	}
    }
    elsif ( $tot ) {
	warn("?".__x("Boekstuk is niet in balans (verschil is {diff})",
		     diff => numfmt($tot))."\n");
	$fail++;
    }
    $dbh->sql_exec("UPDATE Boekstukken SET bsk_amount = ? WHERE bsk_id = ?",
		   $tot, $bsk_id)->finish;

    $dbh->store_journal($self->journalise($bsk_id));

    if ( $opts->{journal} ) {
	warn("?"._T("Dit overzicht is ter referentie, de boeking is niet uitgevoerd!")."\n") if $fail;
	EB::Report::Journal->new->journal
	    ({select => $bsk_id,
	      d_boekjaar => $bky,
	      detail => 1});
    }

    if ( $fail ) {
	warn("?"._T("Boeking ".
		    join(":", ($dbh->lookup($dagboek, qw(Dagboeken dbk_id dbk_desc)), $bsk_nr)).
		    " is niet uitgevoerd!")."\n");
	$dbh->rollback;
	return undef;
    }
    $dbh->commit;

    # TODO -- need this to get a current booking.
    $verbose || 1
      ? join(":", $dbh->lookup($dagboek, qw(Dagboeken dbk_id dbk_desc)), $bsk_nr)
	: "";
}

sub saldo_for {
    my ($dbk, $nr, $bky, $ww) = (@_, "saldo");
    my $sth = $dbh->sql_exec("SELECT bsk_$ww FROM Boekstukken".
			     " WHERE bsk_dbk_id = ? AND bsk_nr = ?".
			     " AND bsk_bky = ?",
			     $dbk, $nr, $bky);
    my $rr = $sth->fetchrow_arrayref;
    $sth->finish;
    if ( $rr && defined($rr->[0]) ) {
	return $rr->[0];
    }
    return;
}

# Adapted from 'Higher Order Perl' (Mark Jason Dominus),
# sec 5.1.1 "Finding All Possible Partitions".

sub partition {
    my ($target, $values, $ix) = @_;
    return [] if $target == 0;

    $ix = [ 0 .. $#{$values} ] unless defined $ix;
    return () if @$ix == 0;

    my ($first, @rest) = @$ix;
    my @solutions = partition($target - $values->[$first], $values, \@rest);
    return ( (map { [ $first, @$_ ] } @solutions),
	     partition($target, $values, \@rest));
}

1;
