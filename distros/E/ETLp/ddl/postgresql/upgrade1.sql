/*
Created		10/04/2010
Modified		17/06/2010
Project		ETLp
Model			Model
Company		Redbone Systems Ltd
Author		Dan Horne
Version		
Database		PostgreSQL 8.1 
*/


/* Create Tables */


Create table etlp_configuration
(
	config_id Serial NOT NULL,
	config_name Varchar(255) NOT NULL,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_configuration primary key (config_id)
) Without Oids;


Create table etlp_section
(
	section_id Serial NOT NULL,
	config_id Integer NOT NULL,
	section_name Varchar(255) NOT NULL,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_section primary key (section_id)
) Without Oids;


Create table etlp_status
(
	status_id Serial NOT NULL,
	status_name Varchar(30) NOT NULL Constraint etlp_status_u1 UNIQUE,
constraint pk_etlp_status primary key (status_id)
) Without Oids;


Create table etlp_job
(
	job_id Serial NOT NULL,
	status_id Integer NOT NULL,
	section_id Integer NOT NULL,
	session_id Integer,
	process_id Integer NOT NULL,
	message Text,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_job primary key (job_id)
) Without Oids;


Create table etlp_item
(
	item_id Serial NOT NULL,
	status_id Integer NOT NULL,
	job_id Integer NOT NULL,
	phase_id Integer NOT NULL,
	item_name Varchar(255) NOT NULL,
	item_type Varchar(30) NOT NULL,
	message Text,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_item primary key (item_id)
) Without Oids;


Create table etlp_phase
(
	phase_id Serial NOT NULL,
	phase_name Varchar(30) NOT NULL,
constraint pk_etlp_phase primary key (phase_id)
) Without Oids;


Create table etlp_file_process
(
	file_proc_id Serial NOT NULL,
	status_id Integer NOT NULL,
	item_id Integer NOT NULL,
	file_id Integer NOT NULL,
	filename Varchar(255) NOT NULL,
	record_count Integer,
	message Text,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_file_process primary key (file_proc_id)
) Without Oids;


Create table etlp_file
(
	file_id Serial NOT NULL,
	canonical_filename Varchar(255) NOT NULL,
	date_created Timestamp(0) NOT NULL,
	date_updated Timestamp(0) NOT NULL,
constraint pk_etlp_file primary key (file_id)
) Without Oids;


Create table etlp_user
(
	user_id Serial NOT NULL,
	username Varchar(30) NOT NULL,
	first_name Varchar(50) NOT NULL,
	last_name Varchar(30) NOT NULL,
	password Varchar(40) NOT NULL,
	email_address Varchar(255),
	admin Integer NOT NULL Default 0 Constraint etlp_user_ck1 Check (admin in (1,0)),
	active Integer NOT NULL Default 1 Constraint etlp_user_ck2 Check (active in (1,0)),
constraint pk_etlp_user primary key (user_id)
) Without Oids;


Create table sessions
(
	id Varchar(32) NOT NULL,
	a_session Varchar(4000) NOT NULL,
	date_created Timestamp(0) NOT NULL,
constraint pk_sessions primary key (id)
) Without Oids;


Create table etlp_schedule_hour
(
	schedule_hour_id Integer NOT NULL,
	schedule_id Integer NOT NULL,
	schedule_hour Integer NOT NULL,
constraint pk_etlp_schedule_hour primary key (schedule_hour_id)
) Without Oids;


Create table etlp_schedule_month
(
	schedule_month_id Integer NOT NULL,
	month_id Integer NOT NULL,
	schedule_id Integer NOT NULL,
constraint pk_etlp_schedule_month primary key (schedule_month_id)
) Without Oids;


Create table etlp_day_of_week
(
	dow_id Integer NOT NULL,
	day_name Varchar(20) NOT NULL UNIQUE,
	cron_day_id Integer NOT NULL,
constraint pk_etlp_day_of_week primary key (dow_id)
) Without Oids;


Create table etlp_app_config
(
	parameter Varchar(50) NOT NULL,
	value Varchar(255) NOT NULL,
	description Varchar(255),
constraint pk_etlp_app_config primary key (parameter)
) Without Oids;


Create table etlp_month
(
	month_id Integer NOT NULL,
	month_name Varchar(20) NOT NULL UNIQUE,
constraint pk_etlp_month primary key (month_id)
) Without Oids;


Create table etlp_schedule_minute
(
	schedule_minute_id Integer NOT NULL,
	schedule_id Integer NOT NULL,
	schedule_minute Integer NOT NULL,
constraint pk_etlp_schedule_minute primary key (schedule_minute_id)
) Without Oids;


Create table etlp_schedule_day_of_week
(
	schedule_dow_id Integer NOT NULL,
	dow_id Integer NOT NULL,
	schedule_id Integer NOT NULL,
constraint pk_etlp_schedule_day_of_week primary key (schedule_dow_id)
) Without Oids;


Create table etlp_schedule
(
	schedule_id Serial NOT NULL,
	user_created Integer NOT NULL,
	user_updated Integer NOT NULL,
	section_id Integer NOT NULL,
	schedule_description Text,
	schedule_comment Text,
	status Integer NOT NULL Default 1,
	date_created Date NOT NULL,
	date_updated Date NOT NULL,
constraint pk_etlp_schedule primary key (schedule_id)
) Without Oids;


Create table etlp_schedule_day_of_month
(
	schedule_dom_id Integer NOT NULL,
	schedule_id Integer NOT NULL,
	schedule_dom Integer NOT NULL,
constraint pk_etlp_schedule_day_of_month primary key (schedule_dom_id)
) Without Oids;


/* Create Tab 'Others' for Selected Tables */


/* Create Alternate Keys */
Alter Table etlp_configuration add Constraint etlp_configuration_u1 UNIQUE (config_name);
Alter Table etlp_section add Constraint etlp_section_u1 UNIQUE (config_id,section_name);
Alter Table etlp_phase add Constraint etl_phase_u1 UNIQUE (phase_name);
Alter Table etlp_user add Constraint etlp_user_u1 UNIQUE (username);


/* Create Indexes */
Create index etlp_job_n1 on etlp_job using btree (date_created);
Create index etlp_job_n2 on etlp_job using btree (date_updated);
Create index etlp_item_n1 on etlp_item using btree (date_created);
Create index etlp_item_n2 on etlp_item using btree (date_updated);
Create index etlp_item_n3 on etlp_item using btree (item_type);
Create index etlp_item_n4 on etlp_item using btree (item_name);
Create index etlp_file_process_n1 on etlp_file_process using btree (filename);
Create index etlp_file_process_n2 on etlp_file_process using btree (date_created);
Create index etlp_file_process_n3 on etlp_file_process using btree (date_updated);
Create index etlp_file_n1 on etlp_file using btree (canonical_filename);
Create index etlp_file_n2 on etlp_file using btree (date_created);
Create index etlp_file_n3 on etlp_file using btree (date_updated);


/* Create Foreign Keys */
Create index IX_section_configuration_fk_etlp_section on etlp_section (config_id);
Alter table etlp_section add Constraint section_configuration_fk foreign key (config_id) references etlp_configuration (config_id) on update restrict on delete restrict;
Create index IX_job_section_fk_etlp_job on etlp_job (section_id);
Alter table etlp_job add Constraint job_section_fk foreign key (section_id) references etlp_section (section_id) on update restrict on delete restrict;
Create index IX_schedule_section_fk_etlp_schedule on etlp_schedule (section_id);
Alter table etlp_schedule add Constraint schedule_section_fk foreign key (section_id) references etlp_section (section_id) on update restrict on delete restrict;
Create index IX_job_status_etlp_job on etlp_job (status_id);
Alter table etlp_job add Constraint job_status foreign key (status_id) references etlp_status (status_id) on update restrict on delete restrict;
Create index IX_item_status_fk_etlp_item on etlp_item (status_id);
Alter table etlp_item add Constraint item_status_fk foreign key (status_id) references etlp_status (status_id) on update restrict on delete restrict;
Create index IX_file_process_status_fk_etlp_file_process on etlp_file_process (status_id);
Alter table etlp_file_process add Constraint file_process_status_fk foreign key (status_id) references etlp_status (status_id) on update restrict on delete restrict;
Create index IX_item_job_fk_etlp_item on etlp_item (job_id);
Alter table etlp_item add Constraint item_job_fk foreign key (job_id) references etlp_job (job_id) on update restrict on delete restrict;
Create index IX_file_process_item_etlp_file_process on etlp_file_process (item_id);
Alter table etlp_file_process add Constraint file_process_item foreign key (item_id) references etlp_item (item_id) on update restrict on delete restrict;
Create index IX_item_phase_fk_etlp_item on etlp_item (phase_id);
Alter table etlp_item add Constraint item_phase_fk foreign key (phase_id) references etlp_phase (phase_id) on update restrict on delete restrict;
Create index IX_file_process_file_fk_etlp_file_process on etlp_file_process (file_id);
Alter table etlp_file_process add Constraint file_process_file_fk foreign key (file_id) references etlp_file (file_id) on update restrict on delete restrict;
Create index IX_schedule_user_created_fk_etlp_schedule on etlp_schedule (user_created);
Alter table etlp_schedule add Constraint schedule_user_created_fk foreign key (user_created) references etlp_user (user_id) on update restrict on delete restrict;
Create index IX_schedule_user_updated_fk_etlp_schedule on etlp_schedule (user_updated);
Alter table etlp_schedule add Constraint schedule_user_updated_fk foreign key (user_updated) references etlp_user (user_id) on update restrict on delete restrict;
Create index IX_schedule_dow_fk_etlp_schedule_day_of_week on etlp_schedule_day_of_week (dow_id);
Alter table etlp_schedule_day_of_week add Constraint schedule_dow_fk foreign key (dow_id) references etlp_day_of_week (dow_id) on update restrict on delete restrict;
Create index IX_schedule_month_fk_etlp_schedule_month on etlp_schedule_month (month_id);
Alter table etlp_schedule_month add Constraint schedule_month_fk foreign key (month_id) references etlp_month (month_id) on update restrict on delete restrict;
Create index IX_dow_schedule_fk_etlp_schedule_day_of_week on etlp_schedule_day_of_week (schedule_id);
Alter table etlp_schedule_day_of_week add Constraint dow_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) on update restrict on delete restrict;
Create index IX_hour_schedule_fk_etlp_schedule_hour on etlp_schedule_hour (schedule_id);
Alter table etlp_schedule_hour add Constraint hour_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) on update restrict on delete restrict;
Create index IX_minute_schedule_fk_etlp_schedule_minute on etlp_schedule_minute (schedule_id);
Alter table etlp_schedule_minute add Constraint minute_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) on update restrict on delete restrict;
Create index IX_dom_schedule_fk_etlp_schedule_day_of_month on etlp_schedule_day_of_month (schedule_id);
Alter table etlp_schedule_day_of_month add Constraint dom_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) on update restrict on delete restrict;
Create index IX_month_schedule_fk_etlp_schedule_month on etlp_schedule_month (schedule_id);
Alter table etlp_schedule_month add Constraint month_schedule_fk foreign key (schedule_id) references etlp_schedule (schedule_id) on update restrict on delete restrict;


/* Create Procedures */


/* Create Views */


/* Create Referential Integrity Triggers */


/* Create User-Defined Triggers */


/* Create Roles */


/* Add Roles To Roles */


/* Create Role Permissions */
/* Role permissions on tables */

/* Role permissions on views */

/* Role permissions on procedures */


/* Create Comment on Tables */
Comment on table etlp_configuration is 'Job configuration';
Comment on table etlp_section is 'The section within the configuration file';
Comment on table etlp_status is 'The ETLp status';
Comment on table etlp_job is 'ETLp Job';
Comment on table etlp_item is 'Individual processing item';
Comment on table etlp_phase is 'The item process phase';
Comment on table etlp_file_process is 'File processing';
Comment on table etlp_file is 'Canonical file';
Comment on table sessions is 'Web session information';
Comment on table etlp_schedule_hour is 'The hours when a task is scheduled';
Comment on table etlp_schedule_month is 'The month (1-12) when a job is scheduled';
Comment on table etlp_day_of_week is 'The days of the week';
Comment on table etlp_app_config is 'Configuration settings for the etl pipeline application';
Comment on table etlp_schedule_minute is 'The minute when a task should run';
Comment on table etlp_schedule_day_of_week is 'The day of the week when the job should run';
Comment on table etlp_schedule is 'A schedules task';
Comment on table etlp_schedule_day_of_month is 'The day of the month (1-31) when a job is scheduled';


/* Create Comment on Columns */
Comment on column etlp_configuration.config_id is 'surrogate key';
Comment on column etlp_configuration.config_name is 'name of the configuration file';
Comment on column etlp_configuration.date_created is 'when the record was created';
Comment on column etlp_configuration.date_updated is 'when the record was updated';
Comment on column etlp_section.section_id is 'surrogate key';
Comment on column etlp_section.config_id is 'the configuration that the section belongs to';
Comment on column etlp_section.section_name is 'the name of the section within the controlfile';
Comment on column etlp_section.date_created is 'when the record was created';
Comment on column etlp_section.date_updated is 'when the record was updated';
Comment on column etlp_status.status_id is 'surrogate key';
Comment on column etlp_status.status_name is 'name of the status';
Comment on column etlp_job.job_id is 'surrogate key';
Comment on column etlp_job.status_id is 'the status of the job';
Comment on column etlp_job.section_id is 'The section that the job runs for';
Comment on column etlp_job.session_id is 'the database sesssion id';
Comment on column etlp_job.process_id is 'the operating system process id';
Comment on column etlp_job.message is 'any message associated with the job';
Comment on column etlp_job.date_created is 'when the record was created';
Comment on column etlp_job.date_updated is 'when the record was updated';
Comment on column etlp_item.item_id is 'surrogate key';
Comment on column etlp_item.status_id is 'the status of an item';
Comment on column etlp_item.job_id is 'the job that created the item';
Comment on column etlp_item.phase_id is 'the phase that the item belongs to';
Comment on column etlp_item.item_name is 'the name of the item';
Comment on column etlp_item.item_type is 'the type of item';
Comment on column etlp_item.message is 'Any message associated with the item';
Comment on column etlp_item.date_created is 'when the record was created';
Comment on column etlp_item.date_updated is 'when the record was updated';
Comment on column etlp_phase.phase_id is 'surrogate key';
Comment on column etlp_phase.phase_name is 'the name of the phase';
Comment on column etlp_file_process.file_proc_id is 'surrogate key';
Comment on column etlp_file_process.status_id is 'the status of the process step';
Comment on column etlp_file_process.item_id is 'the item that initiated the process';
Comment on column etlp_file_process.file_id is 'the canonical file';
Comment on column etlp_file_process.filename is 'the name of teh file being processed';
Comment on column etlp_file_process.record_count is 'the number of records loaded';
Comment on column etlp_file_process.message is 'related message';
Comment on column etlp_file_process.date_created is 'when the record was created';
Comment on column etlp_file_process.date_updated is 'when the record was updated';
Comment on column etlp_file.file_id is 'surrogate key';
Comment on column etlp_file.canonical_filename is 'name of the file being loaded';
Comment on column etlp_file.date_created is 'when the record was created';
Comment on column etlp_file.date_updated is 'when the record was updated';
Comment on column etlp_user.user_id is 'Surrogate key';
Comment on column etlp_user.username is 'unique login name';
Comment on column etlp_user.first_name is 'The user''s first name';
Comment on column etlp_user.last_name is 'The user''s last name';
Comment on column etlp_user.password is 'The user''s encyrpted password';
Comment on column etlp_user.email_address is 'The user''s email address';
Comment on column etlp_user.admin is 'Whether  the user has administrative privileges';
Comment on column etlp_user.active is 'Whether the user is active';
Comment on column sessions.id is 'Surrogate key';
Comment on column sessions.a_session is 'Session data';
Comment on column sessions.date_created is 'when the session was created';
Comment on column etlp_schedule_hour.schedule_hour_id is 'surrogate key';
Comment on column etlp_schedule_hour.schedule_id is 'the schdule this entry belongs to';
Comment on column etlp_schedule_hour.schedule_hour is 'The hour when the job should run';
Comment on column etlp_schedule_month.schedule_month_id is 'surrogate key';
Comment on column etlp_schedule_month.month_id is 'the month that the job is scheduled to run on';
Comment on column etlp_schedule_month.schedule_id is 'the secdue that the entry belongs to';
Comment on column etlp_day_of_week.dow_id is 'surrogate key';
Comment on column etlp_day_of_week.day_name is 'the name of the day';
Comment on column etlp_day_of_week.cron_day_id is 'cron''s represenattion of the day';
Comment on column etlp_app_config.parameter is 'configuration parameter name';
Comment on column etlp_app_config.value is 'configuration value';
Comment on column etlp_app_config.description is 'description of the parameter';
Comment on column etlp_month.month_id is 'key (Jan = 1, Dec = 12)';
Comment on column etlp_month.month_name is 'name of the month';
Comment on column etlp_schedule_minute.schedule_minute_id is 'surrogate key';
Comment on column etlp_schedule_minute.schedule_id is 'scheule assigned to';
Comment on column etlp_schedule_minute.schedule_minute is 'the minute when the job should run';
Comment on column etlp_schedule_day_of_week.schedule_dow_id is 'surrogate key';
Comment on column etlp_schedule_day_of_week.dow_id is 'the day of teh week that the job will run on';
Comment on column etlp_schedule_day_of_week.schedule_id is 'the schule this entry belongs to';
Comment on column etlp_schedule.schedule_id is 'surrogate key';
Comment on column etlp_schedule.user_created is 'user who created the schedule';
Comment on column etlp_schedule.user_updated is 'user wh updated the schedule';
Comment on column etlp_schedule.section_id is 'the task being scheduled';
Comment on column etlp_schedule.schedule_description is 'description of what the job does';
Comment on column etlp_schedule.schedule_comment is 'any addtionakl comment that the schedule administrator wishes to add';
Comment on column etlp_schedule.status is 'whether the entry is active or intactive (1 or 0)';
Comment on column etlp_schedule.date_created is 'when the schedule was updated';
Comment on column etlp_schedule.date_updated is 'when the schedule was last updated';
Comment on column etlp_schedule_day_of_month.schedule_dom_id is 'surrogate key';
Comment on column etlp_schedule_day_of_month.schedule_dom is 'the day of the month that the job is scheduled for';


/* Create Comment on Domains and Types */


/* Create Comment on Indexes */


