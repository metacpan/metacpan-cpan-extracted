#! perl

package main;

our $cfg;
our $dbh;

package EB::Report::Grootboek;

# Author          : Johan Vromans
# Created On      : Wed Jul 27 11:58:52 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jun  7 13:59:31 2012
# Update Count    : 287
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ The Process ################

use EB;
use EB::Booking;		# for dcfromtd()
use EB::Format;
use EB::Report::GenBase;
use EB::Report;

################ Subroutines ################

sub new {
    return bless {};
}

sub perform {
    my ($self, $opts) = @_;

    my $detail = $opts->{detail};
    my $sel = $opts->{select};

    $opts->{STYLE} = "grootboek";
    $opts->{LAYOUT} =
      [ { name => "acct", title => _T("GrBk"),               width =>  5, align => ">" },
	{ name => "desc", title => _T("Grootboek/Boekstuk"), width => 30,              },
	{ name => "date", title => _T("Datum"),              width => $date_width      },
	{ name => "deb",  title => _T("Debet"),              width => $amount_width, align => ">" },
	{ name => "crd",  title => _T("Credit"),             width => $amount_width, align => ">" },
	{ name => "bsk",  title => _T("BoekstukNr"),         width => 14,              },
	{ name => "rel",  title => _T("Relatie"),            width => 10,              },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);
    my $per = $rep->{periode};
    my ($begin, $end) = @$per;

    if ( my $t = $cfg->val(qw(internal now), 0) ) {
	$end = $t if $t lt $end;
    }

    $rep->start(_T("Grootboek"));

    $dbh->begin_work;

    my $table = EB::Report->GetTAccountsAll($begin, $end);

    my $ah = $dbh->sql_exec("SELECT acc_id,acc_desc,acc_ibalance,acc_balres".
			    " FROM ${table}".
			    ($sel ?
			     (" WHERE acc_id IN ($sel)") :
			     (" WHERE acc_ibalance <> 0".
			      " OR acc_id in".
			      "  ( SELECT DISTINCT jnl_acc_id FROM Journal )")).
			      " ORDER BY acc_id");

    my $dgrand = 0;
    my $cgrand = 0;
    my $mdgrand = 0;
    my $mcgrand = 0;
    my $n0 = numfmt(0);

    my $t;
    my $did = 0;

    while ( my $ar = $ah->fetchrow_arrayref ) {
	my ($acc_id, $acc_desc, $acc_ibalance, $acc_balres) = @$ar;

	my $sth = $dbh->sql_exec("SELECT jnl_amount,jnl_damount,jnl_bsk_id,bsk_desc,".
				 "bsk_nr,dbk_desc,dbk_dcsplit,jnl_bsr_date,jnl_desc,jnl_rel".
				 " FROM Journal, Boekstukken, Dagboeken".
				 " WHERE jnl_dbk_id = dbk_id".
				 " AND jnl_bsk_id = bsk_id".
				 " AND jnl_acc_id = ?".
				 " AND jnl_date >= ? AND jnl_date <= ?".
				 " ORDER BY jnl_bsr_date, jnl_bsk_id, jnl_seq",
				 $acc_id, $begin, $end);

	my $rr = $sth->fetchrow_arrayref;
	if ( !$acc_ibalance && !$rr ) {
	    $sth->finish;
	    next;
	}

	$rep->add({ _style => 'h1',
		    acct   => $acc_id,
		    desc   => $acc_desc,
		  }) if $detail;

	my $a = { _style => 'h2', desc   => _T("Beginsaldo") };
	if ( $acc_ibalance ) {
	    if ( $acc_ibalance < 0 ) {
		$a->{crd} = numfmt(-$acc_ibalance);
		$a->{deb} = $n0;
	    }
	    else {
		$a->{crd} = $n0;
		$a->{deb} = numfmt($acc_ibalance);
	    }
	}
	else {
	    $a->{deb} = $a->{crd} = $n0;
	}

	$rep->add($a) if $detail > 0;

	my $dtot = 0;
	my $ctot = 0;
	my $dcsplit;		# any acct was DC split
	while ( $rr ) {
	    my ($amount, $damount, $bsk_id, $bsk_desc, $bsk_nr,
		$dbk_desc, $dbk_dcsplit, $date, $desc, $rel) = @$rr;

	    warn("?Internal error: delta amount while no DC split, acct = $acc_id ($acc_desc)\n")
	      if defined($damount) && !$dbk_dcsplit;
	    $dcsplit ||= $dbk_dcsplit;

	    my ($deb, $crd) = EB::Booking::dcfromtd($amount, $damount);
	    $ctot += $crd if $crd;
	    $dtot += $deb if $deb;
	    $rep->add({ _style => 'd',
			desc   => $desc,
			date   => datefmt($date),
			deb    => numfmt($deb),
			crd    => numfmt($crd),
			bsk    => join(":", $dbk_desc, $bsk_nr),
			$rel ? ( rel => $rel) : (),
		      }) if $detail > 1;
	    $rr = $sth->fetchrow_arrayref;
	}

	$a = { _style => 't2', desc   => _T("Totaal mutaties") };
	if ( $dcsplit ) {
	    $a->{crd} = numfmt($ctot);
	    $a->{deb} = numfmt($dtot);
	    $mdgrand += $dtot if $dtot;
	    $mcgrand += $ctot if $ctot;
	}
	elsif ( $ctot > $dtot ) {
	    $a->{crd} = numfmt($ctot-$dtot);
	    $mcgrand += $ctot - $dtot;
	}
	else {
	    $a->{deb} = numfmt($dtot-$ctot);
	    $mdgrand += $dtot - $ctot;
	}

	$rep->add($a)
	  if $detail && ($dtot || $ctot || $acc_ibalance);

	$rep->add({ _style => 't1',
		    acct   => $acc_id,
		    desc   => __x("Totaal {adesc}", adesc => $acc_desc),
		    $ctot > $dtot + $acc_ibalance ? ( crd => numfmt($ctot-$dtot-$acc_ibalance) )
						  : ( deb => numfmt($dtot+$acc_ibalance-$ctot) ),
		  });
	if ( $ctot > $dtot + $acc_ibalance ) {
	    $cgrand += $ctot - $dtot-$acc_ibalance;
	}
	else {
	    $dgrand += $dtot+$acc_ibalance - $ctot;
	}
	$did++;
    }

    if ( $did ) {
	$rep->add({ _style => 'tm',
		    desc => _T("Totaal mutaties"),
		    deb => numfmt($mdgrand),
		    crd => numfmt($mcgrand),
		  });
	$rep->add({ _style => 'tg',
		    desc   => _T("Totaal"),
		    $cgrand || 1        ? ( crd => numfmt($cgrand) ) : (),
		    $dgrand || !$cgrand ? ( deb => numfmt($dgrand) ) : (),
		   });
    }
    else {
	print("?"._T("Geen informatie gevonden")."\n");
    }

    $rep->finish;
    # Rollback temp table.
    $dbh->rollback;
}

package EB::Report::Grootboek::Text;

use EB;
use base qw(EB::Report::Reporter::Text);

sub new {
    my ($class, $opts) = @_;
    my $self = $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
    $self->{detail} = $opts->{detail};
    return $self;
}

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	_any => {
	#    desc   => { truncate    => 1 },
	},
	h2  => {
	    desc   => { indent      => 1 },
	},
	d  => {
	    desc   => { indent      => 2 },
	},
	t1  => {
	    _style => { skip_after  => ($self->{detail} > 0) },
	},
	t2  => {
	    desc   => { indent      => 1 },
	},
	tm => {
	    _style => { skip_before => 1 },
	},
	tg => {
	    _style => { line_before => 1 }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Grootboek::Html;

use EB;
use base qw(EB::Report::Reporter::Html);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

package EB::Report::Grootboek::Csv;

use EB;
use base qw(EB::Report::Reporter::Csv);
use strict;

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}


1;
