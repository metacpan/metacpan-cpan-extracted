# -- Migratie EekBoek database van versie 1.0.8 naar 1.0.9 (EB 0.92).

package main;

our $cfg;
our $dbh;

package EB::DatabaseMigrator;

use strict;
use warnings;
use EB;
use EB::Tools::SQLEngine;

my $en = EB::Tools::SQLEngine->new(dbh => $dbh->dbh,
				   trace => $cfg->val(qw(internal trace_migration), 0));

$en->process(<<EOS);
BEGIN WORK;

-- Add new column.

ALTER TABLE Boekstukken
  ADD COLUMN bsk_isaldo int8;
EOS

$dbh->trace($cfg->val(qw(internal trace_migration), 0));

my $sth1 = $dbh->sql_exec("SELECT dbk_id".
			  " FROM Dagboeken".
			  " WHERE dbk_type = ? OR dbk_type = ?",
			  DBKTYPE_BANK, DBKTYPE_KAS);
while ( my $rr1 = $sth1->fetchrow_arrayref ) {
    my ($dbk_id) = @$rr1;
  my $sth3 = $dbh->sql_exec("SELECT bky_code FROM Boekjaren");
  while ( my $rb = $sth3->fetchrow_arrayref ) {
    my $bky = $rb->[0];

    my %saldi;
    my %amt;
    my $sth2 = $dbh->sql_exec("SELECT bsk_nr,bsk_amount,bsk_saldo".
			      " FROM Boekstukken".
			      " WHERE bsk_dbk_id = ?".
			      " AND bsk_bky = ?",
			      $dbk_id, $bky);
    while ( my $rr2 = $sth2->fetchrow_arrayref ) {
	$amt{$rr2->[0]} = $rr2->[1];
	$saldi{$rr2->[0]} = $rr2->[2];
    }
    $sth2->finish;
    foreach my $bsk_nr ( keys(%saldi) ) {
	if ( exists $saldi{$bsk_nr-1} ) {
	    warn("SALDO MISMATCH: dbk=$dbk_id nr=$bsk_nr -- PLEASE REBUILD DATABASE\n")
	      unless $saldi{$bsk_nr-1} == $saldi{$bsk_nr} - $amt{$bsk_nr};
	    $dbh->sql_exec("UPDATE Boekstukken".
			   " SET bsk_isaldo = ?".
			   " WHERE bsk_nr = ?".
			   " AND bsk_dbk_id = ?".
			   " AND bsk_bky = ?",
			   $saldi{$bsk_nr-1}, $bsk_nr, $dbk_id, $bky)->finish;
	}
	else {
	    $dbh->sql_exec("UPDATE Boekstukken".
			   " SET bsk_isaldo = bsk_saldo - bsk_amount".
			   " WHERE bsk_nr = ?".
			   " AND bsk_dbk_id = ?".
			   " AND bsk_bky = ?",
			   $bsk_nr, $dbk_id, $bky)->finish;
	}
    }
  }
}

$en->process(<<EOS);
-- Bump version.

UPDATE Constants
  SET value = 9
  WHERE name = 'SCM_REVISION';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int4(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
EOS

1;
