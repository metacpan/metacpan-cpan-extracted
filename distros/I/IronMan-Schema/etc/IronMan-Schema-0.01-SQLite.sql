-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Dec 12 15:38:01 2009
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

