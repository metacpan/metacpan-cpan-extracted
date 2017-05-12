BEGIN WORK;

-- Drop foreign keys to Relaties.

ALTER TABLE Boekstukregels
DROP CONSTRAINT "boekstukregels_bsr_rel_code_fkey";

ALTER TABLE Journal
DROP CONSTRAINT "journal_jnl_rel_fkey";

-- Drop primary key Relaties.

ALTER TABLE Relaties
DROP CONSTRAINT "relaties_pkey";

-- New PK constraint for Relaties.
ALTER TABLE Relaties
ADD CONSTRAINT "relaties_pkey" PRIMARY KEY (rel_code, rel_ledger);

-- Add column bsr_dbk_id for Boekstukregels.

ALTER TABLE Boekstukregels
ADD COLUMN bsr_dbk_id VARCHAR(4) REFERENCES Dagboeken;

-- Fix FK to Relaties.

ALTER TABLE Boekstukregels
ADD CONSTRAINT "bsr_fk_rel"
FOREIGN KEY (bsr_rel_code, bsr_dbk_id) REFERENCES Relaties;

-- Fill.
UPDATE Boekstukregels
SET bsr_dbk_id =
  ( SELECT rel_ledger FROM Relaties WHERE rel_code = Boekstukregels.bsr_rel_code );

-- Add column jnl_rel_dbk_id for Journal.

ALTER TABLE Journal
ADD COLUMN jnl_rel_dbk VARCHAR(4) REFERENCES Dagboeken;

-- Fix FK to Relaties.
ALTER TABLE Journal
ADD CONSTRAINT "jnl_fk_rel"
FOREIGN KEY (jnl_rel, jnl_rel_dbk) REFERENCES Relaties;

-- Fill.
UPDATE Journal
SET jnl_rel_dbk =
  ( SELECT rel_ledger FROM Relaties WHERE rel_code = Journal.jnl_rel_dbk);

-- Bump version.

UPDATE Constants
  SET value = '11'
  WHERE name = 'SCM_REVISION' AND value = '10';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
