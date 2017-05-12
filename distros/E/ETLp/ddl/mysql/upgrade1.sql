/*
Created		10/04/2010
Modified		29/06/2010
Project		ETLp
Model		Model
Company		Redbone Systems Ltd
Author		Dan Horne
Version		
Database		mySQL 5 
*/


Create table etlp_configuration (
	config_id Smallint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	config_name Varchar(255) NOT NULL COMMENT 'name of the configuration file',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (config_id)) ENGINE = InnoDB
COMMENT = 'Job configuration';

Create table etlp_section (
	section_id Smallint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	config_id Smallint NOT NULL COMMENT 'the configuration that the section belongs to',
	section_name Varchar(255) NOT NULL COMMENT 'the name of the section within the controlfile',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (section_id)) ENGINE = InnoDB
COMMENT = 'The section within the configuration file';

Create table etlp_status (
	status_id Smallint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	status_name Varchar(30) NOT NULL COMMENT 'name of the status',
	UNIQUE etlp_status_u1 (status_name),
 Primary Key (status_id)) ENGINE = InnoDB
COMMENT = 'The ETLp status';

Create table etlp_job (
	job_id Bigint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	status_id Smallint NOT NULL COMMENT 'the status of the job',
	section_id Smallint NOT NULL COMMENT 'The section that the job runs for',
	session_id Int COMMENT 'the database sesssion id',
	process_id Int NOT NULL COMMENT 'the operating system process id',
	message Longtext COMMENT 'any message associated with the job',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (job_id)) ENGINE = InnoDB
COMMENT = 'ETLp Job';

Create table etlp_item (
	item_id Bigint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	status_id Smallint NOT NULL COMMENT 'the status of an item',
	job_id Bigint NOT NULL COMMENT 'the job that created the item',
	phase_id Smallint NOT NULL COMMENT 'the phase that the item belongs to',
	item_name Varchar(255) NOT NULL COMMENT 'the name of the item',
	item_type Varchar(30) NOT NULL COMMENT 'the type of item',
	message Longtext COMMENT 'Any message associated with the item',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (item_id)) ENGINE = InnoDB
COMMENT = 'Individual processing item';

Create table etlp_phase (
	phase_id Smallint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	phase_name Varchar(30) NOT NULL COMMENT 'the name of the phase',
 Primary Key (phase_id)) ENGINE = InnoDB
COMMENT = 'The item process phase';

Create table etlp_file_process (
	file_proc_id Bigint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	status_id Smallint NOT NULL COMMENT 'the status of the process step',
	item_id Bigint NOT NULL COMMENT 'the item that initiated the process',
	file_id Bigint NOT NULL COMMENT 'the canonical file',
	filename Varchar(255) NOT NULL COMMENT 'the name of teh file being processed',
	record_count Int COMMENT 'the number of records loaded',
	message Longtext COMMENT 'related message',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (file_proc_id)) ENGINE = InnoDB
COMMENT = 'File processing';

Create table etlp_file (
	file_id Bigint NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	canonical_filename Varchar(255) NOT NULL COMMENT 'name of the file being loaded',
	date_created Datetime NOT NULL COMMENT 'when the record was created',
	date_updated Datetime NOT NULL COMMENT 'when the record was updated',
 Primary Key (file_id)) ENGINE = InnoDB
COMMENT = 'Canonical file';

Create table etlp_user (
	user_id Int NOT NULL AUTO_INCREMENT COMMENT 'Surrogate key',
	username Varchar(30) NOT NULL COMMENT 'unique login name',
	first_name Varchar(50) NOT NULL COMMENT 'The user''s first name',
	last_name Varchar(30) NOT NULL COMMENT 'The user''s last name',
	password Varchar(40) NOT NULL COMMENT 'The user''s encyrpted password',
	email_address Varchar(255) COMMENT 'The user''s email address',
	admin Enum('1','0') NOT NULL DEFAULT '0' COMMENT 'Whether  the user has administrative privileges',
	active Enum('1','0') NOT NULL DEFAULT '1' COMMENT 'Whether the user is active',
 Primary Key (user_id)) ENGINE = InnoDB;

Create table sessions (
	id Varchar(32) NOT NULL COMMENT 'The session id',
	a_session Text NOT NULL COMMENT 'session data',
	date_created Timestamp NOT NULL DEFAULT current_timestamp,
 Primary Key (id)) ENGINE = MyISAM
COMMENT = 'Web session information';

Create table etlp_schedule_hour (
	schedule_hour_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	schedule_id Int NOT NULL COMMENT 'the schdule this entry belongs to',
	schedule_hour Int NOT NULL COMMENT 'The hour when the job should run',
 Primary Key (schedule_hour_id)) ENGINE = InnoDB
COMMENT = 'The hours when a task is scheduled';

Create table etlp_schedule_month (
	schedule_month_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	month_id Int NOT NULL COMMENT 'the month that the job is scheduled to run on',
	schedule_id Int NOT NULL COMMENT 'the secdue that the entry belongs to',
 Primary Key (schedule_month_id)) ENGINE = InnoDB
COMMENT = 'The month (1-12) when a job is scheduled';

Create table etlp_schedule_day_of_month (
	schedule_dom_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	schedule_id Int NOT NULL,
	schedule_dom Int NOT NULL COMMENT 'the day of the month that the job is scheduled for',
 Primary Key (schedule_dom_id)) ENGINE = InnoDB
COMMENT = 'The day of the month (1-31) when a job is scheduled';

Create table etlp_day_of_week (
	dow_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	day_name Varchar(20) NOT NULL COMMENT 'the name of the day',
	cron_day_id Int NOT NULL COMMENT 'cron''s represenattion of the day',
	UNIQUE (day_name),
 Primary Key (dow_id)) ENGINE = InnoDB
COMMENT = 'The days of the week';

Create table etlp_app_config (
	parameter Varchar(50) NOT NULL COMMENT 'configuration parameter name',
	value Varchar(255) NOT NULL COMMENT 'configuration value',
	description Varchar(255) COMMENT 'description of the parameter',
 Primary Key (parameter)) ENGINE = InnoDB
COMMENT = 'Configuration settings for the etl pipeline application';

Create table etlp_month (
	month_id Int NOT NULL AUTO_INCREMENT COMMENT 'key (Jan = 1, Dec = 12)',
	month_name Varchar(20) NOT NULL COMMENT 'name of the month',
	UNIQUE (month_name),
 Primary Key (month_id)) ENGINE = InnoDB;

Create table etlp_schedule_minute (
	schedule_minute_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	schedule_id Int NOT NULL COMMENT 'scheule assigned to',
	schedule_minute Int NOT NULL COMMENT 'the minute when the job should run',
 Primary Key (schedule_minute_id)) ENGINE = InnoDB
COMMENT = 'The minute when a task should run';

Create table etlp_schedule_day_of_week (
	schedule_dow_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	dow_id Int NOT NULL COMMENT 'the day of teh week that the job will run on',
	schedule_id Int NOT NULL COMMENT 'the schule this entry belongs to',
 Primary Key (schedule_dow_id)) ENGINE = InnoDB
COMMENT = 'The day of the week when the job should run';

Create table etlp_schedule (
	schedule_id Int NOT NULL AUTO_INCREMENT COMMENT 'surrogate key',
	section_id Smallint NOT NULL,
	user_created Int NOT NULL COMMENT 'user who created the schedule',
	user_updated Int NOT NULL COMMENT 'user who updated the schedule',
	schedule_description Longtext COMMENT 'description of what the job does',
	schedule_comment Longtext COMMENT 'any addtionakl comment that the schedule administrator wishes to add',
	status Int NOT NULL DEFAULT 1 COMMENT 'whether the entry is active or intactive (1 or 0)',
	date_created Date NOT NULL COMMENT 'when the schedule was updated',
	date_updated Date NOT NULL COMMENT 'when the schedule was last updated',
 Primary Key (schedule_id)) ENGINE = InnoDB
COMMENT = 'A schedules task';


Alter table etlp_configuration add unique etlp_configuration_u1 (config_name);
Alter table etlp_section add unique etlp_section_u1 (config_id,section_name);
Alter table etlp_phase add unique etl_phase_u1 (phase_name);
Alter table etlp_user add unique etlp_user_u1 (username);


Create Index etlp_job_n1 ON etlp_job (date_created);
Create Index etlp_job_n2 ON etlp_job (date_updated);
Create Index etlp_item_n1 ON etlp_item (date_created);
Create Index etlp_item_n2 ON etlp_item (date_updated);
Create Index etlp_item_n3 ON etlp_item (item_type);
Create Index etlp_item_n4 ON etlp_item (item_name);
Create Index etlp_file_process_n1 ON etlp_file_process (filename);
Create Index etlp_file_process_n2 ON etlp_file_process (date_created);
Create Index etlp_file_process_n3 ON etlp_file_process (date_updated);
Create Index etlp_file_n1 ON etlp_file (canonical_filename);
Create Index etlp_file_n2 ON etlp_file (date_created);
Create Index etlp_file_n3 ON etlp_file (date_updated);


Alter table etlp_section add Constraint section_configuration_fk Foreign Key (config_id) references etlp_configuration (config_id) on delete  restrict on update  restrict;
Alter table etlp_job add Constraint job_section_fk Foreign Key (section_id) references etlp_section (section_id) on delete  restrict on update  restrict;
Alter table etlp_schedule add Constraint schedule_section_fk Foreign Key (section_id) references etlp_section (section_id) on delete  restrict on update  restrict;
Alter table etlp_job add Constraint job_status Foreign Key (status_id) references etlp_status (status_id) on delete  restrict on update  restrict;
Alter table etlp_item add Constraint item_status_fk Foreign Key (status_id) references etlp_status (status_id) on delete  restrict on update  restrict;
Alter table etlp_file_process add Constraint file_process_status_fk Foreign Key (status_id) references etlp_status (status_id) on delete  restrict on update  restrict;
Alter table etlp_item add Constraint item_job_fk Foreign Key (job_id) references etlp_job (job_id) on delete  restrict on update  restrict;
Alter table etlp_file_process add Constraint file_process_item Foreign Key (item_id) references etlp_item (item_id) on delete  restrict on update  restrict;
Alter table etlp_item add Constraint item_phase_fk Foreign Key (phase_id) references etlp_phase (phase_id) on delete  restrict on update  restrict;
Alter table etlp_file_process add Constraint file_process_file_fk Foreign Key (file_id) references etlp_file (file_id) on delete  restrict on update  restrict;
Alter table etlp_schedule add Constraint schedule_user_created_fk Foreign Key (user_created) references etlp_user (user_id) on delete  restrict on update  restrict;
Alter table etlp_schedule add Constraint schedule_user_updated_fk Foreign Key (user_updated) references etlp_user (user_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_day_of_week add Constraint schedule_dow_fk Foreign Key (dow_id) references etlp_day_of_week (dow_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_month add Constraint schedule_month_fk Foreign Key (month_id) references etlp_month (month_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_day_of_week add Constraint dow_schedule_fk Foreign Key (schedule_id) references etlp_schedule (schedule_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_hour add Constraint hour_schedule_fk Foreign Key (schedule_id) references etlp_schedule (schedule_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_minute add Constraint minute_schedule_fk Foreign Key (schedule_id) references etlp_schedule (schedule_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_day_of_month add Constraint dom_schedule_fk Foreign Key (schedule_id) references etlp_schedule (schedule_id) on delete  restrict on update  restrict;
Alter table etlp_schedule_month add Constraint month_schedule_fk Foreign Key (schedule_id) references etlp_schedule (schedule_id) on delete  restrict on update  restrict;


