#! perl --			-*- coding: utf-8 -*-

use utf8;

# Export.pm -- Export EekBoek administratie
# Author          : Johan Vromans
# Created On      : Mon Jan 16 20:47:38 2006
# Last Modified By: Johan Vromans
# Last Modified On: Mon Mar  7 08:38:34 2016
# Update Count    : 263
# Status          : Unknown, Use with caution!

package main;

our $dbh;
our $cfg;

package EB::Export;

use strict;
use warnings;

use EB;
use EB::Format;
use Encode;
use Fcntl qw( O_WRONLY O_CREAT );
use EB::Tools::Attachments;

my $ident;

sub export {
    my ($self, $opts) = @_;

    my $dir = $opts->{dir};
    if ( defined $dir ) {
	mkdir($dir, 0777) unless -d $dir;
	die("?".__x("Fout bij aanmaken directory {dir}: {err}",
		    dir => $dir, err => $!)."\n") unless -d $dir;
	die("?".__x("Geen toegang tot directory {dir}",
		    dir => $dir)."\n") unless -w $dir;

	$self->_write("$dir/schema.dat",  sub { $self->_schema(shift) });
	$self->_write("$dir/relaties.eb", sub { print { shift } $self->_relaties });
	$self->_write("$dir/opening.eb",  sub { print { shift } $self->_opening  });
	$self->_write("$dir/mutaties.eb", sub { print { shift } $self->_mutaties($opts) });

	my $att = EB::Tools::Attachments->new;
	foreach my $rr ( @{ $att->attachments } ) {
	    next if $rr->{encoding} == ATTENCODING_URI;
	    my $file = sprintf( "$dir/%08d_%s", $rr->{id}, $rr->{name} );
	    $att->save_to_file( $file, $rr->{id} );
	}
	return;

    }

    my $out = $opts->{file};
    if ( defined $out ) {
	eval { require Archive::Zip }
	  or die("?"._T("Module Archive::Zip, nodig voor export naar file, is niet beschikbaar")."\n");

	my $zip = Archive::Zip->new();
	my $comment = __x("Export van dataset {db} aangemaakt door {id} op {date}",
			  id => $EB::ident,
			  db => $cfg->val(qw(database name)),
			  date => datefmt_full(iso8601date()));
	$comment .= "\n".__x("Omschrijving: {desc}", desc => $opts->{desc})
	  if $opts->{desc};
	$zip->zipfileComment($comment);
	my $m;

	# For the schema, we need a temp file.
	my ($fh, $tmpname) = Archive::Zip::tempFile();
	binmode($fh, ":encoding(utf8)");
	$self->_schema($fh);
	$fh->close;
	$m = $zip->addFile($tmpname, "schema.dat");
	$m->desiredCompressionMethod(8);

	# The others can be added directly.
	# Note that the encoding needs to be fixed since there's no IO involved.
	$m = $zip->addString(_enc($self->_relaties), "relaties.eb");
	$m->desiredCompressionMethod(8);
	$m = $zip->addString(_enc($self->_opening), "opening.eb");
	$m->desiredCompressionMethod(8);
	$m = $zip->addString(_enc($self->_mutaties($opts)), "mutaties.eb");
	$m->desiredCompressionMethod(8);

	# Attachments.
	my $att = EB::Tools::Attachments->new;
	foreach my $rr ( @{ $att->attachments } ) {
	    next if $rr->{encoding} == ATTENCODING_URI;
	    my $file = sprintf( "%08d_%s", $rr->{id}, $rr->{name} );
	    $att->save_to_zip( $zip, $file, $rr->{id} );
	}

	my $status = $zip->writeToFileNamed($out);
	unlink($tmpname);
	die("?", __x("Fout {status} tijdens het aanmaken van exportbestand {name}",
		     status => $status,
		     name => $out)."\n") if $status;
	return;
    }

    die("?ASSERT ERROR: missing --dir / --file in Export\n");
}

sub _enc {
    my $t;
    eval {
	$t = encode( 'utf8', "".$_[0], 1 );
    };
    if ( $@ ) {
	warn("?".__x("Geen geldige UTF-8 tekens for ZIP element",
		     ).
	     "\n".$_[0]."\n");
	return;
    }
    $t;
}

sub _write {
    my ($self, $file, $producer) = @_;
    my $fh;
    open($fh, ">:encoding(utf-8)", $file)
      or die("?".__x("Fout bij aanmaken bestand {file}: {err}",
		     file => $file, err => $!)."\n");
    $producer->($fh)
      or die("?".__x("Fout bij schrijven bestand {file}: {err}",
		     file => $file, err => $!)."\n");
    close($fh)
      or die("?".__x("Fout bij afsluiten bestand {file}: {err}",
		     file => $file, err => $!)."\n");
}

sub _schema {
    my ($self, $fh) = @_;
    use EB::Tools::Schema;
    EB::Tools::Schema->dump_schema($fh);
}

sub _quote {
    my ($t) = @_;
    $t =~ s/(\\")/\\$1/g;
    '"'.$t.'"';
}

sub _relaties {
    my ($self) = @_;

    my $sth = $dbh->sql_exec("SELECT rel_code, rel_desc, rel_debcrd,".
			     " rel_btw_status, dbk_desc, rel_acc_id".
			     " FROM Relaties, Dagboeken".
			     " WHERE rel_ledger = dbk_id".
			     " ORDER BY rel_ledger, rel_btw_status, rel_code");

    my $cur_dbk = "";
    my $cur_btw = -1;
    my $out = "# " . __x("{what} voor administratie {adm}",
			 what => _T("Relaties"), adm => $dbh->adm("name")) . "\n" .
	      "# " . __x("Aangemaakt door {id} op {date}",
		  id => $EB::ident, date => datefmt_full(iso8601date())) . "\n" .
	      "# Content-Type: text/plain; charset = UTF-8";
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($code, $desc, $debcrd, $btw, $dbk, $acct) = @$rr;

	if ( $cur_btw != $btw || $cur_dbk ne $dbk ) {
	    $cur_btw = $btw;
	    $cur_dbk = $dbk;
	    $dbk =~ s/[^[:alnum:]]/_/g;
	    $out .= "\n\n" if $out;
	    $out .= _xt("cmd:relatie")." --".__xt("cmo:relatie:dagboek")."=".lc($dbk);
	    $out .= " --".__xt("cmo:relatie:btw")."=".lc(BTWTYPES->[$btw]) unless $btw == BTWTYPE_NORMAAL;
	}
	$out .= " \\\n        ";
	$out .= sprintf("%-12s %-40s %d", _quote($code), _quote($desc), $acct);
    }

    $out .= "\n\n# " . __x("Einde {what}", what => _T("Relaties")) . "\n";
}

sub _opening {
    my ($self) = @_;

    require EB::Booking::Decode;

    my $sth;

    my $out = "# " . __x("{what} voor administratie {adm}",
			 what => _T("Openingsgegevens"), adm => $dbh->adm("name")) . "\n" .
	      "# " . __x("Aangemaakt door {id} op {date}",
			 id => $EB::ident, date => datefmt_full(iso8601date())) . "\n" .
	      "# Content-Type: text/plain; charset = UTF-8\n\n";

    $out .= _xt("cmd:adm_naam") . "         " . _quote($dbh->adm("name")) . "\n";

    my $begin = $dbh->do("SELECT min(bky_begin)".
			 " FROM Boekjaren".
			 " WHERE bky_begin > ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )",
			 BKY_PREVIOUS);
    $begin = $begin->[0];

    $out .= _xt("cmd:adm_begindatum") . "   " . substr($begin, 0, 4) . "\n";
    $out .= _xt("cmd:adm_boekjaarcode") . " " . _quote($dbh->lookup($begin, qw(Boekjaren bky_begin bky_code))) . "\n";
    $out .= _xt("cmd:adm_btwperiode") . "   " .
      _T(qw(geen jaar x x kwartaal x x x x x x x maand)[$dbh->lookup($begin, qw(Boekjaren bky_begin bky_btwperiod))]).
	"\n" if $dbh->does_btw;

    $out .= "\n# " . _T("Openingsbalans") . "\n";

    $sth = $dbh->sql_exec("SELECT acc_id, acc_desc, acc_ibalance, acc_debcrd".
			  " FROM Accounts".
			  " WHERE acc_balres".
			  " AND acc_ibalance <> 0".
			  " ORDER BY acc_debcrd DESC, acc_id");

    my ($dt, $ct) = (0, 0);
    my $debcrd;
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $acc_desc, $acc_balance, $acc_debcrd) = @$rr;
	next unless $acc_balance;

	# Export boekhoudkundig saldo (zie EB::Tools::Opening).
	if ( $acc_balance >= 0 ) {
	    $dt += $acc_balance;
	}
	else {
	    $ct -= $acc_balance;
	}
	$acc_balance = 0 - $acc_balance unless $acc_debcrd;
	if ( !defined($debcrd) || $acc_debcrd != $debcrd ) {
	    $out .= "\n# " . ($acc_debcrd ? _T("Debet") : _T("Credit")) . "\n";
	}
	$out .= sprintf("%s %-5s %10s   # %s\n",
			_xt("cmd:adm_balans"),
			$acc_id, numfmt_plain($acc_balance),
			$acc_desc);
	$debcrd = $acc_debcrd;
    }

    die("?".__x("Internal error -- unbalance {arg1} <> {arg2}",
		arg1 => numfmt_plain($dt),
		arg2 => numfmt_plain($ct))."\n")
      unless $dt == $ct;
    $out .= "\n# " .  _T("Totaal") . "\n" . _xt("cmd:adm_balanstotaal") . " " . numfmt_plain($dt) . "\n";

    $sth = $dbh->sql_exec("SELECT bsk_id".
			  " FROM Boekstukken".
			  " WHERE bsk_date <= ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )".
			  " ORDER BY bsk_dbk_id, bsk_nr, bsk_date",
			  BKY_PREVIOUS);

    my $rr = $sth->fetchrow_arrayref;
    if ( $rr ) {
	$out .= "\n# "._T("Openstaande posten")."\n\n";
    }

    while ( $rr ) {
	my ($bsk_id) = @$rr;
	$out .= "adm_relatie " .
	  EB::Booking::Decode->decode
	      ($bsk_id,
	       { trail  => 1,
		 single => 0,
		 btw    => 0,
		 bsknr  => 1,
		 bky    => 1,
		 total  => 0,
		 noivbskdesc => 1,
		 debcrd => 0 }) . "\n";
	$rr = $sth->fetchrow_arrayref;
    }

    $out .= "\n# "._T("Openen van de administratie")."\n\n"._xt("cmd:adm_open")."\n";
    $out .= "\n# " . __x("Einde {what}", what => _T("Openingsgegevens")) . "\n";
    $out;
}

sub _mutaties {
    my ($self, $opts) = @_;

    my $out = "# " . __x("{what} voor administratie {adm}",
			 what => _T("Boekingen"), adm => $dbh->adm("name")) . "\n" .
	      "# " . __x("Aangemaakt door {id} op {date}",
			 id => $EB::ident, date => datefmt_full(iso8601date())) . "\n" .
	      "# Content-Type: text/plain; charset = UTF-8\n\n";

    my @bky;
    my $sth = $dbh->sql_exec("SELECT bky_code".
			     " FROM Boekjaren".
			     " WHERE bky_begin > ( SELECT bky_end FROM Boekjaren WHERE bky_code = ? )".
			     " ORDER BY bky_code",
			    BKY_PREVIOUS);
    while ( my $rr = $sth->fetchrow_arrayref ) {
	push(@bky, $rr->[0]);
    }

    my $check_je = sub {
	my ($bky) = @_;
	if ( $dbh->lookup($bky, qw(Boekjaren bky_code bky_closed)) ) {
	    $out .= _xt("cmd:jaareinde") .
	      " --" . __xt("cmo:jaareinde:boekjaar") . "=" . _quote($bky) .
	      " --" . __xt("cmo:jaareinde:definitief") . "\n";
	}
	else {
	    $sth = $dbh->sql_exec("SELECT COUNT(*)".
				  " FROM Boekjaarbalans".
				  " WHERE bkb_bky = ?", $bky);
	    my $rr;
	    if ( ($rr = $sth->fetchrow_arrayref) && $rr->[0] ) {
		$out .= _xt("cmd:jaareinde") .
		  " --" . __xt("cmo:jaareinde:boekjaar") . "=" . _quote($bky) . "\n";
	    }
	    $sth->finish;
	}
	if ( $dbh->does_btw ) {
	    my $bb = $dbh->adm("btwbegin");
	    my $bke = $dbh->lookup($bky, qw(Boekjaren bky_code bky_end));
	    my $bkb = $dbh->lookup($bky, qw(Boekjaren bky_code bky_begin));
	    if ( $bb gt $bkb ) {
		$bke = parse_date($bb, undef, -1) if $bb le $bke;
		$out .= _xt("cmd:btwaangifte").
		  " --" . __xt("cmo:btwaangifte:periode") . "=".
		  datefmt_full($bkb)."-".datefmt_full($bke) .
		  " --" . __xt("cmo:btwaangifte:definitief") .
		  " --" . __xt("cmo:btwaangifte:noreport") . "\n";
	    }
	}
    };

    my $cur_bky = $bky[0];
    foreach my $bky ( @bky ) {
	next if $bky eq BKY_PREVIOUS;
	if ( $cur_bky ne $bky ) {
	    $check_je->($cur_bky);
	    my $bp = $dbh->lookup($bky, qw(Boekjaren bky_code bky_btwperiod));
	    $out .= "\n# ". _T("Openen nieuw boekjaar") . "\n\n";
	    $out .= _xt("cmd:adm_boekjaarcode") . " " . _quote($bky) . "\n";
	    $out .= _xt("cmd:adm_btwperiode") . " " . lc(BTWPERIODES->[$bp]) . "\n" if $bp;
	    $out .= _xt("cmd:adm_open") . "\n";
	    $cur_bky = $bky;
	}
	$out .= _xt("cmd:boekjaar") . " " . _quote($bky) . "\n";

	$sth = $dbh->sql_exec("SELECT bsk_id, dbk_id".
			      " FROM Boekstukken, Dagboeken".
			      " WHERE bsk_dbk_id = dbk_id".
			      " AND bsk_bky = ?".
			      " ORDER BY dbk_type, bsk_dbk_id, bsk_nr", $bky);

	my $cur_dbk = "";
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    my ($bsk_id, $dbk_id) = @$rr;
	    if ( $cur_dbk ne $dbk_id ) {
		$out .= "\n";
		$cur_dbk = $dbk_id;
	    }
	    $out .= EB::Booking::Decode->decode
	      ($bsk_id,
	       { trail  => 1,
		 d_boekjaar => $bky,
		 bsknr  => defined($opts->{bsknr}) ? $opts->{bsknr} : 1,
		 single => $opts->{single}   || 0,
		 btw    => $opts->{explicit} || 0,
		 total  => defined($opts->{totals}) ? $opts->{totals} : 1,
		 debcrd => 0 }) . "\n";
	}
	$out .= "\n";
    }
    $check_je->($cur_bky);
    $out .= "# " . __x("Einde {what}", what => _T("Boekingen")) . "\n";
    $out;
}

sub _xt {			# scm:btw -> scm:vat -> vat
    my $t = _T(shift);
    $t =~ s/^.*://;
    $t;
}

1;
