-- Convert schema './IronMan-Schema-0.01-MySQL.sql' to 'IronMan::Schema v0.02':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `posts` (
  post_id integer NOT NULL auto_increment,
  feed_id varchar(255) NOT NULL,
  url text NOT NULL,
  title text NOT NULL,
  posted_on datetime NOT NULL,
  summary text,
  body text NOT NULL,
  summary_filtered text,
  body_filtered text,
  INDEX posts_idx_feed_id (feed_id),
  PRIMARY KEY (post_id),
  UNIQUE url (url),
  CONSTRAINT posts_fk_feed_id FOREIGN KEY (feed_id) REFERENCES `feed` (id)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE feed CHANGE COLUMN url url text,
                 CHANGE COLUMN link link text,
                 CHANGE COLUMN title title text;

ALTER TABLE tag CHANGE COLUMN name name text NOT NULL;


COMMIT;


