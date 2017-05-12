#! perl

package main;

our $cfg;
our $dbh;

package EB::Report::Balres;

# Author          : Johan Vromans
# Created On      : Sat Jun 11 13:44:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jun  9 22:19:50 2010
# Update Count    : 423
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ The Process ################

use EB;
use EB::Report;
use EB::Format;

################ Subroutines ################

sub new {
    my ($class, $opts) = @_;
    $class = ref($class) || $class;
    $opts = {} unless $opts;
    bless { %$opts }, $class;
}

sub balans {
    my ($self, $opts) = @_;
    $opts->{balans} = 1;
    $self->perform($opts);
}

sub openingsbalans {
    my ($self, $opts) = @_;
    $opts->{balans} = -1;
    $self->perform($opts);
}

sub result {
    my ($self, $opts) = @_;
    $opts->{balans} = 0;
    $self->perform($opts);
}

sub perform {
    my ($self, $opts) = @_;

    my $balans = $opts->{balans};
    my $opening = $opts->{opening};
    my $detail = $opts->{detail};
    $detail = $opts->{verdicht} ? 2 : -1 unless defined $detail;
    $opts->{detail} = $detail;

    my $dtot = 0;
    my $ctot = 0;

    $opts->{STYLE} = $opts->{balans} ? "balans" : "result";
    $opts->{LAYOUT} =
      [ { name => "acct", title => _T("RekNr"), width => 6 },
	{ name => "desc",
	  title => $detail >= 0 ? _T("Verdichting/Grootboekrekening")
				: _T("Grootboekrekening"),
	  width => 40 },
	{ name => "deb", title => _T("Debet"),  width => $amount_width, align => ">" },
	{ name => "crd", title => _T("Credit"), width => $amount_width, align => ">" },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);

    my ($begin, $end) = @{$rep->{periode}};
    my $now = $opts->{per} || $end; #### CHECK: $end is already always $opt->{per}
    if ( my $t = $cfg->val(qw(internal now), 0) ) {
	$now = $t if $t lt $now;
    }
    $now = iso8601date() if $now gt iso8601date();
    $rep->{periodex} = 1 if $rep->{periodex} == 3 && $opts->{balans};

    my $sth;
    my $rr;
    my $table = "Accounts";
    my $need_rollback = 0;
    if ( $balans < 0 ) {
	my $date = $dbh->adm("begin");
	$rep->start(_T("Openingsbalans"),
		    __x("Datum: {date}", date => datefmt_full($now)));
    }
    elsif ( $opening ) {
	my $date = $begin;
	$rep->start(_T("Openingsbalans"),
		    __x("Datum: {date}", date => datefmt_full($date)));
	$dbh->begin_work;
	$need_rollback++;
	$table = EB::Report->GetTAccountsBal($date, 1);
    }
    else {
	$dbh->begin_work;
	$need_rollback++;
	if ( $balans ) {
	    $table = EB::Report->GetTAccountsBal($end);
	}
	elsif ( !$balans ) {
	    $table = EB::Report->GetTAccountsRes($begin, $end);
	}
	$rep->start($balans ? _T("Balans") : _T("Verlies/Winst"));
    }

    my $sql = "SELECT acc_id, acc_desc, acc_balance, acc_ibalance, acc_debcrd, acc_dcfixed".
      " FROM ${table}";
    if ( $balans ) {
	$sql .= " WHERE acc_balres".
	  " AND acc_balance <> 0";
	$sql .= " AND acc_struct = ?" if $detail >= 0;
    }
    else {
	$sql .= ",Journal".
	  " WHERE acc_id = jnl_acc_id".
	    " AND jnl_date >= '$begin' AND jnl_date <= '$end'".
	      " AND NOT acc_balres".
		" AND acc_balance <> acc_ibalance";
	$sql .= " AND acc_struct = ?" if $detail >= 0;
	$sql =~ /SELECT\s+(.*)\s+FROM/;
	$sql .= " GROUP BY $1";
    }
    $sql .= " ORDER BY acc_id";

    if ( $detail >= 0 ) {	# Verdicht
	my @vd;
	my @hvd;
	$sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc".
			      " FROM Verdichtingen".
			      " WHERE".($balans ? "" : " NOT")." vdi_balres".
			      " AND vdi_struct IS NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    $hvd[$rr->[0]] = [ @$rr, []];
	}
	$sth->finish;
	@vd = @hvd;
	$sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc, vdi_struct".
			      " FROM Verdichtingen".
			      " WHERE".($balans ? "" : " NOT")." vdi_balres".
			      " AND vdi_struct IS NOT NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    push(@{$hvd[$rr->[2]]->[2]}, [@$rr]);
	    @vd[$rr->[0]] = [@$rr];
	}
	$sth->finish;

	foreach my $hvd ( @hvd ) {
	    next unless defined $hvd;
	    my $did_hvd = 0;
	    my $dstot = 0;
	    my $cstot = 0;
	    foreach my $vd ( @{$hvd->[2]} ) {
		my $did_vd = 0;
		$sth = $dbh->sql_exec($sql, $vd->[0]);

		my $dsstot = 0;
		my $csstot = 0;
		while ( $rr = $sth->fetchrow_arrayref ) {
		    $rep->add({ _style => 'h1',
			        acct   => $hvd->[0],
			        desc   => $hvd->[1],
			      })
		      unless $detail < 1 || $did_hvd++;
		    $rep->add({ _style => 'h2',
				acct => $vd->[0],
				desc => $vd->[1]
			      })
		      unless $detail < 2 || $did_vd++;
		    my ($acc_id, $acc_desc, $acc_balance, $acc_ibalance,
			$acc_debcrd, $acc_dcfixed) = @$rr;
		    $acc_balance = -$acc_balance if $acc_dcfixed && !$acc_debcrd;
		    if ( $acc_dcfixed ? $acc_debcrd : ($acc_balance >= 0) ) {
			$dsstot += $acc_balance;
			$rep->add({ _style => 'd2',
				    acct   => $acc_id,
				    desc   => $acc_desc,
				    deb    => numfmt($acc_balance),
				   })
			  if $detail >= 2;
		    }
		    else {
			$acc_balance = -$acc_balance unless $acc_dcfixed;
			$csstot += $acc_balance;
			$rep->add({ _style => 'd2',
				    acct   => $acc_id,
				    desc   => $acc_desc,
				    crd    => numfmt($acc_balance),
				  })
			  if $detail >= 2;
		    }
		}
		$sth->finish;
		if ( $detail >= 1 && ($csstot || $dsstot) ) {
		    $rep->add({ _style => 't2',
				acct   => $vd->[0],
				desc   => ($detail > 1 ? __x("Totaal {vrd}", vrd => $vd->[1]) : $vd->[1]),
				$dsstot >= $csstot ? ( deb => numfmt($dsstot-$csstot))
						   : ( crd => numfmt($csstot-$dsstot) ),
			      });
		}
		$cstot += $csstot-$dsstot if $csstot>$dsstot;
		$dstot += $dsstot-$csstot if $dsstot>$csstot;
	    }
	    if ( $detail >= 0  && ($cstot || $dstot) ) {
		$rep->add({ _style => 't1',
			    acct   => $hvd->[0],
			    desc   => ($detail > 0 ? __x("Totaal {vrd}", vrd => $hvd->[1]) : $hvd->[1]),
			    $dstot >= $cstot ? ( deb => numfmt($dstot-$cstot) )
					     : ( crd => numfmt($cstot-$dstot) ),
			  });

	    }
	    $ctot += $cstot-$dstot if $cstot>$dstot;
	    $dtot += $dstot-$cstot if $dstot>$cstot;
	}

    }
    else {			# Op Grootboek
	$sth = $dbh->sql_exec($sql);

	while ( $rr = $sth->fetchrow_arrayref ) {
	    my ($acc_id, $acc_desc, $acc_balance, $acc_ibalance,
		$acc_debcrd, $acc_dcfixed) = @$rr;
#warn("|", join("|", @$rr), "|\n");
	    $acc_balance -= $acc_ibalance unless $opts->{balans};
	    $acc_balance = -$acc_balance if $acc_dcfixed && !$acc_debcrd;
	    if ( $acc_dcfixed ? $acc_debcrd : ($acc_balance >= 0) ) {
		$dtot += $acc_balance;
		$rep->add({ _style => 'd',
			    acct   => $acc_id,
			    desc   => $acc_desc,
			    deb    => numfmt($acc_balance),
			  });
	    }
	    else {
		$acc_balance = -$acc_balance unless $acc_dcfixed;
		$ctot += $acc_balance;
		$rep->add({ _style => 'd',
			    acct   => $acc_id,
			    desc   => $acc_desc,
			    crd    => numfmt($acc_balance),
			  });
	    }
	}
	$sth->finish;
    }

    my ($w, $v) = (_T("Winst"), _T("Verlies"));
    ($w, $v) = ($v, $w) unless $balans;
    if ( $dtot != $ctot ) {
	if ( $dtot >= $ctot ) {
	    $rep->add({ _style => 'v',
			desc   => "<< $w >>",
			crd    => numfmt($dtot - $ctot),
		      });
	    $ctot = $dtot;
	}
	else {
	    $rep->add({ _style => 'v',
			desc   => "<< $v >>",
			deb    => numfmt($ctot - $dtot),
		      });
	    $dtot = $ctot;
	}
    }
    $rep->add({ _style => 'grand',
		desc   => __x("TOTAAL {rep}", rep => $balans ? _T("Balans") : _T("Resultaten")),
		deb    => numfmt($dtot),
		crd    => numfmt($ctot),
	      });
    $rep->finish;

    # Rollback temp table.
    $dbh->rollback if $need_rollback;
}

package EB::Report::Balres::Text;

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
	d2    => {
	    desc   => { indent      => 2 },
	},
	h2    => {
	    desc   => { indent      => 1 },
	},
	t1    => {
	    _style => { skip_after  => (1 <= $self->{detail}) },
	},
	t2    => {
	    _style => { skip_after  => (2 <= $self->{detail}) },
	    desc   => { indent      => 1 },
	},
	grand => {
	    _style => { line_before => 1 }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Balres::Html;

use EB;
use base qw(EB::Report::Reporter::Html);

sub new {
    my ($class, $opts) = @_;
    my $self = $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
    return $self;
}

package EB::Report::Balres::Csv;

use EB;
use base qw(EB::Report::Reporter::Csv);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

1;
