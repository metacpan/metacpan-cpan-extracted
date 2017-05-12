#!/usr/bin/perl -w

# OpenEAFDSS-TypeA-Filter.pl 
#	Electronic Fiscal Signature Devices CUPS Filter
#       Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 by Hasiotis Nikos
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ID: $Id: OpenEAFDSS-TypeA-Filter.pl 105 2009-05-18 10:52:03Z hasiotis $

use strict;
use EAFDSS; 
use DBI;
use Data::Dumper;
use Config::IniFiles;

my(%progie) = ( name      => 'OpenEAFDSS-TypeA-Filter.pl',
                author    => 'Nikos Hasiotis (hasiotis@gmail.com)',
                copyright => 'Copyright (c) 2008 Hasiotis Nikos, all rights reserved',
                version   => '0.80');

our($debug) = 1;

sub main {
	my($job_id, $user, $job_name, $copies, $options, $fname, $sandbox);

	my($cfg) = Config::IniFiles->new(-file => "/etc/OpenEAFDSS/OpenEAFDSS-TypeA.ini", -nocase => 1);

	my($ABC_DIR) = $cfg->val('MAIN', 'ABC_DIR', '/tmp/signs');
	my($SQLITE)  = $cfg->val('MAIN', 'SQLITE', '/tmp/eafdss.sqlite');
	my($CHARSET) = $cfg->val('MAIN',   'CHARSET', 'utf-8');

	my($SN)      = $cfg->val('DEVICE', 'SN', 'ABC02000001');
	my($DRIVER)  = $cfg->val('DEVICE', 'DRIVER', 'SDNP');
	my($PARAM)   = $cfg->val('DEVICE', 'PARAM', 'localhost');

	printf(STDERR "DEBUG: [OpenEAFDSS] EAFDSS PARAMS\n");
	printf(STDERR "DEBUG: [OpenEAFDSS]   ABC_DIR --> [%s]\n", $ABC_DIR);
	printf(STDERR "DEBUG: [OpenEAFDSS]   SQLITE ---> [%s]\n", $SQLITE);
	printf(STDERR "DEBUG: [OpenEAFDSS]   CHARSET --> [%s]\n", $CHARSET);

	printf(STDERR "DEBUG: [OpenEAFDSS]   SN -------> [%s]\n", $SN);
	printf(STDERR "DEBUG: [OpenEAFDSS]   DRIVER ---> [%s]\n", $DRIVER);
	printf(STDERR "DEBUG: [OpenEAFDSS]   PARAM ----> [%s]\n", $PARAM);


	unless ( defined $ENV{'TMPDIR'} ) {
		$ENV{'TMPDIR'} = "/tmp";
	}
	$sandbox = sprintf("%s/OpenEAFDSS-TMP-%s", $ENV{'TMPDIR'}, $$);
	umask(077);
	if (! mkdir($sandbox) ) {
		printf(STDERR "ERROR: [OpenEAFDSS] Cannot create temporary directory [%s]! Exiting\n", $sandbox);
		exit 1;
	}

	if ($#ARGV < 5) {
		$fname = sprintf("%s/JOB-TEMP-FILE-01", $sandbox); 

		open(FIN, "<-") || die "Error Opening STDIN ($!)";
		open(FOUT, ">", $fname) || die "Error Opening TMPFILE ($!)";
		while (<FIN>) { printf(FOUT $_) };
		close(FOUT);
		close(FIN);

		($job_id, $user, $job_name, $copies, $options) = ('', '', '', '', '');
	} else {
		($job_id, $user, $job_name, $copies, $options, $fname) = @ARGV;
	}

	printf(STDERR "DEBUG: [OpenEAFDSS] CUPS PARAMS\n");
	printf(STDERR "DEBUG: [OpenEAFDSS]   Job id ----> [%s]\n", $job_id);
	printf(STDERR "DEBUG: [OpenEAFDSS]   User ------> [%s]\n", $user);
	printf(STDERR "DEBUG: [OpenEAFDSS]   Job name --> [%s]\n", $job_name);
	printf(STDERR "DEBUG: [OpenEAFDSS]   Copies ----> [%s]\n", $copies);
	printf(STDERR "DEBUG: [OpenEAFDSS]   Options ---> [%s]\n", $options);

	unless ( isInvoice($fname) ) {
		printf(STDERR "NOTICE: [OpenEAFDSS] file is not an invoice\n");
		exit;
	}

	open(FH, $fname);
	my($invoice) = do { local($/); <FH> };
	close(FH);

	my($fname_conv) = sprintf("%s/JOB-TEMP-FILE-02", $sandbox); 
	if ($CHARSET ne "iso8859-7") {
		printf(STDERR "NOTICE: [OpenEAFDSS] Converting invoice from %s to iso8859-7\n", $CHARSET);
		my($iconv_cmd) = sprintf("iconv -f %s -t iso8859-7 -o %s %s", $CHARSET, $fname_conv, $fname);
		printf(STDERR "DEBUG: [OpenEAFDSS] iconv command [%s]\n", $iconv_cmd);
		system($iconv_cmd);
		if ($? == -1) {
			printf(STDERR "ERROR: [OpenEAFDSS] Failed to execute iconv: $!\n");
			exit;
		} elsif ($? & 127) {
			printf(STDERR "ERROR: [OpenEAFDSS] iconv died with signal %d\n", ($? & 127));
			exit;
		} elsif ($? >> 8 != 0) {
			printf(STDERR "ERROR: [OpenEAFDSS] iconv failed with value %d\n", $? >> 8);
			exit;
		} else {
			$fname = $fname_conv;
		}
	}

	printf(STDERR "NOTICE: [OpenEAFDSS] Signing file [%s]\n", $fname);

	my($dbh);
	if ( -e $SQLITE) {
		$dbh = DBI->connect("dbi:SQLite:dbname=$SQLITE","","");
	} else {
		printf(STDERR "NOTICE: [OpenEAFDSS] Creating sqlite file [%s]\n", $SQLITE);
		$dbh = DBI->connect("dbi:SQLite:dbname=$SQLITE","","");
		if ($dbh)  {
			$dbh->do("CREATE TABLE invoices" . 
				" (id INTEGER PRIMARY KEY, tm,  job_id, user, job_name, copies, options, signature, text);" );
		}
		chmod(0774, $SQLITE);
	}
	unless ($dbh)  {
		printf(STDERR "ERROR: [OpenEAFDSS] Cannot connect to sqlite db [%s]! Exiting\n", $SQLITE);
		exit 1;
	}

	my($reprint, $signature);
	if ( $options =~ m/eafddssreprint/ ) {
		$options =~ /eafddssreprint=(.*) /;
		$reprint = $1;
	} else {
		$reprint = 0;
	}

	if ($reprint) {
		printf(STDERR "NOTICE: [OpenEAFDSS] This is a reprint we will not sign again\n");
		$signature = $reprint;
	} else {
		umask(077);
		my($dh) = new EAFDSS(
				"DRIVER" => "EAFDSS::" . $DRIVER . "::" . $PARAM,
				"SN"     => $SN,
				"DIR"    => $ABC_DIR,
				"DEBUG"  => $debug
			);

		if (! $dh) {
			printf(STDERR "ERROR: [OpenEAFDSS]" . EAFDSS->error() ."\n");
			printf(STDERR "STATE: [OpenEAFDSS]" . EAFDSS->error() ."\n");
			exit 1;
		}
  
		$signature = $dh->Sign($fname);
		if (! $signature) {
			my($errNo)  = $dh->error();
			my($errMsg) = $dh->errMessage($errNo);
			printf(STDERR "ERROR: [OpenEAFDSS] [0x%02X] %s\n", $errNo, $errMsg);
			printf(STDERR "STATE: [OpenEAFDSS] [0x%02X] %s\n", $errNo, $errMsg);
			exit($errNo);
		} else {
			printf(STDERR "NOTICE: [OpenEAFDSS] Got sign [%s...]\n", substr($signature, 0, 20));
		}
	}

	if ($reprint == 0) {
		$invoice =~ s/'/''/g;

		my($insert) = "INSERT INTO invoices (tm,  job_id, user, job_name, copies, options, signature, text) " . 
                        " VALUES ( date('now'), '$job_id', '$user', '$job_name', '$copies', '$options', '$signature', '$invoice');";

		printf(STDERR "DEBUG: [OpenEAFDSS] SQL Insert [%s]\n", $insert);
		$dbh->do($insert) or die("NOTICE: [OpenEAFDSS] Insert Error [%s]\n", $dbh->errstr);
	}

	$dbh->disconnect();

	printf($invoice);
	printf(" %s \n", $signature);

	rmdir($sandbox);

	printf(STDERR "NOTICE: [OpenEAFDSS] Done\n");
}

sub isInvoice () {
	my($fname) = shift @_;

	my($match) = 0;
	open(FH, $fname);
	while (<FH>) {
		chop;
		if (m/ΑΠΟΔΕΙΞΗ ΛΙΑΝΙΚΗΣ/) {
			return 1;
		}
	}
	close(FH);

	return 0;
}

main();
exit;
