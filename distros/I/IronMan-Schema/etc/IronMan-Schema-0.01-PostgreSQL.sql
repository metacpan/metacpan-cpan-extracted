-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Dec 12 15:38:01 2009
-- 
--
-- Table: feed
--
DROP TABLE "feed" CASCADE;
CREATE TABLE "feed" (
  "id" character varying(255) NOT NULL,
  "url" character varying(1024),
  "link" character varying(1024),
  "title" character varying(1024),
  "owner" character varying(255) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "url" UNIQUE ("url")
);

--
-- Table: tag
--
DROP TABLE "tag" CASCADE;
CREATE TABLE "tag" (
  "id" serial NOT NULL,
  "name" character varying(1024) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: feed_tag_map
--
DROP TABLE "feed_tag_map" CASCADE;
CREATE TABLE "feed_tag_map" (
  "feed" integer NOT NULL,
  "tag" integer NOT NULL,
  PRIMARY KEY ("feed", "tag")
);
CREATE INDEX "feed_tag_map_idx_feed" on "feed_tag_map" ("feed");
CREATE INDEX "feed_tag_map_idx_tag" on "feed_tag_map" ("tag");

--
-- Foreign Key Definitions
--

ALTER TABLE "feed_tag_map" ADD FOREIGN KEY ("feed")
  REFERENCES "feed" ("id") DEFERRABLE;

ALTER TABLE "feed_tag_map" ADD FOREIGN KEY ("tag")
  REFERENCES "tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;


