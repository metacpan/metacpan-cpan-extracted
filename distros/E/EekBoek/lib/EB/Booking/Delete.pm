#! perl

package main;

our $dbh;
our $spp;
our $config;

package EB::Booking::Delete;

# Author          : Johan Vromans
# Created On      : Mon Sep 19 22:19:05 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jun  7 13:58:47 2012
# Update Count    : 88
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

use EB;
use base qw(EB::Booking);

sub new {
    return bless {}, shift;
}

sub perform {
    my ($self, $id, $opts) = @_;

    my $sth;
    my $rr;
    my $orig = $id;
    my $bky = $self->{bky} ||= $opts->{boekjaar} || $dbh->adm("bky");
    my ($bsk, $dbsk, $err) = $dbh->bskid($id, $bky);
    die("?$err\n") unless defined $bsk;
    my $does_btw = $dbh->does_btw;

    my ($dd) = @{$dbh->do("SELECT bsk_date".
			  " FROM Boekstukken".
			  " WHERE bsk_id = ?", $bsk)};
    my ($begin, $end);
    return unless ($begin, $end) = $self->begindate;

    return unless $self->in_bky($dd, $begin, $end);
    if ( $does_btw && $dbh->adm("btwbegin") && $dd lt $dbh->adm("btwbegin") ) {
	my $r = $dbh->do("SELECT COUNT(*)".
			 " from Boekstukregels, Boekstukken".
			 " WHERE bsr_bsk_id = bsk_id".
			 " AND bsr_bsk_id = ?".
			 " AND ( bsr_btw_class != 0 OR bsr_btw_id != 0 )".
			 " LIMIT 1",
			 $bsk);
	if ( $r && $r->[0] ) {
	    warn("?"._T("Deze boeking valt in de periode waarover al BTW aangifte is gedaan en kan niet meer worden verwijderd")."\n");
	    return;
	}
    }

    # Check if this boekstuk is used by others. This can only be the
    # case if has been paid.

    my ($amt, $open, $dbk) = @{$dbh->do("SELECT bsk_amount,bsk_open,bsk_dbk_id".
				  " FROM Boekstukken".
				  " WHERE bsk_id = ?", $bsk)};
    if ( defined($open) && $amt != $open ) {
	# It has been paid. Show the user the list of bookstukken.
	$sth = $dbh->sql_exec("SELECT dbk_desc, bsk_nr".
			      " FROM Boekstukken,Boekstukregels,Dagboeken".
			      " WHERE bsk_id = bsr_bsk_id".
			      " AND bsk_dbk_id = dbk_id".
			      " AND bsr_paid = ?", $bsk);
	$rr = $sth->fetchall_arrayref;
	if ( $rr ) {
	    my $t = "";
	    foreach ( @$rr ) {
		$t .= join(":", @$_) . " ";
	    }
	    chomp($t);
	    return "?".__x("Boekstuk {bsk} is in gebruik door {lst}",
			   bsk => $dbsk, lst => $t)."\n";
	}
    }

    # Collect list of affected boekstukken.
    $sth = $dbh->sql_exec("SELECT bsr_paid,bsr_amount".
			  " FROM Boekstukregels".
			  " WHERE bsr_paid IS NOT NULL AND bsr_bsk_id = ?", $bsk);
    $rr = $sth->fetchall_arrayref;
    my @bsk; my @amt;
    if ( $rr ) {
	foreach ( @$rr ) {
	    push(@bsk, $_->[0]);
	    push(@amt, $_->[1]);
	}
    }

    eval {
	$dbh->begin_work;

	# Adjust saldi grootboekrekeningen.
	# Hoewel in veel gevallen niet nodig, is het toch noodzakelijk i.v.m.
	# de saldi van bankrekeningen.
	$sth = $dbh->sql_exec("SELECT jnl_acc_id, jnl_amount".
			      " FROM Journal".
			      " WHERE jnl_bsk_id = ? AND jnl_seq > 0", $bsk);
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    $dbh->upd_account($rr->[0], -$rr->[1]);
	}

	# Delete journal entries.
	$dbh->sql_exec("DELETE FROM Journal".
		       " WHERE jnl_bsk_id = ?", $bsk)->finish;

	# Clear 'paid' info.
	$dbh->sql_exec("UPDATE Boekstukken".
		       " SET bsk_open = bsk_open - ?".
		       " WHERE bsk_id = ?", shift(@amt), $_)->finish
			 foreach @bsk;

	# Delete boekstukregels.
	$dbh->sql_exec("DELETE FROM Boekstukregels".
		       " WHERE bsr_bsk_id = ?", $bsk)->finish;

	# Delete boekstuk.
	$dbh->sql_exec("DELETE FROM Boekstukken".
		       " WHERE bsk_id = ?", $bsk)->finish;

#	# Adjust saldi van boekingen na deze.
#	$dbh->sql_exec("UPDATE Boekstukken".
#		       " SET bsk_saldo = bsk_saldo - ?".
#		       " WHERE bsk_saldo IS NOT NULL AND".
#		       " bsk_dbk_id = ? AND bsk_id > ?",
#		       $amt, $dbk, $bsk)->finish;

	# If we get here, all went okay.
	$dbh->commit;
    };

    if ( $@ ) {
	# It didn't work. Shouldn't happen.
	warn("?".$@);
	$dbh->rollback;
	return "?".__x("Boekstuk {bsk} niet verwijderd",
		       bsk => $dbsk)."\n";
    }

    return __x("Boekstuk {bsk} verwijderd",
	       bsk => $dbsk)."\n";
}

1;
