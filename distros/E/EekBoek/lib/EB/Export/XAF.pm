# perl

# Export::XAF -- Export XML Audit File
# Author          : Johan Vromans
# Created On      : Sun Apr 13 17:25:07 2008
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jun  7 13:59:14 2012
# Update Count    : 241
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $dbh;
our $cfg;

package EB::Export::XAF;

use strict;
use warnings;

use EB;
use EB::Format;

################ The Process ################

sub export {
    my ($self, $opts) = @_;

    $self = bless {}, $self unless ref $self;

    my $xaf;
    open($xaf, '>:encoding(utf-8)', $opts->{xaf})
      or die("?". __x("Fout tijdens het aanmaken van exportbestand {name}: {err}",
		      name => $opts->{xaf},
		      msg => $!)."\n");
    $self->{fh} = $xaf;

    # Default to current boekjaar.
    $self->{bky} = $opts->{boekjaar} || $dbh->adm("bky");

    $self->{indent} = 0;
    $self->{openingdata} = [];
    $self->{elts} = [];

    # Generate XML Audit File.
    $self->generate_XAF();
}

################ XML Routines ################

{
    sub indent { "  " x $_[0]->{indent} }
    sub indent_incr { $_[0]->{indent}++ }
    sub indent_decr { $_[0]->{indent}-- }
    sub indent_init { $_[0]->{indent} = 0 }
}

sub generate_XAF {
    my ($self) = @_;
    $self->auditfile_begin();
    $self->generalLedger();
    $self->customersSuppliers();
    $self->transactions();
    $self->auditfile_end();
}

sub auditfile_begin {
    my ($self) = @_;

    my $r = $dbh->do("SELECT bky_begin, bky_end".
		     " FROM Boekjaren".
		     " WHERE bky_code = ?",
		     $self->{bky});

    $r or die(__x("Onbekend boekjaar: {bky}", bky => $self->{bky})."\n");

    @{$self}{qw(begin end)} = @$r;

    $self->print
      ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>', "\n");

    $self->xml_elt_open("auditfile");
      $self->xml_elt_open("header");
	$self->xml_elt("auditfileVersion",
		       "CLAIR2.00.00");
	$self->xml_elt("companyID",
		       $cfg->val(qw(company id), "x"));
	$self->xml_elt("taxRegistrationNr",
		       $cfg->val(qw(company taxreg), "1"));
	$self->xml_elt("companyName",
		       $cfg->val(qw(company name), "Squirrel"));
	$self->xml_elt("companyAddress",
		       $cfg->val(qw(company address), "Here"));
	$self->xml_elt("companyCity",
		       $cfg->val(qw(company city), "There"));
	$self->xml_elt("companyPostalCode",
		       $cfg->val(qw(company postalcode), "1234AA"));
	$self->xml_elt("fiscalYear",     $self->{bky});
	$self->xml_elt("startDate",      $self->{begin});
	$self->xml_elt("endDate",        $self->{end});
	$self->xml_elt("currencyCode",   "EUR");
	$self->xml_elt("dateCreated",
		       $cfg->val(qw(internal now), iso8601date()));
	$self->xml_elt("productID",      "EekBoek");
	$self->xml_elt("productVersion", $EekBoek::VERSION);
      $self->xml_elt_close("header");
}

sub auditfile_end {
    my ($self) = @_;
    $self->xml_elt_close("auditfile");
    indent_decr;
}

sub generalLedger {
    my ($self) = @_;

    # Parse SQL and execute.
    my $sth = $dbh->sql_exec
      ("SELECT acc_id, acc_desc, acc_debcrd, acc_balres, acc_ibalance".
       " FROM Accounts".
       " ORDER BY acc_id");

    # Bind result columns.
    $sth->bind_columns(\my($acc_id, $acc_desc, $acc_dc, $acc_br, $acc_ibal));

    $self->xml_elt_open("generalLedger");
    $self->xml_elt("taxonomy", "geen");

    # Fetch entries, one by one.
    while ( $sth->fetch ) {
	$self->xml_elt_open("ledgerAccount");
	  $self->xml_elt("accountID",    $acc_id);
	  $self->xml_elt("accountDesc",  $acc_desc);
	  # B = Balance, P = Profit/Loss.
	  $self->xml_elt("accountType",  $acc_br ? "B" : "P");
	  $self->xml_elt("leadCode",     $acc_id);
	$self->xml_elt_close("ledgerAccount");
	# Save opening transactions.
	push(@{$self->{openingdata}}, [ $acc_id, $acc_ibal ]) if $acc_ibal;
    }

    $self->xml_elt_close("generalLedger");
}

sub customersSuppliers {
    my ($self) = @_;

    # Parse SQL and execute.
    my $sth = $dbh->sql_exec
      ("SELECT DISTINCT rel_code, rel_desc".
       " FROM Relaties".
       " ORDER BY rel_code");

    # Bind result columns.
    $sth->bind_columns(\my($rel_code, $rel_desc));

    $self->xml_elt_open("customersSuppliers");

    # Fetch entries, one by one.
    while ( $sth->fetch ) {
	$self->xml_elt_open("customerSupplier");
	  $self->xml_elt("custSupID",   $rel_code);
	  $self->xml_elt("companyName", $rel_desc);
	  $self->xml_elt_open("streetAddress");
	    $self->xml_elt("address",      "onbekend");
	    $self->xml_elt("city",         "ONBEKEND");
	    $self->xml_elt("postalCode",   "0000 XX");
	    $self->xml_elt("country",      "Nederland");
	  $self->xml_elt_close("streetAddress");
	$self->xml_elt_close("customerSupplier");
    }
    $self->xml_elt_close("customersSuppliers");
}

sub transactions {
    my ($self) = @_;

    $self->xml_elt_open("transactions");

    # Retrieve credit and debit totals separately.

    my ($dcnt, $damt) =
      @{$dbh->do("SELECT count (*), sum(jnl_amount)".
		 " FROM Journal".
		 " WHERE jnl_amount > 0".
		 " AND jnl_date >= ?".
		 " AND jnl_date <= ?".
		 " AND jnl_seq != 0",
		 $self->{begin}, $self->{end})};
    my ($ccnt, $camt) =
      @{$dbh->do("SELECT count (*), sum(jnl_amount)".
		 " FROM Journal".
		 " WHERE jnl_amount < 0".
		 " AND jnl_date >= ?".
		 " AND jnl_date <= ?".
		 " AND jnl_seq != 0",
		 $self->{begin}, $self->{end})};

    my $entries = $dcnt + $ccnt;
    if ( @{$self->{openingdata}} ) {
	$entries += @{$self->{openingdata}};
	foreach ( @{$self->{openingdata}} ) {
	    if ( $_->[1] < 0 ) {
		$camt += $_->[1];
	    }
	    else {
		$damt += $_->[1];
	    }
	}
    }
    $self->xml_elt("numberEntries", $entries);
    $self->xml_elt("totalDebit",    _numfmt($damt));
    $self->xml_elt("totalCredit",   _numfmt(-$camt));

    # Get the list of daybooks (dagboeken).
    my $sth = $dbh->sql_exec
      ("SELECT dbk_id, dbk_desc, dbk_type".
       " FROM Dagboeken".
       " ORDER BY dbk_id");

    my @dbk;
    while ( my $rr = $sth->fetch ) {
	push(@dbk, [@$rr]);
    }

    # Process the daybooks (dagboeken).
    foreach my $dbk ( @dbk ) {

	$self->xml_elt_open("journal");
	$self->xml_elt("journalID", $dbk->[0]);
	$self->xml_elt("description", $dbk->[1]);
	$self->xml_elt("type", $dbk->[2]);

	# Insert openings transactions in (first) memorial.
	if ( $dbk->[2] == DBKTYPE_MEMORIAAL && @{$self->{openingdata}} ) {
	    $self->xml_elt_open("transaction");
	    $self->xml_elt("transactionID", 0);
	    $self->xml_elt("period", 0);
	    $self->xml_elt("transactionDate", $self->{begin});
	    my $nr = 0;
	    foreach my $op ( @{$self->{openingdata}} ) {
		$self->xml_elt_open("line");
		  $self->xml_elt("recordID",    ++$nr);
		  $self->xml_elt("accountID",   $op->[0]);
		  $self->xml_elt("documentID",  0);
		  $self->xml_elt("description", "opening");
		  $self->xml_amt($op->[1]);
		$self->xml_elt_close("line");
	    }
	    $self->{openingdata} = [];	# clear
	    $self->xml_elt_close("transaction");
	}

	# Fetch transactions from journal.
	$sth = $dbh->sql_exec
	  ("SELECT jnl_date, bsk_nr, jnl_seq,".
	   " jnl_acc_id, jnl_rel, jnl_desc, ".
	   " jnl_amount, jnl_damount".
	   " FROM Journal, Boekstukken".
	   " WHERE jnl_dbk_id = ?".
	   " AND jnl_bsk_id = bsk_id".
	   " AND jnl_date >= ?".
	   " AND jnl_date <= ?".
	   " ORDER BY bsk_nr, jnl_date, jnl_bsk_id, jnl_seq",
	   $dbk->[0], $self->{begin}, $self->{end});

	$sth->bind_columns
	  (\my ($jnl_date, $bsk_nr, $jnl_seq, $jnl_acc_id,
		$jnl_rel, $jnl_desc, $jnl_amount, $jnl_damount));

      FETCH: while ( $sth->fetch ) {
	    $self->xml_elt_open("transaction");

	    $self->xml_elt("transactionID",   $bsk_nr);
	    $self->xml_elt("period",          substr($jnl_date, 5, 2));
	    $self->xml_elt("transactionDate", $jnl_date);

	    my $rel = $jnl_rel;	# save relation

	    while ( $sth->fetch ) {
		if ( $jnl_seq == 0 ) {
		    # Close current transaction, proceed with next.
		    $self->xml_elt_close("transaction");
		    redo FETCH;
		}
		# Combine deb/crd amounts.
		$jnl_amount -= $jnl_damount if $jnl_damount;

		$self->xml_elt_open("line");
		  $self->xml_elt("recordID", $jnl_seq);
		  $self->xml_elt("accountID", $jnl_acc_id);
		  $self->xml_elt("custSupID", $rel);
		  $self->xml_elt("documentID", $bsk_nr);
		  $self->xml_elt("description", $jnl_desc);
		  $self->xml_amt($jnl_amount);
		$self->xml_elt_close("line");
	    }
	    $self->xml_elt_close("transaction");
	    last;
	}

	$self->xml_elt_close("journal");
    }

    $self->xml_elt_close("transactions");
}

sub print {
    my ($self, @args) = @_;
    print { $self->{fh} } @args;
}

sub printi {
    my ($self, @args) = @_;
    print { $self->{fh} } $self->indent, @args;
}

sub _numfmt {
    my ($v) = @_;
    my $t = numfmt_plain($v);
    $t =~ s/,/./;
    $t;
}
################ XML Support Routines ################

{
    # Open/close element.

    sub xml_elt_open {
	my ($self, $tag) = @_;
	$self->printi("<$tag>\n");
	$self->indent_incr;
	unshift(@{$self->{elts}}, $tag);
    }

    sub xml_elt_close {
	my ($self, $tag) = @_;
	if ( $tag eq $self->{elts}->[0] ) {
	    shift(@{$self->{elts}});
	}
	else {
	    warn("XML ERROR: closing element $tag while in ",
		 $self->{elts}->[0], "\n");
	}
	$self->indent_decr;
	$self->printi("</$tag>\n");
    }
}

# Output an XML element.
sub xml_elt {
    my ($self, $tag, $val) = @_;
    $self->printi("<$tag>@{[xml_text($val)]}</$tag>\n");
}

# Output an XML amount.
sub xml_amt {
    my ($self, $amount) = @_;
    if ( $amount >= 0 ) {
	$self->xml_elt("debitAmount", _numfmt($amount));
    }
    else {
	$self->xml_elt("creditAmount", _numfmt(-$amount));
    }
}

# XMLise text.
sub xml_text {
    return "" unless defined $_[0];
    for ( $_[0] ) {
	s/&/&amp;/g;
	s/'/&apos;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	return $_;
    }
}

1;
