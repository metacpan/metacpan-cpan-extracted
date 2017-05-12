-- Convert schema './IronMan-Schema-0.02-SQLite.sql' to './IronMan-Schema-0.03-SQLite.sql':;

BEGIN;

ALTER TABLE posts ADD COLUMN author varchar(1024) NOT NULL;

ALTER TABLE posts ADD COLUMN tags varchar(1024) NOT NULL;


COMMIT;

