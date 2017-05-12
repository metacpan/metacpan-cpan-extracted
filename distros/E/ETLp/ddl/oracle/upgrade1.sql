/*
Created		10/04/2010
Modified		17/06/2010
Project		ETLp
Model		Model
Company		Redbone Systems Ltd
Author		Dan Horne
Version		
Database		Oracle 9i 
*/


-- Create Types section


-- Create Tables section


Create table etlp_configuration (
	config_id Integer NOT NULL ,
	config_name Varchar2 (255) NOT NULL ,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_configuration primary key (config_id) 
) 
/

Create table etlp_section (
	section_id Integer NOT NULL ,
	config_id Integer NOT NULL ,
	section_name Varchar2 (255) NOT NULL ,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_section primary key (section_id) 
) 
/

Create table etlp_status (
	status_id Integer NOT NULL ,
	status_name Varchar2 (30) NOT NULL  Constraint etlp_status_u1 UNIQUE ,
 Constraint pk_etlp_status primary key (status_id) 
) 
/

Create table etlp_job (
	job_id Integer NOT NULL ,
	status_id Integer NOT NULL ,
	section_id Integer NOT NULL ,
	session_id Integer,
	process_id Integer NOT NULL ,
	message Clob,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_job primary key (job_id) 
) 
/

Create table etlp_item (
	item_id Integer NOT NULL ,
	status_id Integer NOT NULL ,
	job_id Integer NOT NULL ,
	phase_id Integer NOT NULL ,
	item_name Varchar2 (255) NOT NULL ,
	item_type Varchar2 (30) NOT NULL ,
	message Clob,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_item primary key (item_id) 
) 
/

Create table etlp_phase (
	phase_id Integer NOT NULL ,
	phase_name Varchar2 (30) NOT NULL ,
 Constraint pk_etlp_phase primary key (phase_id) 
) 
/

Create table etlp_file_process (
	file_proc_id Integer NOT NULL ,
	status_id Integer NOT NULL ,
	item_id Integer NOT NULL ,
	file_id Integer NOT NULL ,
	filename Varchar2 (255) NOT NULL ,
	record_count Integer,
	message Clob,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_file_process primary key (file_proc_id) 
) 
/

Create table etlp_file (
	file_id Integer NOT NULL ,
	canonical_filename Varchar2 (255) NOT NULL ,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_file primary key (file_id) 
) 
/

Create table etlp_user (
	user_id Integer NOT NULL ,
	username Varchar2 (30) NOT NULL ,
	first_name Varchar2 (50) NOT NULL ,
	last_name Varchar2 (30) NOT NULL ,
	password Varchar2 (40) NOT NULL ,
	email_address Varchar2 (255),
	admin Integer Default 0 NOT NULL  Constraint etlp_user_ck1 Check (admin in (1,0) ) ,
	active Integer Default 1 NOT NULL  Constraint etlp_user_ck2 Check (active in (1,0) ) ,
 Constraint pk_etlp_user primary key (user_id) 
) 
/

Create table sessions (
	id Varchar2 (32) NOT NULL ,
	a_session Varchar2 (4000) NOT NULL ,
	date_created Date Default sysdate NOT NULL ,
 Constraint pk_sessions primary key (id) 
) 
/

Create table etlp_schedule (
	schedule_id Integer NOT NULL ,
	section_id Integer NOT NULL ,
	user_updated Integer NOT NULL ,
	user_created Integer NOT NULL ,
	schedule_description Clob,
	schedule_comment Clob,
	status Integer Default 1 NOT NULL ,
	date_created Date NOT NULL ,
	date_updated Date NOT NULL ,
 Constraint pk_etlp_schedule primary key (schedule_id) 
) 
/

Create table etlp_schedule_day_of_week (
	schedule_dow_id Integer NOT NULL ,
	dow_id Integer NOT NULL ,
	schedule_id Integer NOT NULL ,
 Constraint pk_etlp_schedule_day_of_week primary key (schedule_dow_id) 
) 
/

Create table etlp_schedule_hour (
	schedule_hour_id Integer NOT NULL ,
	schedule_id Integer NOT NULL ,
	schedule_hour Integer NOT NULL ,
 Constraint pk_etlp_schedule_hour primary key (schedule_hour_id) 
) 
/

Create table etlp_schedule_minute (
	schedule_minute_id Integer NOT NULL ,
	schedule_id Integer NOT NULL ,
	schedule_minute Integer NOT NULL ,
 Constraint pk_etlp_schedule_minute primary key (schedule_minute_id) 
) 
/

Create table etlp_day_of_week (
	dow_id Integer NOT NULL ,
	day_name Varchar2 (20) NOT NULL  UNIQUE ,
	cron_day_id Integer NOT NULL ,
 Constraint pk_etlp_day_of_week primary key (dow_id) 
) 
/

Create table etlp_schedule_month (
	schedule_month_id Integer NOT NULL ,
	month_id Integer NOT NULL ,
	schedule_id Integer NOT NULL ,
 Constraint pk_etlp_schedule_month primary key (schedule_month_id) 
) 
/

Create table etlp_month (
	month_id Integer NOT NULL ,
	month_name Varchar2 (20) NOT NULL  UNIQUE ,
 Constraint pk_etlp_month primary key (month_id) 
) 
/

Create table etlp_app_config (
	parameter Varchar2 (50) NOT NULL ,
	value Varchar2 (255) NOT NULL ,
	description Varchar2 (255),
 Constraint pk_etlp_app_config primary key (parameter) 
) 
/

Create table etlp_schedule_day_of_month (
	schedule_dom_id Integer NOT NULL ,
	schedule_id Integer NOT NULL ,
	schedule_dom Integer NOT NULL ,
 Constraint pk_etlp_schedule_day_of_month primary key (schedule_dom_id) 
) 
/


-- Create Alternate keys section

Alter table etlp_configuration add Constraint etlp_configuration_u1 unique (config_name) 
/
Alter table etlp_section add Constraint etlp_section_u1 unique (config_id,section_name) 
/
Alter table etlp_phase add Constraint etl_phase_u1 unique (phase_name) 
/
Alter table etlp_user add Constraint etlp_user_u1 unique (username) 
/

-- Create Indexes section

Create Index etlp_job_n1 ON etlp_job (date_created) 
/
Create Index etlp_job_n2 ON etlp_job (date_updated) 
/
Create Index etlp_item_n1 ON etlp_item (date_created) 
/
Create Index etlp_item_n2 ON etlp_item (date_updated) 
/
Create BITMAP Index etlp_item_n3 ON etlp_item (item_type) 
/
Create Index etlp_item_n4 ON etlp_item (item_name) 
/
Create Index etlp_file_process_n1 ON etlp_file_process (filename) 
/
Create Index etlp_file_process_n2 ON etlp_file_process (date_created) 
/
Create Index etlp_file_process_n3 ON etlp_file_process (date_updated) 
/
Create Index etlp_file_n1 ON etlp_file (canonical_filename) 
/
Create Index etlp_file_n2 ON etlp_file (date_created) 
/
Create Index etlp_file_n3 ON etlp_file (date_updated) 
/


-- Create Foreign keys section
Create Index IX_section_configuration_fk ON etlp_section (config_id)
/
Alter table etlp_section add Constraint section_configuration_fk foreign key (config_id) references etlp_configuration (config_id) 
/
Create Index IX_job_section_fk ON etlp_job (section_id)
/
Alter table etlp_job add Constraint job_section_fk foreign key (section_id) references etlp_section (section_id) 
/
Create Index IX_schedule_section_fk ON etlp_schedule (section_id)
/
Alter table etlp_schedule add Constraint schedule_section_fk foreign key (section_id) references etlp_section (section_id) 
/
Create Index IX_job_status ON etlp_job (status_id)
/
Alter table etlp_job add Constraint job_status foreign key (status_id) references etlp_status (status_id) 
/
Create Index IX_item_status_fk ON etlp_item (status_id)
/
Alter table etlp_item add Constraint item_status_fk foreign key (status_id) references etlp_status (status_id) 
/
Create Index IX_file_process_status_fk ON etlp_file_process (status_id)
/
Alter table etlp_file_process add Constraint file_process_status_fk foreign key (status_id) references etlp_status (status_id) 
/
Create Index IX_item_job_fk ON etlp_item (job_id)
/
Alter table etlp_item add Constraint item_job_fk foreign key (job_id) references etlp_job (job_id) 
/
Create Index IX_file_process_item ON etlp_file_process (item_id)
/
Alter table etlp_file_process add Constraint file_process_item foreign key (item_id) references etlp_item (item_id) 
/
Create Index IX_item_phase_fk ON etlp_item (phase_id)
/
Alter table etlp_item add Constraint item_phase_fk foreign key (phase_id) references etlp_phase (phase_id) 
/
Create Index IX_file_process_file_fk ON etlp_file_process (file_id)
/
Alter table etlp_file_process add Constraint file_process_file_fk foreign key (file_id) references etlp_file (file_id) 
/
Create Index IX_schedule_user_created_fk ON etlp_schedule (user_created)
/
Alter table etlp_schedule add Constraint schedule_user_created_fk foreign key (user_created) references etlp_user (user_id) 
/
Create Index IX_schedule_user_updated_fk ON etlp_schedule (user_updated)
/
Alter table etlp_schedule add Constraint schedule_user_updated_fk foreign key (user_updated) references etlp_user (user_id) 
/
Create Index IX_dow_schedule_fk ON etlp_schedule_day_of_week (schedule_id)
/
Alter table etlp_schedule_day_of_week add Constraint dow_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) 
/
Create Index IX_hour_schedule_fk ON etlp_schedule_hour (schedule_id)
/
Alter table etlp_schedule_hour add Constraint hour_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) 
/
Create Index IX_minute_schedule_fk ON etlp_schedule_minute (schedule_id)
/
Alter table etlp_schedule_minute add Constraint minute_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) 
/
Create Index IX_dom_schedule_fk ON etlp_schedule_day_of_month (schedule_id)
/
Alter table etlp_schedule_day_of_month add Constraint dom_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) 
/
Create Index IX_month_schedule_fk ON etlp_schedule_month (schedule_id)
/
Alter table etlp_schedule_month add Constraint month_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) 
/
Create Index IX_schedule_dow_fk ON etlp_schedule_day_of_week (dow_id)
/
Alter table etlp_schedule_day_of_week add Constraint schedule_dow_fk foreign key (dow_id) references etlp_day_of_week (dow_id) 
/
Create Index IX_schedule_month_fk ON etlp_schedule_month (month_id)
/
Alter table etlp_schedule_month add Constraint schedule_month_fk foreign key (month_id) references etlp_month (month_id) 
/


-- Create Object Tables section


-- Create XMLType Tables section


-- Create Procedures section


-- Create Functions section


-- Create Views section


-- Regenerate Sequences in Text Objects


-- Create Sequences section

/* Auto-created sequence for table etlp_status attribute status_id */

Create sequence sq_etlp_status_status_id
/

/* Auto-created sequence for table etlp_configuration attribute config_id */

Create sequence sq_etlp_configuration_con1
/

/* Auto-created sequence for table etlp_job attribute job_id */

Create sequence sq_etlp_job_job_id
/

/* Auto-created sequence for table etlp_file_process attribute file_proc_id */

Create sequence sq_etlp_file_process_file31
/

/* Auto-created sequence for table etlp_section attribute section_id */

Create sequence sq_etlp_section_section_id
/

/* Auto-created sequence for table etlp_phase attribute phase_id */

Create sequence sq_etlp_phase_phase_id
/

/* Auto-created sequence for table etlp_item attribute item_id */

Create sequence sq_etlp_item_item_id
/

/* Auto-created sequence for table etlp_file attribute file_id */

Create sequence sq_etlp_file_file_id
/

/* Auto-created sequence for table etlp_user attribute user_id */

Create sequence sq_etlp_user_user_id
/

/* Auto-created sequence for table etlp_schedule_minute attribute schedule_minute_id */

Create sequence sq_etlp_schedule_minute_s73
/

/* Auto-created sequence for table etlp_schedule_hour attribute schedule_hour_id */

Create sequence sq_etlp_schedule_hour_sch70
/

/* Auto-created sequence for table etlp_schedule_day_of_week attribute schedule_dow_id */

Create sequence sq_etlp_schedule_day_of_w67
/

/* Auto-created sequence for table etlp_schedule_month attribute schedule_month_id */

Create sequence sq_etlp_schedule_month_sc79
/

/* Auto-created sequence for table etlp_schedule_day_of_month attribute schedule_dom_id */

Create sequence sq_etlp_schedule_day_of_m98
/

/* Auto-created sequence for table etlp_schedule attribute schedule_id */

Create sequence sq_etlp_schedule_schedule_id
/


/* Trigger for sequence sq_etlp_status_status_id for table etlp_status attribute status_id */
Create or replace trigger t_sq_etlp_status_status_id before insert
on etlp_status for each row
begin
	SELECT sq_etlp_status_status_id.nextval INTO :new.status_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_configuration_con1 for table etlp_configuration attribute config_id */
Create or replace trigger t_sq_etlp_configuration_con1 before insert
on etlp_configuration for each row
begin
	SELECT sq_etlp_configuration_con1.nextval INTO :new.config_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_user_user_id for table etlp_user attribute user_id */
Create or replace trigger t_sq_etlp_user_user_id before insert
on etlp_user for each row
begin
	SELECT sq_etlp_user_user_id.nextval INTO :new.user_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_section_section_id for table etlp_section attribute section_id */
Create or replace trigger t_sq_etlp_section_section_id before insert
on etlp_section for each row
begin
	SELECT sq_etlp_section_section_id.nextval INTO :new.section_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_file_file_id for table etlp_file attribute file_id */
Create or replace trigger t_sq_etlp_file_file_id before insert
on etlp_file for each row
begin
	SELECT sq_etlp_file_file_id.nextval INTO :new.file_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_phase_phase_id for table etlp_phase attribute phase_id */
Create or replace trigger t_sq_etlp_phase_phase_id before insert
on etlp_phase for each row
begin
	SELECT sq_etlp_phase_phase_id.nextval INTO :new.phase_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_job_job_id for table etlp_job attribute job_id */
Create or replace trigger t_sq_etlp_job_job_id before insert
on etlp_job for each row
begin
	SELECT sq_etlp_job_job_id.nextval INTO :new.job_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_item_item_id for table etlp_item attribute item_id */
Create or replace trigger t_sq_etlp_item_item_id before insert
on etlp_item for each row
begin
	SELECT sq_etlp_item_item_id.nextval INTO :new.item_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_file_process_file31 for table etlp_file_process attribute file_proc_id */
Create or replace trigger t_sq_etlp_file_process_file31 before insert
on etlp_file_process for each row
begin
	SELECT sq_etlp_file_process_file31.nextval INTO :new.file_proc_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_minute_s73 for table etlp_schedule_minute attribute schedule_minute_id */
Create or replace trigger t_sq_etlp_schedule_minute_s73 before insert
on etlp_schedule_minute for each row
begin
	SELECT sq_etlp_schedule_minute_s73.nextval INTO :new.schedule_minute_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_hour_sch70 for table etlp_schedule_hour attribute schedule_hour_id */
Create or replace trigger t_sq_etlp_schedule_hour_sch70 before insert
on etlp_schedule_hour for each row
begin
	SELECT sq_etlp_schedule_hour_sch70.nextval INTO :new.schedule_hour_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_day_of_w67 for table etlp_schedule_day_of_week attribute schedule_dow_id */
Create or replace trigger t_sq_etlp_schedule_day_of_w67 before insert
on etlp_schedule_day_of_week for each row
begin
	SELECT sq_etlp_schedule_day_of_w67.nextval INTO :new.schedule_dow_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_month_sc79 for table etlp_schedule_month attribute schedule_month_id */
Create or replace trigger t_sq_etlp_schedule_month_sc79 before insert
on etlp_schedule_month for each row
begin
	SELECT sq_etlp_schedule_month_sc79.nextval INTO :new.schedule_month_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_day_of_m98 for table etlp_schedule_day_of_month attribute schedule_dom_id */
Create or replace trigger t_sq_etlp_schedule_day_of_m98 before insert
on etlp_schedule_day_of_month for each row
begin
	SELECT sq_etlp_schedule_day_of_m98.nextval INTO :new.schedule_dom_id FROM dual;
end;
/
 
/* Trigger for sequence sq_etlp_schedule_schedule_id for table etlp_schedule attribute schedule_id */
Create or replace trigger t_sq_etlp_schedule_schedule_id before insert
on etlp_schedule for each row
begin
	SELECT sq_etlp_schedule_schedule_id.nextval INTO :new.schedule_id FROM dual;
end;
/

-- Create Triggers from referential integrity section


-- Create user Triggers section


-- Create Packages section


-- Create Synonyms section


-- Create Roles section


-- Roles Permissions section

/* Roles permissions */


-- User Permissions section

/* Users permissions */


-- Create Table comments section

Comment on table etlp_configuration is 'Job configuration'
/
Comment on table etlp_section is 'The section within the configuration file'
/
Comment on table etlp_status is 'The ETLp status'
/
Comment on table etlp_job is 'ETLp Job'
/
Comment on table etlp_item is 'Individual processing item'
/
Comment on table etlp_phase is 'The item process phase'
/
Comment on table etlp_file_process is 'File processing'
/
Comment on table etlp_file is 'Canonical file'
/
Comment on table sessions is 'Web session information'
/
Comment on table etlp_schedule is 'A schedules task'
/
Comment on table etlp_schedule_day_of_week is 'The day of the week when the job should run'
/
Comment on table etlp_schedule_hour is 'The hours when a task is scheduled'
/
Comment on table etlp_schedule_minute is 'The minute when a task should run'
/
Comment on table etlp_day_of_week is 'The days of the week'
/
Comment on table etlp_schedule_month is 'The month (1-12) when a job is scheduled'
/
Comment on table etlp_app_config is 'Configuration settings for the etl pipeline application'
/
Comment on table etlp_schedule_day_of_month is 'The day of the month (1-31) when a job is scheduled'
/

-- Create Attribute comments section

Comment on column etlp_configuration.config_id is 'surrogate key'
/
Comment on column etlp_configuration.config_name is 'name of the configuration file'
/
Comment on column etlp_configuration.date_created is 'when the record was created'
/
Comment on column etlp_configuration.date_updated is 'when the record was updated'
/
Comment on column etlp_section.section_id is 'surrogate key'
/
Comment on column etlp_section.config_id is 'the configuration that the section belongs to'
/
Comment on column etlp_section.section_name is 'the name of the section within the controlfile'
/
Comment on column etlp_section.date_created is 'when the record was created'
/
Comment on column etlp_section.date_updated is 'when the record was updated'
/
Comment on column etlp_status.status_id is 'surrogate key'
/
Comment on column etlp_status.status_name is 'name of the status'
/
Comment on column etlp_job.job_id is 'surrogate key'
/
Comment on column etlp_job.status_id is 'the status of the job'
/
Comment on column etlp_job.section_id is 'The section that the job runs for'
/
Comment on column etlp_job.session_id is 'the database sesssion id'
/
Comment on column etlp_job.process_id is 'the operating system process id'
/
Comment on column etlp_job.message is 'any message associated with the job'
/
Comment on column etlp_job.date_created is 'when the record was created'
/
Comment on column etlp_job.date_updated is 'when the record was updated'
/
Comment on column etlp_item.item_id is 'surrogate key'
/
Comment on column etlp_item.status_id is 'the status of an item'
/
Comment on column etlp_item.job_id is 'the job that created the item'
/
Comment on column etlp_item.phase_id is 'the phase that the item belongs to'
/
Comment on column etlp_item.item_name is 'the name of the item'
/
Comment on column etlp_item.item_type is 'the type of item'
/
Comment on column etlp_item.message is 'Any message associated with the item'
/
Comment on column etlp_item.date_created is 'when the record was created'
/
Comment on column etlp_item.date_updated is 'when the record was updated'
/
Comment on column etlp_phase.phase_id is 'surrogate key'
/
Comment on column etlp_phase.phase_name is 'the name of the phase'
/
Comment on column etlp_file_process.file_proc_id is 'surrogate key'
/
Comment on column etlp_file_process.status_id is 'the status of the process step'
/
Comment on column etlp_file_process.item_id is 'the item that initiated the process'
/
Comment on column etlp_file_process.file_id is 'the canonical file'
/
Comment on column etlp_file_process.filename is 'the name of teh file being processed'
/
Comment on column etlp_file_process.record_count is 'the number of records loaded'
/
Comment on column etlp_file_process.message is 'related message'
/
Comment on column etlp_file_process.date_created is 'when the record was created'
/
Comment on column etlp_file_process.date_updated is 'when the record was updated'
/
Comment on column etlp_file.file_id is 'surrogate key'
/
Comment on column etlp_file.canonical_filename is 'name of the file being loaded'
/
Comment on column etlp_file.date_created is 'when the record was created'
/
Comment on column etlp_file.date_updated is 'when the record was updated'
/
Comment on column etlp_user.user_id is 'Surrogate key'
/
Comment on column etlp_user.username is 'unique login name'
/
Comment on column etlp_user.first_name is 'The user''s first name'
/
Comment on column etlp_user.last_name is 'The user''s last name'
/
Comment on column etlp_user.password is 'The user''s encyrpted password'
/
Comment on column etlp_user.email_address is 'The user''s email address'
/
Comment on column etlp_user.admin is 'Whether  the user has administrative privileges'
/
Comment on column etlp_user.active is 'Whether the user is active'
/
Comment on column sessions.id is 'Surrogate key'
/
Comment on column sessions.a_session is 'Session data'
/
Comment on column sessions.date_created is 'when the session was created'
/
Comment on column etlp_schedule.schedule_id is 'surrogate key'
/
Comment on column etlp_schedule.section_id is 'The task being scheduled'
/
Comment on column etlp_schedule.user_updated is 'user who updated the schedule'
/
Comment on column etlp_schedule.user_created is 'user who created the schedule'
/
Comment on column etlp_schedule.schedule_description is 'description of what the job does'
/
Comment on column etlp_schedule.schedule_comment is 'any addtionakl comment that the schedule administrator wishes to add'
/
Comment on column etlp_schedule.status is 'whether the entry is active or intactive (1 or 0)'
/
Comment on column etlp_schedule.date_created is 'when the schedule was updated'
/
Comment on column etlp_schedule.date_updated is 'when the schedule was last updated'
/
Comment on column etlp_schedule_day_of_week.schedule_dow_id is 'surrogate key'
/
Comment on column etlp_schedule_day_of_week.dow_id is 'the day of teh week that the job will run on'
/
Comment on column etlp_schedule_day_of_week.schedule_id is 'the schule this entry belongs to'
/
Comment on column etlp_schedule_hour.schedule_hour_id is 'surrogate key'
/
Comment on column etlp_schedule_hour.schedule_id is 'the schdule this entry belongs to'
/
Comment on column etlp_schedule_hour.schedule_hour is 'The hour when the job should run'
/
Comment on column etlp_schedule_minute.schedule_minute_id is 'surrogate key'
/
Comment on column etlp_schedule_minute.schedule_id is 'scheule assigned to'
/
Comment on column etlp_schedule_minute.schedule_minute is 'the minute when the job should run'
/
Comment on column etlp_day_of_week.dow_id is 'surrogate key'
/
Comment on column etlp_day_of_week.day_name is 'the name of the day'
/
Comment on column etlp_day_of_week.cron_day_id is 'cron''s represenattion of the day'
/
Comment on column etlp_schedule_month.schedule_month_id is 'surrogate key'
/
Comment on column etlp_schedule_month.month_id is 'the month that the job is scheduled to run on'
/
Comment on column etlp_schedule_month.schedule_id is 'the secdue that the entry belongs to'
/
Comment on column etlp_month.month_id is 'key (Jan = 1, Dec = 12)'
/
Comment on column etlp_month.month_name is 'name of the month'
/
Comment on column etlp_app_config.parameter is 'configuration parameter name'
/
Comment on column etlp_app_config.value is 'configuration value'
/
Comment on column etlp_app_config.description is 'description of the parameter'
/
Comment on column etlp_schedule_day_of_month.schedule_dom_id is 'surrogate key'
/
Comment on column etlp_schedule_day_of_month.schedule_dom is 'the day of the month that the job is scheduled for'
/

-- After section


