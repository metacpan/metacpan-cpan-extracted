

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE ROLE "MAPLAT_Server" LOGIN ENCRYPTED PASSWORD 'md54ce682a1dcfef7fa6c7150725f90d5ca'
  SUPERUSER CREATEDB
   VALID UNTIL 'infinity';
UPDATE pg_authid SET rolcatupdate=false WHERE rolname='MAPLAT_Server';


CREATE DATABASE "MAPLAT_DB" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE "MAPLAT_DB" OWNER TO "MAPLAT_Server";

