Alter table etlp_section drop constraint section_configuration_fk
/
Alter table etlp_job drop constraint job_section_fk
/
Alter table etlp_job drop constraint job_status
/
Alter table etlp_item drop constraint item_status_fk
/
Alter table etlp_file_process drop constraint file_process_status_fk
/
Alter table etlp_item drop constraint item_job_fk
/
Alter table etlp_file_process drop constraint file_process_item
/
Alter table etlp_item drop constraint item_phase_fk
/
Alter table etlp_file_process drop constraint file_process_file_fk
/
Alter table etlp_schedule drop constraint schedule_user_created_fk
/
Alter table etlp_schedule drop constraint schedule_user_updated_fk
/
Alter table etlp_schedule_day_of_week drop constraint dow_schedule_fk
/
Alter table etlp_schedule_hour drop constraint hour_schedule_fk
/
Alter table etlp_schedule_minute drop constraint minute_schedule_fk
/
Alter table etlp_schedule_day_of_month drop constraint dom_schedule_fk
/
Alter table etlp_schedule_month drop constraint month_schedule_fk
/
Alter table etlp_schedule_day_of_week drop constraint schedule_dow_fk
/
Alter table etlp_schedule_month drop constraint schedule_month_fk
/


Drop table etlp_schedule_day_of_month
/
Drop table etlp_app_config
/
Drop table etlp_month
/
Drop table etlp_schedule_month
/
Drop table etlp_day_of_week
/
Drop table etlp_schedule_minute
/
Drop table etlp_schedule_hour
/
Drop table etlp_schedule_day_of_week
/
Drop table etlp_schedule
/
Drop table sessions
/
Drop table etlp_user
/
Drop table etlp_file
/
Drop table etlp_file_process
/
Drop table etlp_phase
/
Drop table etlp_item
/
Drop table etlp_job
/
Drop table etlp_status
/
Drop table etlp_section
/
Drop table etlp_configuration
/

Drop sequence sq_etlp_status_status_id
/

Drop sequence sq_etlp_configuration_con1
/

Drop sequence sq_etlp_job_job_id
/

Drop sequence sq_etlp_file_process_file31
/

Drop sequence sq_etlp_section_section_id
/

Drop sequence sq_etlp_phase_phase_id
/

Drop sequence sq_etlp_item_item_id
/

Drop sequence sq_etlp_file_file_id
/

Drop sequence sq_etlp_user_user_id
/

Drop sequence sq_etlp_schedule_minute_s73
/

Drop sequence sq_etlp_schedule_hour_sch70
/

Drop sequence sq_etlp_schedule_day_of_w67
/

Drop sequence sq_etlp_schedule_month_sc79
/

Drop sequence sq_etlp_schedule_day_of_m98
/

Drop sequence sq_etlp_schedule_schedule_id
/

