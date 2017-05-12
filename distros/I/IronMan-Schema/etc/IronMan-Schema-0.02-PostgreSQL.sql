-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Dec 12 16:12:55 2009
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
-- Table: posts
--
DROP TABLE "posts" CASCADE;
CREATE TABLE "posts" (
  "post_id" serial NOT NULL,
  "feed_id" character varying(255) NOT NULL,
  "url" character varying(1024) NOT NULL,
  "title" character varying(1024) NOT NULL,
  "posted_on" timestamp NOT NULL,
  "summary" text,
  "body" text NOT NULL,
  "summary_filtered" text,
  "body_filtered" text,
  PRIMARY KEY ("post_id"),
  CONSTRAINT "url3" UNIQUE ("url")
);
CREATE INDEX "posts_idx_feed_id" on "posts" ("feed_id");

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

ALTER TABLE "posts" ADD FOREIGN KEY ("feed_id")
  REFERENCES "feed" ("id") DEFERRABLE;

ALTER TABLE "feed_tag_map" ADD FOREIGN KEY ("feed")
  REFERENCES "feed" ("id") DEFERRABLE;

ALTER TABLE "feed_tag_map" ADD FOREIGN KEY ("tag")
  REFERENCES "tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;


