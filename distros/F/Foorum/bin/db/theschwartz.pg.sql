--
-- Table: funcmap
--
CREATE TABLE "funcmap" (
  "funcid" serial NOT NULL,
  "funcname" character varying(255) NOT NULL,
  PRIMARY KEY ("funcid"),
  UNIQUE ("funcname")
);



--
-- Table: job
--
CREATE TABLE "job" (
  "jobid" bigserial NOT NULL,
  "funcid" bigint NOT NULL,
  "arg" bytea,
  "uniqkey" character varying(255),
  "insert_time" bigint,
  "run_after" bigint NOT NULL,
  "grabbed_until" bigint NOT NULL,
  "priority" smallint,
  "coalesce" character varying(255),
  PRIMARY KEY ("jobid"),
  UNIQUE ("funcid", "uniqkey")
);
CREATE INDEX "" on "job" ("funcid", "run_after");
CREATE INDEX "" on "job" ("funcid", "coalesce");


--
-- Table: note
--
CREATE TABLE "note" (
  "jobid" bigint NOT NULL,
  "notekey" character varying(255) NOT NULL,
  "value" bytea,
  PRIMARY KEY ("jobid", "notekey")
);



--
-- Table: error
--
CREATE TABLE "error" (
  "error_time" bigint NOT NULL,
  "jobid" bigint NOT NULL,
  "message" character varying(255) NOT NULL,
  "funcid" bigint DEFAULT '0' NOT NULL
);
CREATE INDEX "" on "error" ("funcid", "error_time");
CREATE INDEX "" on "error" ("error_time");
CREATE INDEX "" on "error" ("jobid");


--
-- Table: exitstatus
--
CREATE TABLE "exitstatus" (
  "jobid" bigint NOT NULL,
  "funcid" bigint DEFAULT '0' NOT NULL,
  "status" smallint,
  "completion_time" bigint,
  "delete_after" bigint,
  PRIMARY KEY ("jobid")
);
CREATE INDEX "" on "exitstatus" ("funcid");
CREATE INDEX "" on "exitstatus" ("delete_after");
