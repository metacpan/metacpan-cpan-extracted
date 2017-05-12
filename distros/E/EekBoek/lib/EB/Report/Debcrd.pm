#! perl

package main;

our $cfg;
our $dbh;

package EB::Report::Debcrd;

# Author          : Johan Vromans
# Created On      : Wed Dec 28 16:08:10 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jun 24 22:23:55 2012
# Update Count    : 188
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ The Process ################

use EB;
use EB::Format;
use EB::Report::GenBase;

################ Subroutines ################

sub new {
    return bless {};
}

sub debiteuren {
    my ($self, $args, $opts) = @_;
    $self->_perform($args, $opts, 1);
}

sub crediteuren {
    my ($self, $args, $opts) = @_;
    $self->_perform($args, $opts, 0);
}

sub _perform {
    my ($self, $args, $opts, $debcrd) = @_;

    if ( $args ) {
	$args = join("|", map { quotemeta($_) } @$args);
    }

    $opts->{STYLE} = "debrept";
    $opts->{LAYOUT} =
      [ { name  => "debcrd",
	  title => $debcrd ? _T("Debiteur") : _T("Crediteur"),
	  width => 10 },
	{ name  => "date",   title => _T("Datum"),        width => $date_width },
	{ name  => "desc",   title => _T("Omschrijving"), width => 25 },
	{ name  => "amount", title => _T("Bedrag"),       width => $amount_width, align => ">" },
	{ name  => "open",   title => _T("Open"),         width => $amount_width, align => ">" },
	{ name  => "paid",   title => _T("Betaald"),      width => $amount_width, align => ">" },
	{ name  => "bsknr",  title => _T("Boekstuk"),     width => 18 },
      ];

    my $rep = EB::Report::GenBase->backend($self, { %$opts, debcrd => $debcrd });

    my %rels;
    my $sth;

    $sth = $dbh->sql_exec("SELECT DISTINCT bsr_rel_code".
			  " FROM Boekstukregels, Boekstukken, Dagboeken".
			  " WHERE bsr_date >= ? AND bsr_date <= ?".
			  " AND bsr_bsk_id = bsk_id".
			  " AND bsk_dbk_id = dbk_id".
			  " AND dbk_type = ?",
			  @{$rep->{periode}},
			  $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP);
    while ( my $rr = $sth->fetchrow_arrayref ) {
	next if $args && $rr->[0] !~ /^$args$/i;
	$rels{$rr->[0]} = undef;
    }
    $sth->finish;

    $sth = $dbh->sql_exec("SELECT bsr_rel_code, bsr_paid".
			  " FROM Boekstukregels, Boekstukken".
			  " WHERE bsr_paid = bsk_id".
			  " AND bsr_date >= ? AND bsr_date <= ?".
			  " AND bsk_date < ?".
			  " AND bsr_type = ?",
			  @{$rep->{periode}},
			  $rep->{per_begin},
			  $debcrd ? DBKTYPE_INKOOP : DBKTYPE_VERKOOP);

    while ( my $rr = $sth->fetchrow_arrayref ) {
	next if $args && $rr->[0] !~ /^$args$/i;
	$rels{$rr->[0]}->{$rr->[1]} = 1;
    }
    $sth->finish;
    return "!"._T("Geen boekingen gevonden") unless %rels;

    $rep->start($debcrd ? _T("Debiteurenadministratie")
	                : _T("Crediteurenadministratie"));

    my $a_grand = 0;
    my $o_grand = 0;

    foreach my $rel ( sort(keys(%rels)) ) {

	my $a_tot = 0;
	my $o_tot = 0;
	my @rp = ();

	push(@rp, { debcrd => $rel, _style=> "h1" });

	my $sth;

	# Process betalingen zonder boekstuk.

	if ( $rels{$rel} ) {
	    foreach my $bsk_id ( keys %{$rels{$rel}} ) {

		my $sth;
		$sth = $dbh->sql_exec("SELECT bsk_id, bsk_desc, bsk_date,".
				      " bsk_amount, bsk_open, dbk_desc, bsk_nr, bsk_bky".
				      " FROM Boekstukken, Boekstukregels, Dagboeken".
				      " WHERE bsk_id = ?".
				      " AND bsk_dbk_id = dbk_id".
				      " AND bsr_bsk_id = bsk_id",
				      $bsk_id);

		my $rr = $sth->fetchrow_arrayref;
		$sth->finish;
		my ($bsk_id, $bsk_desc, $bsk_date,
		    $bsr_amount, $bsr_open, $dbk_desc, $bsk_nr, $bsk_bky) = @$rr;

		# Correct for future payments.
		my $rop = $dbh->do("SELECT sum(bsr_amount)".
				   " FROM Boekstukregels".
				   " WHERE bsr_type = ?".
				   " AND bsr_date > ?".
				   " AND bsr_paid = ?",
				   $debcrd ? 1 : 2, $rep->{per_end}, $bsk_id);

		if ( $rop && $rop->[0] ) {
		    $bsr_open -= $rop->[0];
		}

		$bsr_amount = 0-$bsr_amount unless $debcrd;
		$bsr_open   = 0-$bsr_open   unless $debcrd;
		$a_tot += $bsr_amount;
		$o_tot += $bsr_open;

		push(@rp, { desc   => $bsk_desc,
			    date   => datefmt($bsk_date),
			    amount => numfmt($bsr_amount),
			    open   => numfmt($bsr_open),
			    bsknr  => join(":", $dbk_desc, $bsk_bky, $bsk_nr),
			    _style => "bskprv",
			  });

		$sth = $dbh->sql_exec("SELECT bsr_date, bsr_desc, bsr_amount,".
				      " dbk_desc, bsk_nr".
				      " FROM Boekstukregels, Boekstukken, Dagboeken".
				      " WHERE bsr_type = ?".
				      " AND bsr_date >= ? AND bsr_date <= ?".
				      " AND bsr_paid = ?".
				      " AND bsr_bsk_id = bsk_id AND bsk_dbk_id = dbk_id".
				      " ORDER BY bsr_date, bsk_nr",
				      $debcrd ? 1 : 2, @{$rep->{periode}}, $bsk_id);
		while ( my $rr = $sth->fetchrow_arrayref ) {
		    my ($x_bsr_date, $x_bsr_desc, $x_bsr_amount,
			$x_dbk_desc, $x_bsk_nr, $x_bsk_bky) = @$rr;
		    $x_bsr_amount = 0-$x_bsr_amount unless $debcrd;
		    push(@rp, { desc    => $x_bsr_desc,
				date    => datefmt($x_bsr_date),
				paid    => numfmt(0-$x_bsr_amount),
				bsknr   => join(":", $x_dbk_desc, $x_bsk_nr),
				_style  => "paid",
			      });
		}


	    }
	}

	# Process boekstukken met evt. betalingen.

	$sth = $dbh->sql_exec("SELECT bsk_id, bsk_desc, bsk_date,".
			      " bsk_amount, bsk_open, dbk_desc, bsk_nr".
			      " FROM Boekstukken, Boekstukregels, Dagboeken".
			      " WHERE bsr_date >= ? AND bsr_date <= ?".
			      " AND bsr_bsk_id = bsk_id".
			      " AND bsk_dbk_id = dbk_id".
			      " AND bsr_type = 0".
			      " AND bsr_nr = 1".
			      " AND bsr_rel_code = ?".
			      " AND dbk_type = ?".
			      " ORDER BY bsk_date, bsk_nr",
			      @{$rep->{periode}},
			      $rel,
			      $debcrd ? DBKTYPE_VERKOOP : DBKTYPE_INKOOP);

	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($bsk_id, $bsk_desc, $bsk_date,
		$bsr_amount, $bsr_open, $dbk_desc, $bsk_nr) = @$rr;

	    # Correct for future payments.
	    my $rop = $dbh->do("SELECT sum(bsr_amount)".
				     " FROM Boekstukregels".
				     " WHERE bsr_type = ?".
				     " AND bsr_date > ?".
				     " AND bsr_paid = ?",
				     $debcrd ? 1 : 2, $rep->{per_end}, $bsk_id);

	    if ( $rop && $rop->[0] ) {
		$bsr_open -= $rop->[0];
	    }

	    next if $opts->{openstaand} && $bsr_open == 0;

	    $bsr_amount = 0-$bsr_amount unless $debcrd;
	    $bsr_open   = 0-$bsr_open   unless $debcrd;
	    $a_tot += $bsr_amount;
	    $o_tot += $bsr_open;

	    push(@rp, { desc   => $bsk_desc,
			date   => datefmt($bsk_date),
			amount => numfmt($bsr_amount),
			open   => numfmt($bsr_open),
			bsknr  => join(":", $dbk_desc, $bsk_nr),
			_style => "bsk",
		      });

	    my $sth = $dbh->sql_exec("SELECT bsr_date, bsr_desc, bsr_amount,".
				     " dbk_desc, bsk_nr".
				     " FROM Boekstukregels, Boekstukken, Dagboeken".
				     " WHERE bsr_type = ?".
				     " AND bsr_date >= ? AND bsr_date <= ?".
				     " AND bsr_paid = ?".
				     " AND bsr_bsk_id = bsk_id AND bsk_dbk_id = dbk_id".
				     " ORDER BY bsr_date, bsk_nr",
				     $debcrd ? 1 : 2, @{$rep->{periode}}, $bsk_id);
	    while ( my $rr = $sth->fetchrow_arrayref ) {
		my ($x_bsr_date, $x_bsr_desc, $x_bsr_amount,
		    $x_dbk_desc, $x_bsk_nr) = @$rr;
		$x_bsr_amount = 0-$x_bsr_amount unless $debcrd;
		push(@rp, { desc    => $x_bsr_desc,
			    date    => datefmt($x_bsr_date),
			    paid    => numfmt(0-$x_bsr_amount),
			    bsknr   => join(":", $x_dbk_desc, $x_bsk_nr),
			    _style  => "paid",
			  });
	    }
	}

	push(@rp, { debcrd => $rel,
		    desc   => _T("Totaal"),
		    amount => numfmt($a_tot),
		    open   => numfmt($o_tot),
		    _style => "total",
		  });

	$a_grand += $a_tot;
	$o_grand += $o_tot;

	next if $opts->{openstaand} && $o_tot == 0;
	$rep->add($_) foreach @rp;

    }

    $rep->add({ debcrd => _T("Totaal"),
		amount => numfmt($a_grand),
		open   => numfmt($o_grand),
		_style => "grand",
	      });

    $rep->finish;
    return;
}

package EB::Report::Debcrd::Text;

use EB;
use base qw(EB::Report::Reporter::Text);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	paid  => {
	    desc   => { indent      => 2 },
	},
	total => {
	    _style => { skip_after  => 1 },
	    amount => { line_before => 1 },
	    open   => { line_before => 1 },
	},
	grand => {
	    _style => { line_before => 1 }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Debcrd::Html;

use EB;
use base qw(EB::Report::Reporter::Html);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

package EB::Report::Debcrd::Csv;

use EB;
use base qw(EB::Report::Reporter::Csv);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

1;
