BEGIN WORK;

ALTER TABLE Boekstukken
ADD COLUMN bsk_ref TEXT;

ALTER TABLE Journal
ADD COLUMN jnl_bsk_ref TEXT;

-- Bump version.

UPDATE Constants
  SET value = '12'
  WHERE name = 'SCM_REVISION' AND value = '11';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
