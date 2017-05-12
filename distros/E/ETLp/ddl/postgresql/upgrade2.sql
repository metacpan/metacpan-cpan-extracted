insert into etlp_status (status_name) values ('running')
;
insert into etlp_status (status_name) values ('failed')
;
insert into etlp_status (status_name) values ('succeeded')
;
insert into etlp_status (status_name) values ('warning')
;
insert into etlp_status (status_name) values ('reaped')
;

insert into etlp_phase (phase_name) values ('pre_process')
;
insert into etlp_phase (phase_name) values ('process')
;
insert into etlp_phase (phase_name) values ('post_process')
;

insert into etlp_user(username, first_name, last_name, password, admin)
values('admin', 'The', 'Administrator', '$1$3BaXa6TV$FlY6sBRqwUZ13c7gC4DfK.',1)
;

insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(1, 'Monday', 1)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(2, 'Tuesday', 2)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(3, 'Wednesday', 3)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(4, 'Thursday', 4)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(5, 'Friday', 5)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(6, 'Saturday', 6)
;
insert into etlp_day_of_week(dow_id, day_name, cron_day_id)
values(7, 'Sunday', 0)
;

insert into etlp_month (month_id, month_name) values (1, 'January');
insert into etlp_month (month_id, month_name) values (2, 'February');
insert into etlp_month (month_id, month_name) values (3, 'March');
insert into etlp_month (month_id, month_name) values (4, 'April');
insert into etlp_month (month_id, month_name) values (5, 'May');
insert into etlp_month (month_id, month_name) values (6, 'June');
insert into etlp_month (month_id, month_name) values (7, 'July');
insert into etlp_month (month_id, month_name) values (8, 'August');
insert into etlp_month (month_id, month_name) values (9, 'September');
insert into etlp_month (month_id, month_name) values (10, 'October');
insert into etlp_month (month_id, month_name) values (11, 'November');
insert into etlp_month (month_id, month_name) values (12, 'December');

insert into etlp_app_config(parameter, value, description) values ('scheduler status', 'enabled', 'Whether the scheduler is enabled'); 