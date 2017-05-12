#! perl

# Relation.pm -- 
# Author          : Johan Vromans
# Created On      : Thu Jul 14 12:54:08 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan 26 11:04:05 2012
# Update Count    : 118
# Status          : Unknown, Use with caution!

package main;

our $dbh;

package EB::Relation;

use strict;
use warnings;

use EB;

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    bless $self => $class;
    $self->add(@_) if @_;
    $self;
}

sub add {
    my ($self, $code, $desc, $acct, $opts) = @_;
    my $bstate = $opts->{btw};
    my $dbk = $opts->{dagboek};

    if ( defined($bstate) ) {
	$bstate = lc($bstate);
	if ( $bstate =~ /^\d+$/ && $bstate >= 0 && $bstate < @{&BTWTYPES} ) {
	    # Ok.
	}
	elsif ( $bstate eq lc(BTWTYPES->[BTWTYPE_NORMAAL]) ) { $bstate = BTWTYPE_NORMAAL }
	elsif ( $bstate eq lc(BTWTYPES->[BTWTYPE_VERLEGD]) ) { $bstate = BTWTYPE_VERLEGD }
	elsif ( $bstate eq lc(BTWTYPES->[BTWTYPE_INTRA]  ) ) { $bstate = BTWTYPE_INTRA   }
	elsif ( $bstate eq lc(BTWTYPES->[BTWTYPE_EXTRA]  ) ) { $bstate = BTWTYPE_EXTRA   }
	else {
	    warn("?".__x("Ongeldige waarde voor BTW status: {btw}", btw => $bstate)."\n");
	    return;
	}
	if ( $bstate == BTWTYPE_VERLEGD ) {	#### TODO
	    warn("?"._T("Relaties met verlegde BTW worden nog niet ondersteund")."\n");
	    return;
	}
	if ( $bstate == BTWTYPE_INTRA ) { #### TODO
	    warn("!"._T("Relaties met intra-communautaire BTW worden nog niet volledig ondersteund")."\n");
	}
    }
    my $debiteur;
    my $ddesc;
    if ( $dbk ) {
	my $rr = $dbh->do("SELECT dbk_id, dbk_type, dbk_desc".
			       " FROM Dagboeken".
			       " WHERE dbk_desc ILIKE ?",
			  $dbk);
	unless ( $rr ) {
	    warn("?".__x("Onbekend dagboek: {dbk}", dbk => $dbk)."\n");
	    return;
	}
	my ($id, $type, $desc) = @$rr;
	if ( $type == DBKTYPE_INKOOP ) {
	    $debiteur = 0;
	}
	elsif ( $type == DBKTYPE_VERKOOP ) {
	    $debiteur = 1;
	}
	else {
	    warn("?".__x("Ongeldig dagboek voor relatie: {dbk}", dbk => $dbk)."\n");
	    return;
	}
	$dbk = $id;
	$ddesc = $desc;
    }

    # Invoeren nieuwe relatie.

    # Koppeling debiteur/crediteur op basis van debcrd van de
    # bijbehorende grootboekrekening.

    # Koppeling met dagboek op basis van het laagstgenummerde
    # inkoop/verkoop dagboek (tenzij meegegeven).

    my $dbcd = "acc_debcrd";
    if ( $acct =~ /^(\d+)([DC]$)/i) {
	warn("!"._T("Waarschuwing: De toevoeging 'D' of 'C' aan het grootboeknummer wordt afgeraden! Gebruik de --dagboek optie indien nodig.")."\n");
	$acct = $1;
	$dbcd = uc($2) eq 'D' ? 0 : 1; # Note: D -> Crediteur
	if ( defined($debiteur) && $dbcd == $debiteur ) {
	    warn("?".__x("Dagboek {dbk} implicieert {typ1} maar {acct} impliceert {typ2}",
			 dbk => $ddesc,
			 typ1 => lc($debiteur ? _T("Debiteur") : _T("Crediteur")),
			 acct => $acct.$2,
			 typ2 => lc($dbcd ? _T("Crediteur") : _T("Debiteur")))."\n");
	    return;
	}
    }

    my $rr = $dbh->do("SELECT acc_desc,acc_balres,$dbcd".
			" FROM Accounts".
			" WHERE acc_id = ?", $acct);
    unless ( $rr ) {
	warn("?".__x("Onbekende grootboekrekening: {acct}", acct => $acct). "\n");
	return;
    }
    my ($adesc, $balres, $debcrd) = @$rr;
    if ( $balres ) {
	warn("!".__x("Grootboekrekening {acct} ({desc}) is een balansrekening",
		     acct => $acct, desc => $adesc)."\n");
	return;
    }
    $debcrd = defined($debiteur) ? $debiteur : 0+!!$debcrd;

    unless ( $dbk ) {
	my $sth = $dbh->sql_exec("SELECT dbk_id, dbk_desc".
				 " FROM Dagboeken".
				 " WHERE dbk_type = ?".
				 " ORDER BY dbk_id",
				 $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP);
	$rr = $sth->fetchrow_arrayref;
	$sth->finish;
	($dbk, $ddesc) = @$rr;
    }

    $rr = $dbh->do("SELECT COUNT(*)".
		   " FROM Relaties".
		   " WHERE upper(rel_code) = ? AND rel_ledger = ?",
		   uc($code), $dbk);
    if ( $rr->[0]) {
	warn("?".__x("Relatiecode {code} is niet uniek in dagboek {dbk}",
		     code => uc($code), dbk => $ddesc)."\n");
	return;
    }

    $dbh->begin_work;
    $dbh->sql_insert("Relaties",
		       [qw(rel_code rel_desc rel_debcrd rel_btw_status rel_ledger rel_acc_id)],
		       $code, $desc, $debcrd, $bstate || 0, $dbk, $acct);

    $dbh->commit;
    $debcrd
      ? __x("Debiteur {code} -> {acct} ({desc}), dagboek {dbk}",
	    code => $code, acct => $acct, desc => $adesc, dbk => $ddesc)
      : __x("Crediteur {code} -> {acct} ({desc}), dagboek {dbk}",
	    code => $code, acct => $acct, desc => $adesc, dbk => $ddesc);
}

1;
