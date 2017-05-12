BEGIN WORK;

ALTER TABLE Boekstukregels
ADD COLUMN bsr_ref      text;	-- reference

-- Bump version.

UPDATE Constants
  SET value = '15'
  WHERE name = 'SCM_REVISION' AND value = '14';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
