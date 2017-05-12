BEGIN WORK;

-- ONLY: SQLite
SELECT * INTO TEMP TAccounts FROM Accounts WHERE acc_id = 0;

ALTER TABLE Accounts
ADD COLUMN acc_dcfixed      boolean;	-- fixed d/c

-- ONLY: SQLite
ALTER TABLE TAccounts
ADD COLUMN acc_dcfixed      boolean;	-- fixed d/c

UPDATE Accounts SET acc_dcfixed = 'f' WHERE acc_balres;

-- Bump version.

UPDATE Constants
  SET value = '14'
  WHERE name = 'SCM_REVISION' AND value = '13';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
