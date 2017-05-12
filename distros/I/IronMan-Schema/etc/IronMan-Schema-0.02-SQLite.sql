-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Dec 12 16:12:51 2009
-- 


BEGIN TRANSACTION;

--
-- Table: feed
--
DROP TABLE feed;

CREATE TABLE feed (
  id varchar(255) NOT NULL,
  url varchar(1024),
  link varchar(1024),
  title varchar(1024),
  owner varchar(255) NOT NULL,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX url ON feed (url);

--
-- Table: posts
--
DROP TABLE posts;

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

--
-- Table: tag
--
DROP TABLE tag;

CREATE TABLE tag (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(1024) NOT NULL
);

--
-- Table: feed_tag_map
--
DROP TABLE feed_tag_map;

CREATE TABLE feed_tag_map (
  feed integer NOT NULL,
  tag integer NOT NULL,
  PRIMARY KEY (feed, tag)
);

CREATE INDEX feed_tag_map_idx_feed ON feed_tag_map (feed);

CREATE INDEX feed_tag_map_idx_tag ON feed_tag_map (tag);

COMMIT;

