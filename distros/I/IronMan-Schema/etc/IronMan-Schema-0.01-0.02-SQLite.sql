-- Convert schema './IronMan-Schema-0.01-SQLite.sql' to './IronMan-Schema-0.02-SQLite.sql':;

BEGIN;

CREATE TABLE posts (
  post_id INTEGER PRIMARY KEY NOT NULL,
  feed_id varchar(255) NOT NULL,
  url varchar(1024) NOT NULL,
  title varchar(1024) NOT NULL,
  posted_on datetime NOT NULL,
  summary text,
  body text NOT NULL,
  summary_filtered text,
  body_filtered text
);

CREATE INDEX posts_idx_feed_id ON posts (feed_id);

CREATE UNIQUE INDEX url02 ON posts (url);


COMMIT;


