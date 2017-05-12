-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Jan  1 15:42:20 2014
-- 

;
BEGIN TRANSACTION;
--
-- Table: jedi_auth_roles
--
CREATE TABLE jedi_auth_roles (
  id INTEGER PRIMARY KEY NOT NULL,
  name  NOT NULL
);
CREATE UNIQUE INDEX uniq_name ON jedi_auth_roles (name);
--
-- Table: jedi_auth_users
--
CREATE TABLE jedi_auth_users (
  id INTEGER PRIMARY KEY NOT NULL,
  user  NOT NULL,
  password  NOT NULL,
  uuid  NOT NULL,
  info  NOT NULL
);
CREATE UNIQUE INDEX uniq_user ON jedi_auth_users (user);
CREATE UNIQUE INDEX uuid ON jedi_auth_users (uuid);
--
-- Table: jedi_auth_users_roles
--
CREATE TABLE jedi_auth_users_roles (
  user_id integer NOT NULL,
  role_id integer NOT NULL,
  PRIMARY KEY (user_id, role_id)
);
COMMIT;
