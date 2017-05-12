-- Convert schema 'c040455291b2b29e4367' to 'index':;

BEGIN;

ALTER TABLE entries ADD COLUMN published tinyint NOT NULL DEFAULT 0;


COMMIT;

