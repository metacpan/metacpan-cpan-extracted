#! perl

package main;

our $cfg;
our $dbh;

package EB::Report::Proof;

# Author          : Johan Vromans
# Created On      : Sat Jun 11 13:44:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:39:09 2010
# Update Count    : 306
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ The Process ################

use EB;
use EB::Format;
use EB::Report;

################ Subroutines ################

sub new {
    my ($class, $opts) = @_;
    $class = ref($class) || $class;
    $opts = {} unless $opts;
    bless { %$opts }, $class;
}

sub proefensaldibalans {
    my ($self, $opts) = @_;
    $self->perform($opts);
}

sub perform {
    my ($self, $opts) = @_;

    my $detail = $opts->{detail};
    $detail = $opts->{verdicht} ? 2 : -1 unless defined $detail;
    $opts->{proef} = 1;
    $opts->{detail} = $detail;

    my @grand = (0) x 4;	# grand total

    $opts->{STYLE} = "proef";
    $opts->{LAYOUT} =
      [ { name => "acct", title => _T("RekNr"),    width => 6, },
	{ name => "desc",
	  title => $detail >= 0 ? _T("Verdichting/Grootboekrekening")
				: _T("Grootboekrekening"),
	  width => 40, },
	{ name => "deb",  title => _T("Debet"),    width => $amount_width, align => ">", },
	{ name => "crd",  title => _T("Credit"),   width => $amount_width, align => ">", },
	{ name => "sdeb", title => _T("Saldo Db"), width => $amount_width, align => ">" },
	{ name => "scrd", title => _T("Saldo Cr"), width => $amount_width, align => ">" },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);

    my $rr;
    $rep->{periodex} = 1;
    my ($begin, $end) = @{$rep->{periode}};
    $dbh->begin_work;
    my $table = EB::Report->GetTAccountsAll($begin, $end);

    $rep->start(_T("Proef- en Saldibalans"));

    my $sth;

    my $hvd_hdr;
    my $vd_hdr;

    my $journaal = sub {
	my ($acc_id, $acc_desc, $acc_ibalance) = @_;
	my @tot = (0) x 4;
	my $did = 0;
	if ( $acc_ibalance ) {
	    $did++;
	    if ( $acc_ibalance < 0 ) {
		$tot[1] = -$acc_ibalance;
	    }
	    else {
		$tot[0] = $acc_ibalance;
	    }
	    # $rep->addline('D2', '', _T("Beginsaldo"), @tot);
	}
	my $sth = $dbh->sql_exec
	  ("SELECT jnl_amount,jnl_desc".
	   " FROM Journal".
	   " WHERE jnl_acc_id = ?".
	   " AND jnl_date >= ? AND jnl_date <= ?".
	   " ORDER BY jnl_bsr_date",
	   $acc_id, $begin, $end,
	  );
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($amount, $desc) = @$rr;
	    $did++;
	    my @t = (0) x 4;
	    $t[$amount<0] += abs($amount);
	    # $rep->addline('D2', '', $desc, @t);
	    $tot[$_] += $t[$_] foreach 0..$#tot;
	}
	if ( $tot[0] >= $tot[1] ) {
	    $tot[2] = $tot[0] - $tot[1]; $tot[3] = 0;
	}
	else {
	    $tot[3] = $tot[1] - $tot[0]; $tot[2] = 0;
	}
	$tot[0] ||= "00" if $did;
	$tot[1] ||= "00" if $did;
	@tot;
    };
    my $grootboeken = sub {
	my ($vd, $hvd) = shift;
	my @tot = (0) x 4;
	my $sth = $dbh->sql_exec
	  ("SELECT acc_id, acc_desc, acc_balance, acc_ibalance".
	   " FROM ${table}".
	   " WHERE acc_struct = ?".
	   " AND ( acc_ibalance <> 0".
	   "       OR acc_id IN ( SELECT DISTINCT jnl_acc_id FROM Journal".
	   "                      WHERE jnl_date >= ? AND jnl_date <= ? ))".
	   " ORDER BY acc_id",
	   $vd->[0], $begin, $end);
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($acc_id, $acc_desc, $acc_balance, $acc_ibalance) = @$rr;
	    my @t = $journaal->($acc_id, $acc_desc, $acc_ibalance);
	    next if "@t" eq "0 0 0 0";
	    $tot[$_] += $t[$_] foreach 0..$#tot;
	    next unless $detail > 1;

	    if ( $hvd_hdr ) {
		$rep->add({ acct => $hvd_hdr->[0],
			    desc => $hvd_hdr->[1],
			    _style => 'h1',
			  });
		undef $hvd_hdr;
	    }
	    if ( $vd_hdr ) {
		$rep->add({ acct => $vd_hdr->[0],
			    desc => $vd_hdr->[1],
			    _style => 'h2',
			  });
		undef $vd_hdr;
	    }
	    $rep->add({ _style => 'd2',
			acct => $acc_id,
			desc => $acc_desc,
			deb  => numfmt($t[0]),
			crd  => numfmt($t[1]),
			$t[2] ? ( sdeb => numfmt($t[2]) ) : (),
			$t[3] ? ( scrd => numfmt($t[3]) ) : (),
		      });
	}
	if ( $tot[0] >= $tot[1] ) {
	    $tot[2] = $tot[0] - $tot[1]; $tot[3] = 0;
	}
	else {
	    $tot[3] = $tot[1] - $tot[0]; $tot[2] = 0;
	}
	@tot;
    };
    my $verdichtingen = sub {
	my ($hvd) = shift;
	my @tot = (0) x 4;
	my $did = 0;
	foreach my $vd ( @{$hvd->[2]} ) {
	    next unless defined $vd;
	    $vd_hdr = [ $vd->[0], $vd->[1] ];
	    my @t = $grootboeken->($vd, $hvd);
	    next if "@t" eq "0 0 0 0";
	    $tot[$_] += $t[$_] foreach 0..$#tot;
	    next unless $detail > 0;
	    if ( $hvd_hdr ) {
		$rep->add({ acct => $hvd_hdr->[0],
			    desc => $hvd_hdr->[1],
			    _style => 'h1',
			  });
		undef $hvd_hdr;
	    }
	    $rep->add({ _style => 't2',
			acct => $vd->[0],
			desc => __x("Totaal {vrd}", vrd => $vd->[1]),
			$t[0] ? ( deb  => numfmt($t[0]) ) : (),
			$t[1] ? ( crd  => numfmt($t[1]) ) : (),
			$t[2] ? ( sdeb => numfmt($t[2]) ) : (),
			$t[3] ? ( scrd => numfmt($t[3]) ) : (),
		      });
	}
	if ( $tot[0] >= $tot[1] ) {
	    $tot[2] = $tot[0] - $tot[1]; $tot[3] = 0;
	}
	else {
	    $tot[3] = $tot[1] - $tot[0]; $tot[2] = 0;
	}
	@tot;
    };
    my $hoofdverdichtingen = sub {
	my (@hvd) = @_;
	my @tot = (0) x 4;
	foreach my $hvd ( @hvd ) {
	    next unless defined $hvd;
	    $hvd_hdr = [ $hvd->[0], $hvd->[1] ];
	    my @t = $verdichtingen->($hvd);
	    next if "@t" eq "0 0 0 0";
	    if ( $detail && $hvd_hdr ) {
		$rep->add({ acct => $hvd_hdr->[0],
			    desc => $hvd_hdr->[1],
			    _style => 'h1',
			  });
		undef $hvd_hdr;
	    }
	    $rep->add({ _style => 't1',
			acct => $hvd->[0],
			desc => __x("Totaal {vrd}", vrd => $hvd->[1]),
			$t[0] ? ( deb  => numfmt($t[0]) ) : (),
			$t[1] ? ( crd  => numfmt($t[1]) ) : (),
			$t[2] ? ( sdeb => numfmt($t[2]) ) : (),
			$t[3] ? ( scrd => numfmt($t[3]) ) : (),
		      });
	    $tot[$_] += $t[$_] foreach 0..$#tot;
	}
	@tot;
    };

    if ( $detail >= 0 ) {	# Verdicht
	my @vd;
	my @hvd;
	$sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc".
			      " FROM Verdichtingen".
			      " WHERE vdi_struct IS NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    $hvd[$rr->[0]] = [ @$rr, []];
	}

	@vd = @hvd;
	$sth = $dbh->sql_exec("SELECT vdi_id, vdi_desc, vdi_struct".
			      " FROM Verdichtingen".
			      " WHERE vdi_struct IS NOT NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    push(@{$hvd[$rr->[2]]->[2]}, [@$rr]);
	    @vd[$rr->[0]] = [@$rr];
	}

	my @tot = $hoofdverdichtingen->(@hvd);
	$rep->add({ _style => 't',
		    desc => _T("TOTAAL"),
		    $tot[0] ? ( deb  => numfmt($tot[0]) ) : (),
		    $tot[1] ? ( crd  => numfmt($tot[1]) ) : (),
		    $tot[2] ? ( sdeb => numfmt($tot[2]) ) : (),
		    $tot[3] ? ( scrd => numfmt($tot[3]) ) : (),
		  });
    }

    else {			# Op Grootboek

	my @tot = (0) x 4;
	my $sth = $dbh->sql_exec
	  ("SELECT acc_id, acc_desc, acc_balance, acc_ibalance".
	   " FROM ${table}".
	   " WHERE ( acc_ibalance <> 0".
	   "         OR acc_id IN ( SELECT DISTINCT jnl_acc_id FROM Journal".
	  "                         WHERE jnl_date >= ? AND jnl_date <= ? ))".
	   " ORDER BY acc_id", $begin, $end);
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($acc_id, $acc_desc, $acc_balance, $acc_ibalance) = @$rr;
	    my @t = $journaal->($acc_id, $acc_desc, $acc_ibalance);
	    next if "@t" eq "0 0 0 0";
	    $tot[$_] += $t[$_] foreach 0..$#tot;
	    $rep->add({ _style => 'd',
			acct => $acc_id,
			desc => $acc_desc,
			deb  => numfmt($t[0]),
			crd  => numfmt($t[1]),
			$t[2] ? ( sdeb => numfmt($t[2]) ) : (),
			$t[3] ? ( scrd => numfmt($t[3]) ) : (),
		      });
	}
	$rep->add({ _style => 't',
		    desc => _T("TOTAAL"),
		    deb  => numfmt($tot[0]),
		    crd  => numfmt($tot[1]),
		    $tot[2] ? ( sdeb => numfmt($tot[2]) ) : (),
		    $tot[3] ? ( scrd => numfmt($tot[3]) ) : (),
		  });
    }
    $rep->finish;
    $dbh->rollback;
}

package EB::Report::Proof::Text;

use EB;
use base qw(EB::Report::Reporter::Text);

sub new {
    my ($class, $opts) = @_;
    my $self = $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
    $self->{detail} = $opts->{detail};
    $self;
}

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	d2  => {
	    desc   => { indent      => 2 },
	},
	t2  => {
	    _style => { skip_after  => $self->{detail} > 1, },
	    desc   => { indent      => 1 },
	},
	h2  => {
	    desc   => { indent      => 1 },
	},
	t1 => {
	    _style => { skip_after  => $self->{detail} > 0,
			skip_before => $self->{detail} > 1,
		      },
	},
	t => {
	    _style => { line_before => 1 }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Proof::Csv;

use EB;
use base qw(EB::Report::Reporter::Csv);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

package EB::Report::Proof::Html;

use EB;
use base qw(EB::Report::Reporter::Html);
use strict;

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

1;
