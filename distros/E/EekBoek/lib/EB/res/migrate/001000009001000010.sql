-- Migratie EekBoek database van versie 1.0.9 naar 1.0.10 (EB 1.01.xx).

BEGIN WORK;

-- Table Dagboeken
ALTER TABLE ONLY Dagboeken ADD COLUMN dbk_dcsplit BOOLEAN;
ALTER TABLE ONLY Dagboeken ALTER COLUMN dbk_dcsplit SET DEFAULT false;
UPDATE Dagboeken SET dbk_dcsplit = 'false';

-- Table Journal
ALTER TABLE ONLY Journal ADD COLUMN jnl_damount int8;

-- Table Boekstukregels
ALTER TABLE ONLY Boekstukregels DROP COLUMN bsr_id;

-- Table Boekstukken

-- Operatie: wijzig type van bsk_id van serial naar int.
-- Omdat bsk_id vanuit diverse andere tabellen wordt gerefereerd als
-- foreign key moeten deze constraints eerst worden vervijderd, en
-- later weer aangemaakt.

ALTER TABLE ONLY Journal
    DROP CONSTRAINT "journal_jnl_bsk_id_fkey";
ALTER TABLE ONLY Boekstukregels
    DROP CONSTRAINT "boekstukregels_bsr_paid_fkey";
ALTER TABLE ONLY Boekstukregels
    DROP CONSTRAINT "boekstukregels_bsr_bsk_id_fkey";

-- De eigenlijke wijziging.
ALTER TABLE ONLY Boekstukken ADD COLUMN temp int8;
UPDATE Boekstukken SET temp = bsk_id;
ALTER TABLE ONLY Boekstukken DROP COLUMN bsk_id;
ALTER TABLE ONLY Boekstukken RENAME COLUMN temp TO bsk_id;
ALTER TABLE ONLY Boekstukken
    ADD CONSTRAINT "boekstukken_pkey"
    PRIMARY KEY ( bsk_id );

-- Expliciete sequence.
CREATE SEQUENCE boekstukken_bsk_id_seq;
SELECT setval('boekstukken_bsk_id_seq', max(bsk_id)) FROM Boekstukken;

-- Restore de FK constraints.
ALTER TABLE ONLY Journal
    ADD CONSTRAINT "journal_jnl_bsk_id_fkey"
    FOREIGN KEY ( jnl_bsk_id ) REFERENCES Boekstukken ( bsk_id );
ALTER TABLE ONLY Boekstukregels
    ADD CONSTRAINT "boekstukregels_bsr_paid_fkey"
    FOREIGN KEY ( bsr_paid ) REFERENCES Boekstukken ( bsk_id );
ALTER TABLE ONLY Boekstukregels
    ADD CONSTRAINT "boekstukregels_bsr_bsk_id_fkey"
    FOREIGN KEY ( bsr_bsk_id ) REFERENCES Boekstukken ( bsk_id );

-- Bump version.

UPDATE Constants
  SET value = 10
  WHERE name = 'SCM_REVISION';
UPDATE Metadata
  SET adm_scm_revision =
	(SELECT int4(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
