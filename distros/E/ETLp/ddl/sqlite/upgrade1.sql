-- 
-- created by sql::translator::producer::sqlite
-- created on wed may 12 16:45:34 2010
-- 


--begin transaction;

--
-- table: etlp_configuration
--
create table etlp_configuration (
  config_id  integer primary key,
  config_name varchar2(255) not null,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_file
--
create table etlp_file (
  file_id  integer primary key,
  canonical_filename varchar2(255) not null,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_file_process
--
create table etlp_file_process (
  file_proc_id  integer primary key,
  status_id number(38) not null,
  item_id number(38) not null,
  file_id number(38) not null,
  filename varchar2(255) not null,
  record_count number(38),
  message text,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_item
--
create table etlp_item (
  item_id  integer primary key,
  status_id number(38) not null,
  job_id number(38) not null,
  phase_id number(38) not null,
  item_name varchar2(255) not null,
  item_type varchar2(30) not null,
  message text,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_job
--
create table etlp_job (
  job_id  integer primary key,
  status_id number(38) not null,
  section_id number(38) not null,
  session_id number(38),
  process_id number(38) not null,
  message text,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_phase
--
create table etlp_phase (
  phase_id integer primary key,
  phase_name varchar2(30) not null
);

--
-- table: etlp_section
--
create table etlp_section (
  section_id integer primary key,
  config_id number(38) not null,
  section_name varchar2(255) not null,
  date_created text not null,
  date_updated text not null
);

--
-- table: etlp_status
--
create table etlp_status (
  status_id integer primary key,
  status_name varchar2(30) not null
);

--
-- table: etlp_user
--
create table etlp_user (
  user_id integer primary key,
  username varchar2(30) not null,
  first_name varchar2(50) not null,
  last_name varchar2(30) not null,
  password varchar2(40) not null,
  email_address varchar2(255),
  admin number(38) not null default '0 ',
  active number(38) not null default '1 '
);

 Create table sessions (
	id Varchar2 (32) NOT NULL ,
	a_session Text NOT NULL ,
	last_session_update Date
) 


--commit;
