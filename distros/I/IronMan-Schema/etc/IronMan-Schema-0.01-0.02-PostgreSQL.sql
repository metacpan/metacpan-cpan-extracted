-- Convert schema './IronMan-Schema-0.01-PostgreSQL.sql' to './IronMan-Schema-0.02-PostgreSQL.sql':;

BEGIN;

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

ALTER TABLE "posts" ADD FOREIGN KEY ("feed_id")
  REFERENCES "feed" ("id") DEFERRABLE;


COMMIT;


