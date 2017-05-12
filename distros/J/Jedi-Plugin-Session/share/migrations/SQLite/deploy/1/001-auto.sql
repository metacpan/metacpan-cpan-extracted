-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Dec 25 17:17:20 2013
-- 

;
BEGIN TRANSACTION;
--
-- Table: jedi_session
--
CREATE TABLE jedi_session (
  id  NOT NULL,
  expire_at TIMESPAMP NOT NULL,
  session  NOT NULL,
  PRIMARY KEY (id)
);
COMMIT;
