#! perl --			-*- coding: utf-8 -*-

use utf8;

# Einde.pm -- Eindejaarsverwerking
# Author          : Johan Vromans
# Created On      : Sun Oct 16 21:27:40 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:42:33 2010
# Update Count    : 247
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Tools::Einde;

use strict;
use warnings;

use EB;
use EB::Format;
use EB::Report;
use EB::Report::GenBase;
use EB::Report::Journal;
use EB::Report::Open;

sub new {
    my ($class) = @_;
    $class = ref($class) || $class;
    return bless {} => $class;
}

sub perform {
    my ($self, $args, $opts) = @_;

    # Akties:
    # Afboeken resultaatrekeningen -> Winstrekening
    # Afboeken BTW I/V H/L -> BTW Betaald

    my $tot = 0;

    my $date = $cfg->val(qw(internal now), iso8601date());
    $date = $dbh->adm("end") unless $date lt $dbh->adm("end");

    my $sth;
    my $rr;
    my $bky = $opts->{boekjaar};
    my $def = $opts->{definitief};
    my $eb;
    if ( $opts->{eb} ) {
	unless ( open($eb, '>:encoding(utf-8)', $opts->{eb}) ) {
	    warn("?", __x("Fout tijdens het aanmaken van bestand {file}: {err}",
			 file => $opts->{eb}, err => $!."")."\n");
	    return;
	}
	$opts->{eb_handle} = $eb;
    }

    my ($acc_id, $acc_desc, $acc_balance);

    warn("?",_T("Geen boekjaar opgegeven")."\n"), return unless $bky;

    $rr = $dbh->do("SELECT bky_begin, bky_end, bky_closed".
		   " FROM Boekjaren".
		   " WHERE bky_code = ?", $bky);
    warn("?",__x("Onbekend boekjaar: {bky}", bky => $bky)."\n"), return unless $rr;

    my ($begin, $end, $closed) = @$rr;
    if ( $closed ) {
	if ( $opts->{verwijder} ) {
	    warn("?",__x("Boekjaar {bky} is definitief afgesloten", bky => $bky)."\n");
	}
	else {
	    warn("?",__x("Boekjaar {bky} is reeds definitief afgesloten", bky => $bky)."\n");
	}
	return;
    }

    $dbh->begin_work;

    $dbh->sql_exec("DELETE FROM Boekjaarbalans where bkb_bky = ?", $bky)->finish;

    $dbh->commit, return if $opts->{verwijder};

    $opts->{STYLE} = "journaal";
    $opts->{LAYOUT} =
      [ { name => "date", title => _T("Datum"),              width => $date_width, },
	{ name => "desc", title => _T("Boekstuk/Grootboek"), width => 30, },
	{ name => "acct", title => _T("Rek"),                width =>  5, align => ">", },
	{ name => "deb",  title => _T("Debet"),              width =>  $amount_width, align => ">", },
	{ name => "crd",  title => _T("Credit"),             width =>  $amount_width, align => ">", },
	{ name => "bsk",  title => _T("Boekstuk/regel"),     width => 30, },
	{ name => "rel",  title => _T("Relatie"),            width => 10, },
      ];

    my $rep;
    $rep = EB::Report::GenBase->backend(EB::Report::Journal::, $opts);

    my $tbl = EB::Report::->GetTAccountsBal($end);

    $sth = $dbh->sql_exec("SELECT acc_id, acc_desc, acc_balance".
			  " FROM ${tbl}".
			  " WHERE NOT acc_balres".
			  " AND acc_balance <> 0".
			  " ORDER BY acc_id");

    my $edt = parse_date($end, undef, 1);
    my $dtot = 0;
    my $ctot = 0;
    my $did;
    my $desc;
    while ( $rr = $sth->fetchrow_arrayref ) {
	($acc_id, $acc_desc, $acc_balance) = @$rr;
	$tot += $acc_balance;
	$dbh->sql_insert("Boekjaarbalans",
			 [qw(bkb_bky bkb_acc_id bkb_balance bkb_end)],
			 $bky, $acc_id, $acc_balance, $end);

	unless ( $did++ ) {
	    $rep->start(_T("Journaal"),
			__x("Afsluiting boekjaar {bky}", bky => $bky));
	}
	unless ( $desc ) {
	    $rep->add({ _style => 'head',
			date => datefmt_full($end),
			desc => join(":", "<<"._T("Systeemdagboek").">>", $bky, 1),
		      });
	    $desc = "Afboeken Resultaatrekeningen";
	}
	$acc_balance = -$acc_balance;
	$rep->add({ _style => 'data',
		    date => datefmt_full($end),
		    desc => $dbh->lookup($acc_id, qw(Accounts acc_id acc_desc)),
		    acct => $acc_id,
		    $acc_balance >= 0 ? ( deb => numfmt($acc_balance) )
				      : ( crd => numfmt(-$acc_balance) ),
		    bsk  => $desc,
		  });
	$dtot += $acc_balance if $acc_balance > 0;
	$ctot -= $acc_balance if $acc_balance < 0;
    }
    if ( $did ) {
	my $d = '<< ' . ($tot <= 0 ?
			 __x("Winst boekjaar {bky}", bky => $bky) :
			 __x("Verlies boekjaar {bky}", bky => $bky)) . ' >>';

	$dbh->sql_insert("Boekjaarbalans",
			 [qw(bkb_bky bkb_acc_id bkb_balance bkb_end)],
			 $bky, $dbh->std_acc("winst"), -$tot, $end);

	$tot = -$tot;
	$rep->add({ _style => 'data',
		    date => datefmt_full($end),
		    desc => $d,
		    acct => $dbh->std_acc("winst"),
		    $tot >= 0 ? ( crd => numfmt($tot) )
		    : ( deb => numfmt(-$tot) ),
		    bsk  => $desc,
		  });
	$ctot += $tot if $tot > 0;
	$dtot -= $tot if $tot < 0;
    }

    $tot = 0;
    $desc = "";

    if ( $dbh->does_btw ) {

      ## Afboeken BTW

      foreach ( @{ $dbh->std_accs } ) {
	my $stdacc = $_;	# copy for mod
	next unless $stdacc =~ /^btw_[iv].$/;
	next unless defined( $stdacc = $dbh->std_acc($stdacc, undef) );
	($acc_id, $acc_desc, $acc_balance) =
	  @{$dbh->do("SELECT acc_id,acc_desc,acc_balance".
		     " FROM ${tbl}".
		     " WHERE acc_id = ?",
		     $stdacc)};
	next unless $acc_balance;
	$tot += $acc_balance;
	$dbh->sql_insert("Boekjaarbalans",
			 [qw(bkb_bky bkb_acc_id bkb_balance bkb_end)],
			 $bky, $acc_id, $acc_balance, $end);

	unless ( $did++ ) {
	    $rep->start(_T("Journaal"),
			__x("Afsluiting boekjaar {bky}", bky => $bky));
	}
	elsif ( !$desc ) {
#	    $rep->outline(' ');
	}
	unless ( $desc ) {
	    $rep->add({ _style => 'head',
			date => datefmt_full($end),
			desc => join(":", "<<"._T("Systeemdagboek").">>", $bky, 2),
		      });
	    $desc = "Afboeken BTW rekeningen";
	}

	$acc_balance = -$acc_balance;
	$rep->add({ _style => 'data',
		    date => datefmt_full($end),
		    desc => $dbh->lookup($acc_id, qw(Accounts acc_id acc_desc)),
		    acct => $acc_id,
		    $acc_balance >= 0 ? ( deb => numfmt($acc_balance) )
				      : ( crd => numfmt(-$acc_balance) ),
		    bsk  => $desc,
		  });
	$dtot += $acc_balance if $acc_balance > 0;
	$ctot -= $acc_balance if $acc_balance < 0;
      }
      if ( $did && $dbh->does_btw ) {
	($acc_id, $acc_desc, $acc_balance) =
	  @{$dbh->do("SELECT acc_id,acc_desc,acc_balance".
		     " FROM ${tbl}".
		     " WHERE acc_id = ?",
		     $dbh->std_acc("btw_ok"))};
	$dbh->sql_insert("Boekjaarbalans",
			 [qw(bkb_bky bkb_acc_id bkb_balance bkb_end)],
			 $bky, $acc_id, -$tot, $end);

	$tot = -$tot;
	$rep->add({ _style => 'data',
		    date => datefmt_full($end),
		    desc => $acc_desc,
		    acct => $acc_id,
		    $tot >= 0 ? ( crd => numfmt($tot) )
		    : ( deb => numfmt(-$tot) ),
		    bsk  => $desc,
		  });
	$ctot += $tot if $tot > 0;
	$dtot -= $tot if $tot < 0;
      }

    }	## End afboeken BTW

    if ( $did ) {
	$rep->add({ _style => 'total',
		    desc => __x("Totaal {pfx}", pfx => __x("Afsluiting boekjaar {bky}", bky => $bky)),
		    deb  => numfmt($dtot),
		    crd  => numfmt($ctot),
	      });
	$rep->finish;
    }

    if ( $eb ) {

	print {$eb} ("\n# ",
		     __x("Eindbalans bij afsluiting boekjaar {bky}",
			 bky => $bky),
		     "\n");


	$sth = $dbh->sql_exec("SELECT acc_id, acc_desc, acc_balance, acc_ibalance, acc_debcrd".
			      " FROM ${tbl}".
			      " WHERE acc_balres".
			      " ORDER BY acc_debcrd DESC, acc_id");

	my ($dt, $ct);
	my $debcrd;
	while ( $rr = $sth->fetchrow_arrayref ) {
	    my ($acc_id, $acc_desc, $acc_balance, $acc_ibalance, $acc_debcrd) = @$rr;
#	    warn("=> acc $acc_id bal = $acc_balance ibal = $acc_ibalance\n");
	    if ( my $t = $dbh->do("SELECT bkb_balance".
				  " FROM Boekjaarbalans".
				  " WHERE bkb_bky = ?".
				  " AND bkb_acc_id = ?",
				  $bky, $acc_id) ) {
		$acc_balance -= $t->[0];
	    }
	    next unless $acc_balance;
	    if ( $acc_balance >= 0 ) {
		$dt += $acc_balance;
	    }
	    else {
		$ct -= $acc_balance;
	    }
	    $acc_balance = 0 - $acc_balance unless $acc_debcrd;
	    if ( !defined($debcrd) || $acc_debcrd != $debcrd ) {
		print {$eb} ("\n# ",
			     $acc_debcrd ? _T("Debet") : _T("Credit"),
			     "\n");
	    }
	    printf {$eb} ("adm_balans %-5s %10s   # %s\n",
			  $acc_id, numfmt_plain($acc_balance),
			  $acc_desc);
	    $debcrd = $acc_debcrd;
	}

	die("?".__x("Internal error -- unbalance {arg1} <> {arg2}",
		    arg1 => numfmt($dt),
		    arg2 => numfmt($ct))."\n")
	  unless $dt == $ct;
	print {$eb} ("\n# ", _T("Totaal"), "\n",
		     "adm_balanstotaal   ", numfmt_plain($dt), "\n");

	print {$eb} ("\n# ",
		     __x("Openstaande posten bij afsluiting boekjaar {bky}",
			 bky => $bky),
		     "\n\n");
	my $t = EB::Report::Open->new->perform($opts);
	if ( $t ) {
	    $t =~ s/^./# /;
	    print {$eb} ($t, "\n");
	}
    }
    else {
	EB::Report::Open->new->perform($opts);
    }

    if ( $def ) {
	$dbh->sql_exec("UPDATE Boekjaren".
		       " SET bky_closed = now()".
		       " WHERE bky_code = ?", $bky)->finish;
    }

    $dbh->commit;
    close($eb) if $eb;
    undef;
}

1;
