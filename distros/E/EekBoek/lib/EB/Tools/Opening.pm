#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Tue Aug 30 09:49:11 2005
# Last Modified By: Johan Vromans
# Last Modified On: Fri Aug 31 18:18:52 2012
# Update Count    : 308
# Status          : Unknown, Use with caution!

package main;

our $dbh;
our $config;

package EB::Tools::Opening;

use strict;
use warnings;

use EB;
use EB::Format;

# List of API methods (for the shell).
sub commands {
    [qw(open set_naam set_btwperiode set_begindatum set_balanstotaal
	set_boekjaarcode set_balans set_relatie)];
}

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    bless {}, $class;
}

# Shell methods.
# NOTE: A true result means ERROR!
sub set_naam {
    return shellhelp() unless @_ == 2;
    my ($self, $naam) = @_;
    $self->check_open(0);
    $self->{o}->{naam} = $naam;
    "";
}

sub set_btwperiode {
    return shellhelp() unless @_ == 2;
    my ($self, $per) = @_;
    my $pat = join("|", _T("jaar"), _T("maand"), _T("kwartaal"));
    return __x("Ongeldige BTW periode: {per}", per => $per)."\n"
      unless $per =~ /^$pat|jaar|maand}kwartaal$/i;
    #$self->check_open(0);
    $self->{o}->{btwperiode} = 1 if lc($per) eq _T("jaar") || lc($per) eq "jaar";
    $self->{o}->{btwperiode} = 4 if lc($per) eq _T("kwartaal") || lc($per) eq "kwartaal";
    $self->{o}->{btwperiode} = 12 if lc($per) eq _T("maand") || lc($per) eq "maand";
    ""
}

sub set_begindatum {
    return shellhelp() unless @_ == 2;
    my ($self, $date) = @_;

    if ( $date =~ /^\d{4}$/ ) {
	$date .= "-01-01";
    }
    my $d = parse_date($date);

    my ($jaar) = $d =~ /^(\d{4})/;
    return __x("Ongeldige openingsdatum: {date}", date => $date)."\n" unless $jaar =~ /^\d+$/
      && $jaar >= 1990 && $jaar < 2099;	# TODO
    $self->check_open(0);
    $self->{o}->{begindatum} = $d;
    $d =~ s/^(\d{4})/$1+1/e;
    $self->{o}->{einddatum} = parse_date($d, undef, -1);
    "";
}

sub set_boekjaarcode {
    return shellhelp() unless @_ == 2;
    my ($self, $code) = @_;
    my $t;
    return __x("Ongeldige boekjaar-code: {year}", year => $code)."\n" unless $code =~ /^\w{1,4}$/;
    return __x("Boekjaar-code {year} bestaat al ({desc}",
	       year => $code, desc => $t)."\n"
      if $t = $dbh->lookup($code, qw(Boekjaren bky_code bky_name));
    #$self->check_open(0);
    $self->{o}->{boekjaarcode} = $code;
    "";
}

sub set_balanstotaal {
    return shellhelp() unless @_ == 2;
    my ($self, $amt) = @_;
    my $anew;
    return __x("Ongeldig bedrag: {amount}", amount => $amt)."\n" unless defined($anew = amount($amt));
    $self->check_open(0);
    $self->{o}->{balanstotaal} = $anew;
    "";
}

sub set_balans {
    return shellhelp() unless @_ == 3;
    my ($self, $acct, $amt) = @_;
    my $rr = $dbh->do("SELECT acc_balres, acc_debcrd".
		      " FROM Accounts".
		      " WHERE acc_id = ?", $acct);
    return __x("Onbekende grootboekrekening: {acct}", acct => $acct)."\n"
      unless defined($rr);
    my $balres = $rr->[0];
    return __x("Grootboekrekening {acct} is geen balansrekening", acct => $acct)."\n"
      unless $balres;
    my $debcrd;
    if ( $amt =~ /^(.*)([DC])/ ) {
	$amt = $1;
	$debcrd = $2 eq "D";
    }
    else {
	$debcrd = $rr->[1];
    }
    my $anew;
    return __x("Ongeldig bedrag: {amount}", amount => $amt)."\n" unless defined($anew = amount($amt));
    $self->check_open(0);
    $anew = -$anew unless $debcrd;
    if ( exists($self->{o}->{balans}->{$acct}) ) {
	my $e = $self->{o}->{balans}->{$acct};
	$anew = -$anew if ($e->[0] xor $debcrd);
	$self->{o}->{balans}->{$acct}->[1] += $anew;
    }
    else {
	$self->{o}->{balans}->{$acct} = [ $debcrd, $anew ];
    }
    "";
}

sub set_relatie {

    # adm_relatie verkoop:2000:31 2000-12-30 ACME Cursus 1000
    # adm_relatie 2000-12-31 Cons deb ACME 1000

    return shellhelp() unless @_ == 6;
    my $self = shift;
    my ($date, $desc, $type, $code, $amt);
    my ($dbk, $bky, $nr);

    if ( $_[0] =~ /^(\w+):(\w+):(\d+)$/ ) {
	# adm_relatie verkoop:2000:31 2000-12-30 ACME Cursus 1000
	($dbk, $bky, $nr) = ($1, $2, $3);
	shift;
	($date, $code, $desc, $amt) = @_;
	my $t = $dbh->lookup($dbk, qw(Dagboeken dbk_desc dbk_type ILIKE));
	return __x("Onbekend dagboek: {dbk}", dbk => $dbk)."\n"
	  unless defined($t);
	$type = $t == DBKTYPE_VERKOOP;
    }
    else {
	# adm_relatie 2000-12-31 Cons deb ACME 1000
	($date, $desc, $type, $code, $amt) = @_;
	return _T("Relatietype moet \"deb\" of \"crd\" zijn")."\n"
	  unless $type =~ /^crd|deb$/;
	$type = $type eq "deb";
    }

    my $t = parse_date($date);
    return __x("Ongeldige datum: {date}", date => $date)."\n"
      unless $t;
    $date = $t;
    return __x("Datum {date} valt niet vóór het boekjaar",
	       date => datefmt_full($date))."\n"
      if $self->{o}->{begindatum} && $self->{o}->{begindatum} le $t;
    $bky = substr($date, 0, 4) unless defined $bky;

    my $acct;
    my $sth;
    unless ( defined($dbk) ) {
	$sth = $dbh->sql_exec("SELECT rel_code, rel_ledger".
			      " FROM Relaties".
			      " WHERE UPPER(rel_code) = ?".
			      " AND ".($type ? "" : "NOT ")." rel_debcrd",
			      uc($code));
	my $rr = $sth->fetch;
	return __x("Onbekende relatie: {rel}", rel => $code)."\n"
	  unless defined $rr;
	($code, $dbk) = @$rr;
	$sth->finish;
	$sth = $dbh->sql_exec("SELECT dbk_id, dbk_acc_id".
			      " FROM Dagboeken".
			      " WHERE dbk_id = ?",
			      $dbk);
    }
    else {
	$sth = $dbh->sql_exec("SELECT dbk_id, dbk_acc_id".
			      " FROM Dagboeken".
			      " WHERE UPPER(dbk_desc) = ?",
			      uc($dbk));
    }
    ($dbk, $acct) = @{$sth->fetch};

    my $rr = $dbh->do("SELECT rel_code FROM Relaties" .
		      " WHERE UPPER(rel_code) = ?" .
		      "  AND " . ($type ? "" : "NOT ") . "rel_debcrd" .
		      "  AND rel_ledger = ?",
		      uc($code), $dbk);

    return __x("Onbekende relatie: {rel}", rel => $code)."\n"
      unless defined $rr;

    my $anew;
    return __x("Ongeldig bedrag: {amount}", amount => $amt)."\n" unless defined($anew = amount($amt));

    $self->check_open(0);
    push(@{$self->{o}->{relatie}}, [$bky, $nr, $date, $desc, $type, $code, $acct, $anew]);
    "";
}

# The actual opening process.
sub open {
    if ( $dbh->adm_open ) {
	goto &reopen;
    }

    return shellhelp() unless @_ == 1;
    my ($self) = @_;
    $self->check_open(0);

    my $o = $self->{o};
    my $fail = 0;
    $fail++, warn(_T("De naam van de administratie is nog niet opgegeven")."\n")
      unless $o->{naam};
    $fail++, warn(_T("De begindatum is nog niet opgegeven")."\n")
      unless $o->{begindatum};
    my $does_btw = $dbh->does_btw;

    my $gbj;
    unless ( $gbj = defined($o->{boekjaarcode}) ) {
	warn(__x("Er is geen boekjaarcode opgegeven, de waarde {val} wordt gebruikt",
		 val => $o->{boekjaarcode} = substr($o->{begindatum}, 0, 4))."\n");
	$fail++, warn(__x("Boekjaarcode \"{code}\" is reeds in gebruik",
			  code => $o->{boekjaarcode})."\n")
	  if $dbh->lookup($o->{boekjaarcode}, qw(Boekjaren bky_code bky_name));
    }
    elsif ( $o->{boekjaarcode} !~ /^\w{1,4}$/ ) {
	warn(__x("Ongeldige boekjaarcode: {code}",
		 code => $o->{boekjaarcode})."\n");
	$fail++;
    }

    $fail++, warn(_T("De BTW periode is nog niet opgegeven")."\n")
      if $does_btw && !$o->{btwperiode};
    if ( ($o->{balans} || $o->{relatie}) && !defined($o->{balanstotaal}) ) {
	$fail++;
	warn(_T("Het totaalbedrag van de openingsbalans is nog niet opgegeven")."\n");

    }

    # Generalise for multiple deb/crd accounts.
    my %adeb;
    my %acrd;
    my $sth = $dbh->sql_exec("SELECT dbk_acc_id FROM Dagboeken".
			     " WHERE dbk_type = ?", DBKTYPE_INKOOP);
    while ( my $rr = $sth->fetch ) {
	$acrd{0+$rr->[0]} = 0;
    }
    $sth = $dbh->sql_exec("SELECT dbk_acc_id FROM Dagboeken".
			  " WHERE dbk_type = ?", DBKTYPE_VERKOOP);
    while ( my $rr = $sth->fetch ) {
	$adeb{0+$rr->[0]} = 0;
    }

    $dbh->begin_work;

    if ( defined($o->{balanstotaal}) ) {
	my $adeb;
	my $acrd;
	my $need_rel = 0;
	if ( !$o->{balans} && $o->{openingsbalans} ) {
	    $fail++;
	    warn(_T("De openingsbalans is nog niet opgegeven")."\n");
	}
	else {
	    # Boekhoudkundig rekenen.
	    my $bdebet  = $o->{balanstotaal};
	    my $bcredit = -$bdebet;
	    # Rekenkundig rekenen.
	    my $rcredit = $bcredit;
	    my $rdebet  = $bdebet;
	    while ( my ($acct, $e) = each(%{$o->{balans}}) ) {
		my ($dc, $amt) = @$e;
		# Rekenkundig rekenen.
		if ( $dc ) {
		    $rdebet -= $amt;
		}
		else {
		    $rcredit -= $amt;
		}
		# Boekhoudkundig rekenen.
		if ( $amt >= 0 ) {
		    $bdebet -= $amt;
		}
		else {
		    $bcredit -= $amt;
		}
		$need_rel++, $adeb{$acct} += $amt if defined($adeb{$acct});
		$need_rel++, $acrd{$acct} += $amt if defined($acrd{$acct});
	    }
	    if ( ($rdebet || $rcredit) && ($bdebet || $bcredit) ) {
		$fail++;
		warn(_T("De openingsbalans is niet correct!")."\n");
		warn(__x("Opgegeven balanstotaal = {total}",
			 total => numfmt($o->{balanstotaal}))."\n");
		warn(__x("Rekenkundig residu debet = {rdeb}, credit = {rcrd}",
			 rdeb => numfmt($rdebet),
			 rcrd => numfmt(-$rcredit)).
		     ($rdebet == -$rcredit
		      ? __x(" (balanstotaal {total})", total => numfmt($o->{balanstotaal} - $rdebet))
		      : '')."\n");
		warn(__x("Boekhoudkundig residu debet = {rdeb}, credit = {rcrd}",
			 rdeb => numfmt($bdebet),
			 rcrd => numfmt(-$bcredit)).
		     ($bdebet == -$bcredit
		      ? __x(" (balanstotaal {total})", total => numfmt($o->{balanstotaal} - $bdebet))
		      : '')."\n");
	    }

	    # Helpful hints...
	    $fail++, warn(_T("Er zijn geen openstaande posten opgegeven")."\n")
	      if !$o->{relatie} && $need_rel;
	    $fail++, warn(_T("Er zijn openstaande posten opgegeven, maar geen corresponderende balansposten")."\n")
	      if $o->{relatie} && !$need_rel;

	    # Process relations.
	    foreach my $r ( @{$o->{relatie}} ) {
		my ($bky, $nr, $date, $desc, $debcrd, $code, $acct, $amt) = @$r;

		if ( $debcrd ) {
		    $adeb = $acct;
		    $adeb ||= $dbh->std_acc("deb", $adeb);
		    unless ( defined $adeb ) {
			$adeb = (keys(%adeb))[0] if scalar(keys(%adeb)) == 1;
		    }
		    unless ( defined $adeb ) {
			warn(_T("Deze administratie kent geen koppeling voor verkoopboekingen")."\n");
			$fail++;
			$adeb = 0;
			next;
		    }
		    next unless $adeb;
		    $adeb{$adeb} -= $amt;
		}
		else {
		    $acrd = $acct;
		    $acrd ||= $dbh->std_acc("crd", $acrd);
		    unless ( defined $acrd ) {
			$acrd = (keys(%acrd))[0] if scalar(keys(%acrd)) == 1;
		    }
		    unless ( defined $acrd ) {
			warn(_T("Deze administratie kent geen koppeling voor inkoopboekingen")."\n");
			$fail++;
			$acrd = 0; # defined
			next;
		    }
		    next unless $acrd;
		    $acrd{$acrd} += $amt;
		}

		if ( defined($bky) ) {
		    my $sth = $dbh->sql_exec("SELECT bky_begin, bky_end".
					     " FROM Boekjaren".
					     " WHERE bky_code = ?", $bky);
		    my $rr = $sth->fetchrow_arrayref;
		    $sth->finish;
		    if ( defined($rr) ) {
			my ($begin, $end) = @$rr;
			if ( $date lt $begin || $date gt $end ) {
			    $fail++;
			    warn(_T("Boekingsdatum valt niet binnen het boekjaar")."\n");
			}
		    }
		    else {
			# Add a (pseudo) boekjaar.
			my $t = $o->{begindatum};
			$t .= "-01-01" if length($t) == 4;
			(my $begin = $t) =~ s/^(\d{4})/substr($date,0,4)/e;
			my $end   = parse_date($begin, undef, -1, undef, +1);
			$dbh->sql_insert("Boekjaren",
					 [qw(bky_code bky_name bky_begin bky_end bky_btwperiod bky_opened bky_closed)],
					 $bky, "$begin - $end", $begin, $end, 0, undef, undef);
		    }
		}
		else {
		    $bky = BKY_PREVIOUS;
		}
	    }

	    foreach my $adeb ( keys(%adeb) ) {
		next unless $adeb{$adeb};
		$fail++;
		if ( $adeb{$adeb} >= 0 ) {
		    warn(__x("Er is {amt} te weinig aan openstaande {dc} (rekening {acct}) opgegeven",
			     amt => numfmt($adeb{$adeb}), acct => $adeb,
			     dc => lc(_T("Debiteuren")))."\n");
		}
		else {
		    warn(__x("Er is {amt} te veel aan openstaande {dc} (rekening {acct}) opgegeven",
			     amt => numfmt(-$adeb{$adeb}), acct => $adeb,
			     dc => lc(_T("Debiteuren")))."\n");
		}
	    }

	    foreach my $acrd ( keys(%acrd) ) {
		next unless $acrd{$acrd};
		$fail++;
		if ( $acrd{$acrd} >= 0 ) {
		    warn(__x("Er is {amt} te veel aan openstaande {dc} (rekening {acct}) opgegeven",
			     amt => numfmt($acrd{$acrd}), acct => $acrd,
			     dc => lc(_T("Crediteuren")))."\n");
		}
		else {
		    warn(__x("Er is {amt} te weinig aan openstaande {dc} (rekening {acct}) opgegeven",
			     amt => numfmt(-$acrd{$acrd}), acct => $acrd,
			     dc => lc(_T("Crediteuren")))."\n");
		}
	    }
	}
    }
    if ( $fail ) {
	$dbh->rollback if $dbh->in_transaction;
	return _T("DE OPENING IS NIET UITGEVOERD!")."\n";
    }

    my $now = iso8601date();

    $dbh->sql_insert("Boekjaren",
		     [qw(bky_code bky_name bky_begin bky_end bky_btwperiod bky_opened)],
		     $o->{boekjaarcode}, $o->{naam},
		     $o->{begindatum}, $o->{einddatum},
		     $o->{btwperiode}||0, $now);
    $dbh->sql_exec("UPDATE Metadata".
		   " SET adm_bky = ?, adm_btwbegin = ?",
		   $o->{boekjaarcode},
		   $does_btw ? $o->{begindatum} : undef);
    my $t = parse_date($o->{begindatum}, undef, -1);
    $dbh->sql_exec("UPDATE Boekjaren".
		   " SET bky_closed = ?, bky_end = ?".
		   " WHERE bky_code = ?", $t, $t, BKY_PREVIOUS);

    if ( defined $o->{balanstotaal} ) {
	while ( my ($acct, $e) = each(%{$o->{balans}}) ) {
	    my ($dc, $amt) = @$e;
	    $dbh->sql_exec("UPDATE Accounts".
			   " SET acc_balance = acc_balance + ?,".
			   "     acc_ibalance = acc_ibalance + ?".
			   " WHERE acc_id = ?",
			   $amt, $amt, $acct);
	}
	my $dbk_inkoop;
	my $dbk_verkoop;
	foreach my $r ( @{$o->{relatie}} ) {
	    my ($bky, $nr, $date, $desc, $debcrd, $code, $acct, $amt) = @$r;
	    $nr = $dbh->get_sequence("bsk_nr_0_seq") unless defined $nr;

	    my ($dagboek) = @{$dbh->do("SELECT dbk_id".
				       " FROM Dagboeken".
				       " WHERE dbk_acc_id = ?",
				       $acct)};

	    if ( $debcrd ) {
#		unless ( $dbk_verkoop ) {
#		    ($dbk_verkoop) = @{$dbh->do("SELECT dbk_id FROM Dagboeken".
#						" WHERE dbk_type = ?",
#						DBKTYPE_VERKOOP)};
#		}
#		$dagboek = $dbk_verkoop;
	    }
	    else {
#		unless ( $dbk_inkoop ) {
#		    ($dbk_inkoop) = @{$dbh->do("SELECT dbk_id FROM Dagboeken".
#					       " WHERE dbk_type = ?",
#					       DBKTYPE_INKOOP)};
#		}
#		$dagboek = $dbk_inkoop;
		$amt = -$amt;
	    }

	    my $bsk_id = $dbh->get_sequence("boekstukken_bsk_id_seq");
	    $dbh->sql_insert("Boekstukken",
			     [qw(bsk_id bsk_nr bsk_desc bsk_dbk_id bsk_date bsk_bky bsk_open bsk_amount)],
			     $bsk_id, $nr, $desc, $dagboek, $date, $bky, $amt, $amt);
	    $dbh->sql_insert("Boekstukregels",
			     [qw(bsr_nr bsr_date bsr_bsk_id bsr_desc bsr_rel_code bsr_amount
				 bsr_dbk_id bsr_type bsr_btw_class)],
			     1, $date, $bsk_id,
			     $desc, $code, 0-$amt, $dagboek, 9, 0);
	}
#	my $highest = $dbh->get_sequence("bsk_nr_0_seq") + 1;
#	$dbh->set_sequence("bsk_nr_${dbk_inkoop}_seq", $highest)
#	  if $dbk_inkoop;
#	$dbh->set_sequence("bsk_nr_${dbk_verkoop}_seq", $highest)
#	  if $dbk_verkoop;
    }
    $dbh->commit;
    delete($self->{o});
    $dbh->adm("");		# flush cache

    require EB::Report::Balres;
    my $opts = { verbose      => $self->{verbose},
		 per	      => $dbh->adm("begin"),
	       };

    EB::Report::Balres->new->openingsbalans($opts);
    undef;

}

# A new bookyear.
sub reopen {
    return shellhelp() unless @_ == 1;
    my ($self) = @_;
    $self->check_open(1);

    my $o = $self->{o};
    my $fail = 0;

    # New begin date is old + one year.
    my $y = parse_date($dbh->adm("end"), undef, 1);

    # Avoid opening a new book year too soon.
    if ( $y gt parse_date(iso8601date(), undef, 0, 6) ) {
	warn(__x("Begindatum {year} komt in de toekomst te liggen",
		 year => $y)."\n");
	$fail++;
    }

    $o->{begindatum} = $y;
    $y =~ s/^(\d{4})/$1+1/e;
    $o->{einddatum} = parse_date($y, undef, -1);

    warn(_T("Er is geen nieuwe BTW periode opgegeven, deze blijft ongewijzigd")."\n")
      if $dbh->does_btw && !$o->{btwperiode};

    if ( !defined($o->{boekjaarcode}) ) {
	warn(__x("Er is geen boekjaarcode opgegeven, de waarde {val} wordt gebruikt",
		val => $o->{boekjaarcode} = substr($o->{begindatum}, 0, 4))."\n");
    }
    return _T("HET NIEUWE BOEKJAAR IS NIET GEOPEND!")."\n" if $fail;

    my $now = iso8601date();

    $dbh->begin_work;

    $dbh->sql_insert("Boekjaren",
		     [qw(bky_code bky_name bky_begin bky_end bky_btwperiod bky_opened)],
		     $o->{boekjaarcode},
		     defined $o->{naam} ? $o->{naam} : $dbh->adm("name"),
		     $o->{begindatum}, $o->{einddatum},
		     defined $o->{btwperiode} ? $o->{btwperiode} : $dbh->adm("btwperiod"),
		     $now);

    $dbh->adm("bky", $o->{boekjaarcode}, "use_existing_transaction");
    $dbh->adm("");		# flush cache

    # Reset boekstuknummer sequences.
    my $sth = $dbh->sql_exec("SELECT dbk_id FROM Dagboeken");
    my $max = 1;
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my $t = $dbh->get_sequence("bsk_nr_".$rr->[0]."_seq");
	$dbh->set_sequence("bsk_nr_".$rr->[0]."_seq", 1);
	$max = $t if $t > $max;
    }
    # Sequence for bookings prev period.
    $dbh->set_sequence("bsk_nr_0_seq", $max);

    $dbh->commit;
    delete($self->{o});

    undef;
}

sub shellhelp {
    my ($self, $cmd) = @_;
    _T( <<EOS );
Het openen van een administratie kan slechts éénmaal gebeuren, vóór
het invoeren van de eerste mutatie. Het openen van een nieuw boekjaar
kan te allen tijde worden uitgevoerd, uiteraard maar één keer per
boekjaar.

Het openen kan een aantal opdrachten omvatten, en wordt afgesloten met
de opdracht "adm_open". Zolang deze laatste opdracht niet is gegeven
blijft de administratie ongewijzigd. Alle benodigde opdrachten moeten
dan ook in één enkele EekBoek shell sessie worden afgehandeld.

Mogelijke opdrachten voor openen van een boekjaar:

  adm_btwperiode [ jaar | kwartaal | maand ]
  adm_boekjaarcode <code>
		Een code van max 4 letters en/of cijfers waarmee het
		boekjaar kan worden geïdentificeerd.
		Standaard wordt het jaartal van het boekjaar genomen.
  adm_open
		Alle informatie die met de bovenstaande opdrachten is
		ingevoerd, wordt verwerkt.

Opdrachten voor het openen van een administratie:

  adm_naam "Naam van de administratie"
  adm_btwperiode [ jaar | kwartaal | maand ]
  adm_begindatum <jaar>
		Een administratie loopt altijd van 1 januari tot en
		met 31 december van een kalenderjaar.
  adm_boekjaarcode <code>
		Een code van max 4 letters en/of cijfers waarmee het
		boekjaar kan worden geïdentificeerd.
		Standaard wordt het jaartal van het boekjaar genomen.
		De boekjaarcode is alleen relevant indien er meerdere
		boekjaren in één administratie worden bijgehouden.
  adm_balanstotaal <bedrag>
		Als een balanstotaal is opgegeven, moeten er ook
		openingsbalansboekingen worden uitgevoerd met een of
		meer adm_balans opdrachten.
  adm_balans <balansrekening> <bedrag>
		De debet en credit boekingen moeten uiteindelijk
		allebei gelijk zijn aan het opgegeven balanstotaal.
		Indien er een bedrag is opgegeven voor de balansrekening
		Crediteuren of Debiteuren, dan moet er voor dit bedrag
		ook openstaande posten worden ingevoerd met een of
		meer adm_relatie opdrachten.
  adm_relatie <boekstuk> <datum> <code> <omschrijving> <bedrag>
		Invoeren van een openstaande post uit het voorgaande
		boekjaar. Het <boekstuk> moet volledig zijn, dus
		<dagboek>:<boekjaar>:<nummer>.
  adm_open
		Alle informatie die met de bovenstaande opdrachten is
		ingevoerd, wordt verwerkt.
EOS
}

sub help_btwperiode {
    _T( <<EOS );
Specifeer de BTW aangifteperiode voor het nieuw te openen jaar.

  adm_btwperiode [ jaar | kwartaal | maand ]

Deze opdracht kan worden gebruikt bij het openen van een boekjaar.
Zie "help adm_open" voor meer informatie.
EOS
}

sub help_boekjaarcode {
    _T( <<EOS );
Specificeert de boekjaarcode voor het nieuw te openen jaar.

  adm_boekjaarcode <code>

De boekjaarcode telt maximaal 4 letters en/of cijfers.
Standaard wordt het jaartal van het te openen boekjaar genomen.
De boekjaarcode is alleen belangrijk indien er meerdere boekjaren in één
administratie worden bijgehouden.

Deze opdracht kan worden gebruikt bij het openen van een boekjaar.
Zie "help adm_open" voor meer informatie.
EOS
}

sub help_naam {
    _T( <<EOS );
Specificeert de naam van de administratie, te gebruiken voor rapportages.

  adm_naam "Naam van de administratie"

Deze opdracht kan alleen worden gebruikt bij het openen van een nieuwe
administratie. Zie "help adm_open" voor meer informatie.
EOS
}

sub help_begindatum {
    _T( <<EOS );
Specificeert de begindatum van de administratie.
Een administratie loopt altijd van 1 januari tot en met 31 december
van een kalenderjaar. Daarom moet als begindatum een jaartal worden
opgegeven.

  adm_begindatum <jaar>

Deze opdracht kan alleen worden gebruikt bij het openen van een nieuwe
administratie. Zie "help adm_open" voor meer informatie.
EOS
}

sub help_balanstotaal {
    _T( <<EOS );
Specificeert het balanstotaal voor de in te voeren openingbalans.

  adm_balanstotaal <bedrag>

Het balanstotaal is de zowel de som van alle debet-posten als de som
van alle credit-posten van de openingsbalans. Als een balanstotaal is
opgegeven, moeten er ook openingsbalansboekingen worden uitgevoerd met
een of meer adm_balans opdrachten. Zie ook "help adm_balans".

Deze opdracht kan alleen worden gebruikt bij het openen van een nieuwe
administratie. Zie "help adm_open" voor meer informatie.
EOS
}

sub help_balans {
    _T( <<EOS );
Specificeert een balanspost voor de openingsbalans.

  adm_balans <balansrekening> <bedrag>

De debet en credit boekingen moeten uiteindelijk allebei gelijk zijn
aan het opgegeven balanstotaal.

Indien er een bedrag is opgegeven voor de balansrekening Crediteuren
of voor Debiteuren, dan moeten er ook openstaande posten voor in
totaal dit bedrag worden ingevoerd met een of meer adm_relatie
opdrachten. Zie ook "help adm_relatie".

Deze opdracht kan alleen worden gebruikt bij het openen van een nieuwe
administratie. Zie "help adm_open" voor meer informatie.
EOS
}

sub help_relatie {
    _T( <<EOS );
Specificeert een openstaande post uit een voorgaand boekjaar.

  adm_relatie <boekstuk> <datum> <code> <omschrijving> <bedrag>

Het <boekstuk> moet volledig zijn, dus <dagboek>:<boekjaar>:<nummer>.

Indien er voor de openingsbalans een bedrag is opgegeven voor de
balansrekening Crediteuren of voor Debiteuren, dan moeten er ook
openstaande posten voor in totaal dit bedrag worden ingevoerd. Zie ook
"help adm_balans".

Deze opdracht kan alleen worden gebruikt bij het openen van een nieuwe
administratie. Zie "help adm_open" voor meer informatie.
EOS
}

sub check_open {
    my ($self, $open) = @_;
    $open = 1 unless defined($open);
    if ( $open && !$dbh->adm_open ) {
	die("?"._T("De administratie is nog niet geopend")."\n");
    }
    elsif ( !$open && $dbh->adm_open ) {
	die("?"._T("De administratie is reeds in gebruik")."\n");
    }
    1;
}

1;
