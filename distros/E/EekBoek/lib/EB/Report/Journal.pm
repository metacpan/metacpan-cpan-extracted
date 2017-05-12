#! perl

# Author          : Johan Vromans
# Created On      : Sat Jun 11 13:44:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Fri Jun  8 22:38:39 2012
# Update Count    : 340
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;
our $dbh;

package EB::Report::Journal;

use strict;
use warnings;

use EB;
use EB::Format;
use EB::Booking;		# for dcfromtd()
use EB::Report::GenBase;

sub new {
    bless {}, shift;
}

sub journal {
    my ($self, $opts) = @_;

    my $nr = $opts->{select};
    my $pfx = $opts->{postfix} || "";
    my $detail = $opts->{detail};

    my $extra_btw_info = $cfg->val(qw(journal btwxinfo), $dbh->does_btw ? 1 : 0);

    $opts->{STYLE} = "journaal";
    $opts->{LAYOUT} =
      [ { name => "date", title => _T("Datum"),              width => $date_width, },
	{ name => "desc", title => _T("Boekstuk/Grootboek"), width => 30, },
	{ name => "acct", title => _T("Rek"),                width =>  5, align => ">", },
	{ name => "deb",  title => _T("Debet"),              width => $amount_width, align => ">", },
	{ name => "crd",  title => _T("Credit"),             width => $amount_width, align => ">", },
	$extra_btw_info ?
	({ name => "btw",  title => _T("BTW \%"),             width => $amount_width, align => ">", },
	 { name => "btg",  title => _T("Tarief"),             width => 10, }) : (),
	{ name => "bsk",  title => _T("Boekstuk/regel"),     width => 30, },
	{ name => "rel",  title => _T("Relatie"),            width => 10, },
      ];

    my $rep = EB::Report::GenBase->backend($self, $opts);
    my $per = $rep->{periode};
    if ( my $t = $cfg->val(qw(internal now), 0) ) {
	$per->[1] = $t if $t lt $per->[1];
    }

    # Sort order (boekstukken).
    my $so = join(", ",
		  "jnl_date",					# date
		  "jnl_dbk_id",					# dagboek
		  "bsk_nr",					# boekstuk
		  "CASE WHEN jnl_seq = 0 THEN 0 ELSE 1 END",# bsr 0 eerst
		  "sign(jnl_amount) DESC",			# debet eerst
		  "jnl_acc_id",					# rekeningnummer
		  "jnl_amount DESC",				# grootste bedragen vooraan
		  "jnl_type",
		  "jnl_seq");				# if all else fails

    $rep->start(_T("Journaal"));

    my $sth;
    if ( $nr ) {
	if ( $nr =~ /^([[:alpha:]].*):(\d+)$/ ) {
	    my $rr = $dbh->do("SELECT dbk_desc, dbk_id".
			      " FROM Dagboeken".
			      " WHERE dbk_desc ILIKE ?",
			      $1);
	    unless ( $rr ) {
		warn("?".__x("Onbekend dagboek: {dbk}", dbk => $1)."\n");
		return;
	    }
	    $sth = $dbh->sql_exec("SELECT jnl_date, jnl_bsr_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, jnl_seq, ".
				  "jnl_type, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel, jnl_bsk_ref".
				  " FROM Journal, Boekstukken, Dagboeken".
				  " WHERE bsk_nr = ?".
				  " AND dbk_id = ?".
				  " AND jnl_bsk_id = bsk_id".
				  " AND jnl_dbk_id = dbk_id".
				  ($per ? " AND jnl_date >= ? AND jnl_date <= ?" : "").
				  " ORDER BY ".$so,
				  $2, $rr->[1], $per ? @$per : ());
	    $pfx ||= __x("Boekstuk {nr}", nr => "$rr->[0]:$2");
	}
	elsif ( $nr =~ /^([[:alpha:]].*)$/ ) {
	    my $rr = $dbh->do("SELECT dbk_desc, dbk_id".
			      " FROM Dagboeken".
			      " WHERE dbk_desc ILIKE ?",
			      $1);
	    unless ( $rr ) {
		warn("?".__x("Onbekend dagboek: {dbk}", dbk => $1)."\n");
		return;
	    }
	    $sth = $dbh->sql_exec("SELECT jnl_date, jnl_bsr_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, jnl_seq, ".
				  "jnl_type, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel, jnl_bsk_ref".
				  " FROM Journal, Boekstukken, Dagboeken".
				  " WHERE dbk_id = ?".
				  " AND jnl_bsk_id = bsk_id".
				  " AND jnl_dbk_id = dbk_id".
				  ($per ? " AND jnl_date >= ? AND jnl_date <= ?" : "").
				  " ORDER BY ".$so,
				  $rr->[1], $per ? @$per : ());
	    $pfx ||= __x("Dagboek {nr}", nr => $rr->[0]);
	}
	else {
	    $sth = $dbh->sql_exec("SELECT jnl_date, jnl_bsr_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, jnl_seq, ".
				  "jnl_type, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel".
				  " FROM Journal, Boekstukken".
				  " WHERE jnl_bsk_id = ?".
				  " AND jnl_bsk_id = bsk_id".
				  ($per ? " AND jnl_date >= ? AND jnl_date <= ?" : "").
				  " ORDER BY ".$so,,
				  $nr, $per ? @$per : ());
	    $pfx ||= __x("Boekstuk {nr}", nr => $nr);
	}
    }
    else {
	$sth = $dbh->sql_exec("SELECT jnl_date, jnl_bsr_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, jnl_seq, ".
			      "jnl_type, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel, jnl_bsk_ref".
			      " FROM Journal, Boekstukken".
			      " WHERE jnl_bsk_id = bsk_id".
			      ($per ? " AND jnl_date >= ? AND jnl_date <= ?" : "").
			      " ORDER BY ".$so,
			      $per ? @$per : ());
    }
    my $rr;
    my $nl = 0;
    my $totd = my $totc = 0;

    while ( $rr = $sth->fetchrow_arrayref ) {
	my ($jnl_date, $jnl_bsr_date, $jnl_dbk_id, $jnl_bsk_id, $bsk_nr,
	    $jnl_bsr_seq, $jnl_seq, $jnl_type, $jnl_acc_id,
	    $jnl_amount, $jnl_damount, $jnl_desc, $jnl_rel, $jnl_bsk_ref) = @$rr;

	my $iv = _dbk_type($jnl_dbk_id) == DBKTYPE_INKOOP ? 'c'
	  : _dbk_type($jnl_dbk_id) == DBKTYPE_VERKOOP ? 'd' : '';

	if ( $jnl_seq == 0 ) {
	    $nl++, next unless $detail;
	    my $t = $jnl_rel;
	    if ( $t && $jnl_bsk_ref ) {
		$t .= ":" . $jnl_bsk_ref;
	    }
	    if ( $iv && $cfg->val(qw(internal noxrel), 0) ) {
		undef $t;
	    }
	    $rep->add({ _style => $iv.'head',
			date => datefmt($jnl_bsr_date),
			desc => join(":", _dbk_desc($jnl_dbk_id), $bsk_nr),
			bsk  => $jnl_desc,
			rel  => $t,
		      });
	    next;
	}

	my ($deb, $crd) = EB::Booking::dcfromtd($jnl_amount, $jnl_damount);
	$totd += $deb;
	$totc += $crd;
	next unless $detail;
	my $t = $jnl_rel;
	if ( $t && $jnl_bsk_ref ) {
	    $t .= ":" . $jnl_bsk_ref;
	}
	if ( $t ) {
	    $iv = _acc_type($jnl_acc_id) ? 'd' : 'c';
	}
	else {
	    $iv = '';
	}

	my $btw_perc = "";
	my $btw_tg = "";
	if ( $extra_btw_info > 1
	     || ( $extra_btw_info && defined($jnl_type) && $jnl_type == 0 ) ) {
	    my $res = $dbh->do( "SELECT bsr_btw_id, bsr_btw_class FROM Boekstukregels".
				" WHERE bsr_bsk_id = ? AND bsr_nr = ?",
				$jnl_bsk_id, $jnl_bsr_seq );
	    if ( defined($res) && defined($res->[0])
		 && defined($res->[1])
		 && $res->[1] & BTWKLASSE_BTW_BIT ) {
		my $btw_id = $res->[0];
		$res = $dbh->do( "SELECT btw_perc, btw_tariefgroep".
				 " FROM BTWTabel".
				 " WHERE btw_id = ?",
				 $btw_id );
		$btw_perc = btwfmt( $res->[0] );
		$btw_tg = BTWTARIEVEN->[$res->[1]];
	    }
	}


	$rep->add({ _style => $iv.'data',
		    date => datefmt($jnl_bsr_date),
		    desc => _acc_desc($jnl_acc_id),
		    acct => $jnl_acc_id,
		    ($deb || defined $jnl_damount) ? (deb => numfmt($deb)) : (),
		    ($crd || defined $jnl_damount) ? (crd => numfmt($crd)) : (),
		    bsk  => $jnl_desc,
		    $jnl_rel ? ( rel => $t ) : (),
		    $extra_btw_info ? ( btw => $btw_perc, btg => $btw_tg ) : (),
		  });
    }
    $rep->add({ _style => 'total',
		desc => __x("Totaal {pfx}", pfx => $pfx),
		deb  => numfmt($totd),
		crd  => numfmt($totc),
	      });
    $rep->finish;
}

my %dbk_desc;
sub _dbk_desc {
    $dbk_desc{$_[0]} ||= $dbh->lookup($_[0],
				      qw(Dagboeken dbk_id dbk_desc =));
}

my %dbk_type;
sub _dbk_type {
    $dbk_type{$_[0]} ||= $dbh->lookup($_[0],
				      qw(Dagboeken dbk_id dbk_type =));
}

my %acc_desc;
sub _acc_desc {
    return '' unless $_[0];
    $acc_desc{$_[0]} ||= $dbh->lookup($_[0],
				      qw(Accounts acc_id acc_desc =));
}

my %acc_type;
sub _acc_type {
    return '' unless $_[0];
    $acc_type{$_[0]} ||= $dbh->lookup($_[0],
				      qw(Accounts acc_id acc_debcrd =));
}

package EB::Report::Journal::Text;

use EB;
use base qw(EB::Report::Reporter::Text);
use strict;

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

# Style mods.

sub style {
    my ($self, $row, $cell) = @_;

    my $style_data  = {
		       _style => { skip_after  => 1,
				   cancel_skip => 1,
				 },
		       desc   => { indent      => 2 },
		       bsk    => { indent      => 2 },
		      };

    my $stylesheet = {
	data  => $style_data,
	cdata => $style_data,
	ddata => $style_data,
	total => {
	    _style => { line_before => 1 },
#	    desc   => { excess      => 2 },
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

package EB::Report::Journal::Html;

use EB;
use base qw(EB::Report::Reporter::Html);
use strict;

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

package EB::Report::Journal::Csv;

use EB;
use base qw(EB::Report::Reporter::Csv);

sub new {
    my ($class, $opts) = @_;
    $class->SUPER::new($opts->{STYLE}, $opts->{LAYOUT});
}

1;

