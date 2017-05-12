#! perl

package main;

our $config;
our $dbh;

package EB::Report::Open;

# Author          : Johan Vromans
# Created On      : Fri Sep 30 17:48:16 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jun 24 22:29:59 2012
# Update Count    : 206
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

sub perform {
    my ($self, $opts, $args) = @_;

    $opts->{STYLE} = "openstaand";
    $opts->{LAYOUT} =
      [
	{ name => "rel",  title => _T("Relatie"),      width => 10, },
        { name => "date", title => _T("Datum"),        width => $date_width, },
	{ name => "desc", title => _T("Omschrijving"), width => 30, },
	{ name => "amt",  title => _T("Bedrag"),       width => $amount_width, align => ">", },
	{ name => "bsk",  title => _T("Boekstuk"),     width => 16, },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);

    my $per = $rep->{per} = $rep->{periode}->[1];
    $rep->{periodex} = 1;	# force 'per'.
    my $sel;
    if ( $opts->{deb} && !$opts->{crd} ) {
	$sel = " AND dbk_type = @{[DBKTYPE_VERKOOP]}";
    }
    elsif ( !$opts->{deb} && $opts->{crd} ) {
	$sel = " AND dbk_type = @{[DBKTYPE_INKOOP]}";
    }
    else {
	$sel = " AND dbk_type in (@{[DBKTYPE_INKOOP]},@{[DBKTYPE_VERKOOP]})";
    }

    if ( $args && @$args == 1 ) {
	$sel .= " AND bsr_rel_code = ?";
    }

    my $eb = $opts->{eb_handle};

    my $gtot = 0;		# grand total deb/crd
    my $rtot = 0;		# relation total

    my $sth = $dbh->sql_exec("SELECT bsk_id, dbk_id, dbk_desc, bsk_nr, bsk_desc, bsk_date,".
			     " bsk_open, dbk_type, dbk_acc_id, bsr_rel_code, bsk_bky".
			     " FROM Boekstukken, Dagboeken, Boekstukregels".
			     " WHERE bsk_dbk_id = dbk_id".
			     " AND bsr_bsk_id = bsk_id AND bsr_nr = 1".
			     " AND bsk_date <= ?".
			     $sel.
			     " ORDER BY dbk_acc_id, bsr_rel_code, bsk_date",
			     $per, @$args);

    $rep->start(_T("Openstaande posten"));

    my $cur_rel;
    my $cur_cat;
    my $did;
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($bsk_id, $dbk_id, $dbk_desc, $bsk_nr, $bsk_desc, $bsk_date,
	    $bsk_amount, $dbk_type, $dbk_acc_id, $bsr_rel, $bsk_bky) = @$rr;


	# Correct for future payments.
	my $rop = $dbh->do("SELECT sum(bsr_amount)".
			   " FROM Boekstukregels".
			   " WHERE bsr_type IN (@{[DBKTYPE_INKOOP]},@{[DBKTYPE_VERKOOP]})".
			   " AND bsr_date > ?".
			   " AND bsr_paid = ?",
			   $per, $bsk_id);

	if ( $rop && $rop->[0] ) {
	    $bsk_amount -= $rop->[0];
	}

	next unless $bsk_amount;

	if ( defined($cur_rel) && $bsr_rel ne $cur_rel ) {
	    $rep->add({ _style => "trelatie",
			desc => __x("Totaal {rel}", rel  => $cur_rel),
			amt  => numfmt($rtot),
		      });
	    $rtot = 0;
	}

	if ( defined($cur_cat) && $dbk_acc_id ne $cur_cat ) {
	    $rep->add({ _style => "tdebcrd",
			desc => __x("Totaal {debcrd}",
				    debcrd => $dbh->lookup($cur_cat, qw(Accounts acc_id acc_desc))),
			amt  => numfmt($gtot),
		      });
	    $gtot = 0;
	    $rtot = 0;
	}

	$bsk_amount = 0-$bsk_amount if $dbk_type == DBKTYPE_INKOOP;

	if ( $eb ) {
	    my $t = lc($dbk_desc);
	    $t =~ s/\s+/_/g;
	    print {$eb} ("adm_relatie ",
			 join(":", $t, $bsk_bky, $bsk_nr), " ",
			 $bsk_date, " \"", $bsr_rel, "\" \"", $bsk_desc, "\" ",
			 numfmt_plain($bsk_amount), "\n");
	}

	my $bsk;
	my $style = $dbk_type == DBKTYPE_INKOOP ? "cdata" :
	  $dbk_type == DBKTYPE_VERKOOP ? "ddata" : "data";
	if ( $bsk_date lt $rep->{per_begin} ) {
	    $bsk = join(":", $dbk_desc, $bsk_bky, $bsk_nr);
	    $style = "prevdata";
	}
	else {
	    $bsk = join(":", $dbk_desc, $bsk_nr);
	}

	$rep->add({ _style => $style,
		    date => datefmt($bsk_date),
		    bsk  => $bsk,
		    desc => $bsk_desc,
		    rel  => $bsr_rel,
		    amt  => numfmt($bsk_amount),
		  });
	$gtot += $bsk_amount;
	$rtot += $bsk_amount;
	$cur_rel = $bsr_rel;
	$cur_cat = $dbk_acc_id;
	$did++;
    }

    if ( defined($cur_rel) ) {
	$rep->add({ _style => "trelatie",
		    desc => __x("Totaal {rel}", rel  => $cur_rel),
		    amt  => numfmt($rtot),
		  });
	$rtot = 0;
    }

    if ( defined($cur_cat) ) {
	$rep->add({ _style => "tdebcrd",
		    desc => __x("Totaal {debcrd}",
				debcrd => $dbh->lookup($cur_cat, qw(Accounts acc_id acc_desc))),
		    amt  => numfmt($gtot),
		  });
    }

    if ( $did ) {
	$rep->add({ _style => "last" });
	$rep->finish;
    }
    else {
	return "!"._T("Geen openstaande posten gevonden");
    }
    return;
}

package EB::Report::Open::Text;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Text);

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	trelatie  => {
	    _style => { skip_after => 1 },
	},
	tdebcrd  => {
	    _style => { cancel_skip => 1,
			skip_after => 1 },
	    amt    => { line_before => 1 },
	},
	last   => {
	    _style => { line_before => 1 },
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Open::Html;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Html);

package EB::Report::Open::Csv;

use strict;
use warnings;
use base qw(EB::Report::Reporter::Csv);

1;

