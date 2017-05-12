-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Jun 16 10:49:03 2008
-- 
BEGIN TRANSACTION;


--
-- Table: funcmap
--
CREATE TABLE funcmap (
  funcid INTEGER PRIMARY KEY NOT NULL,
  funcname VARCHAR(255) NOT NULL
);

CREATE UNIQUE INDEX funcmap ON funcmap (funcname);

--
-- Table: job
--
CREATE TABLE job (
  jobid INTEGER PRIMARY KEY NOT NULL,
  funcid int(11) NOT NULL,
  arg MEDIUMBLOB,
  uniqkey VARCHAR(255),
  insert_time int(11),
  run_after int(11) NOT NULL,
  grabbed_until int(11) NOT NULL,
  priority SMALLINT(6),
  coalesce VARCHAR(255)
);

CREATE INDEX job ON job (funcid, run_after);
CREATE INDEX job02 ON job (funcid, coalesce);
CREATE UNIQUE INDEX job03 ON job (funcid, uniqkey);

--
-- Table: note
--
CREATE TABLE note (
  jobid BIGINT(20) NOT NULL,
  notekey VARCHAR(255) NOT NULL,
  value MEDIUMBLOB,
  PRIMARY KEY (jobid, notekey)
);


--
-- Table: error
--
CREATE TABLE error (
  error_time int(11) NOT NULL,
  jobid BIGINT(20) NOT NULL,
  message VARCHAR(255) NOT NULL,
  funcid int(11) NOT NULL DEFAULT '0'
);

CREATE INDEX error ON error (funcid, error_time);
CREATE INDEX error02 ON error (error_time);
CREATE INDEX error03 ON error (jobid);

--
-- Table: exitstatus
--
CREATE TABLE exitstatus (
  jobid INTEGER PRIMARY KEY NOT NULL,
  funcid int(11) NOT NULL DEFAULT '0',
  status SMALLINT(6),
  completion_time int(11),
  delete_after int(11)
);

CREATE INDEX exitstatus ON exitstatus (funcid);
CREATE INDEX exitstatus02 ON exitstatus (delete_after);

COMMIT;
