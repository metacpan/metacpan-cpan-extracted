BEGIN WORK;

ALTER TABLE Standaardrekeningen
ADD COLUMN std_acc_btw_vp   int references Accounts;	-- BTW verkoop privé
ALTER TABLE Standaardrekeningen
ADD COLUMN std_acc_btw_ip   int references Accounts;	-- BTW inkoop privé
ALTER TABLE Standaardrekeningen
ADD COLUMN std_acc_btw_va   int references Accounts;	-- BTW verkoop anders
ALTER TABLE Standaardrekeningen
ADD COLUMN std_acc_btw_ia   int references Accounts;	-- BTW inkoop anders

INSERT INTO Constants (name, value) VALUES ('BTWTARIEF_PRIV',   '3');
INSERT INTO Constants (name, value) VALUES ('BTWTARIEF_ANDERS', '4');

ALTER TABLE ONLY BTWTabel
    DROP CONSTRAINT "btw_tariefgroep";
ALTER TABLE ONLY BTWTabel
    ADD CONSTRAINT "btw_tariefgroep"
	CHECK (btw_tariefgroep >= 0 AND btw_tariefgroep <= 4);


-- Bump version.

UPDATE Constants
  SET value = '13'
  WHERE name = 'SCM_REVISION' AND value = '12';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
