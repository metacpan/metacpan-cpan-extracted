BEGIN WORK;

-- Aanpassen BTW Tabel.
-- Nieuwe velden:
ALTER TABLE BTWTabel ADD COLUMN btw_alias varchar(10);
ALTER TABLE BTWTabel ADD COLUMN btw_start date;
ALTER TABLE BTWTabel ADD COLUMN btw_end	  date;

-- Markeer 'oude' hoog-tarief.
UPDATE BTWTabel SET btw_end = '2012-09-30' WHERE btw_perc = 1900 AND btw_tariefgroep = 1;

-- Voeg nieuwe 'hoog' tarief toe.
--  We have to use '1' for true and '0' for false to satisfy both PostgreSQL and SQLite.
INSERT INTO BTWTabel
       (btw_id, btw_desc, btw_perc, btw_tariefgroep, btw_incl, btw_alias, btw_start, btw_end)
       VALUES(1024, 'BTW 21% incl.', 2100, 1, '1', 'h21',  '2012-10-01', NULL);

INSERT INTO BTWTabel
       (btw_id, btw_desc, btw_perc, btw_tariefgroep, btw_incl, btw_alias, btw_start, btw_end)
       VALUES(1025, 'BTW 21% excl.', 2100, 1, '0', 'h21-', '2012-10-01', NULL);

-- Aanpassen Journaal.
-- column jnl_bsr_seq wordt jnl_seq
-- nieuwe column jnl_bsr_seq
-- nieuwe column jnl_type

-- SQLite cannot rename a column...

ALTER TABLE Journal RENAME TO tmp_Journal;

CREATE TABLE Journal (
    jnl_date	date not null,	-- boekstukdatum
    jnl_dbk_id	varchar(4) references Dagboeken,
    jnl_bsk_id	int not null references Boekstukken,
    jnl_bsk_ref text,
    jnl_bsr_date date not null,	-- boekstukregeldatum
    jnl_bsr_seq	int,		-- boekstukregelvolgnummer
    jnl_seq	int not null,	-- volgnummer journaalregel
    jnl_type	smallint,       -- 0 = primary, 1 = derived (VAT, ...), ...
    jnl_acc_id	int references Accounts,
    jnl_amount	int8,	-- total amount
    jnl_damount	int8,	-- debet portion
    jnl_desc	text,
    jnl_rel	CHAR(10),
    jnl_rel_dbk	varchar(4) references Dagboeken,
    CONSTRAINT "jnl_fk_rel"
	FOREIGN KEY (jnl_rel, jnl_rel_dbk) REFERENCES Relaties,
    UNIQUE(jnl_bsk_id, jnl_dbk_id, jnl_seq)
);

INSERT INTO Journal
    (jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsk_ref, jnl_bsr_date, jnl_bsr_seq, jnl_seq, jnl_type, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel, jnl_rel_dbk)
  SELECT
    jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsk_ref, jnl_bsr_date, NULL, jnl_bsr_seq, NULL, jnl_acc_id, jnl_amount, jnl_damount, jnl_desc, jnl_rel, jnl_rel_dbk
    FROM tmp_Journal;

DROP TABLE tmp_Journal;

ALTER TABLE Journal
  ADD CONSTRAINT "jnl_type"
    	CHECK(jnl_type >= 0 AND jnl_type <= 1);

-- Bump version.

UPDATE Constants
  SET value = '16'
  WHERE name = 'SCM_REVISION' AND value = '15';
UPDATE Metadata
  SET adm_scm_revision =
    (SELECT int2(value) FROM Constants WHERE name = 'SCM_REVISION');

COMMIT WORK;
