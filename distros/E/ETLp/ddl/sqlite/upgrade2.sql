insert into etlp_status (status_name) values ('running');
insert into etlp_status (status_name) values ('failed');
insert into etlp_status (status_name) values ('succeeded');
insert into etlp_status (status_name) values ('warning');
insert into etlp_status (status_name) values ('reaped');

insert into etlp_phase (phase_name) values ('pre_process');
insert into etlp_phase (phase_name) values ('process');
insert into etlp_phase (phase_name) values ('post_process');

insert into etlp_user(username, first_name, last_name, password, admin)
values('admin', 'The', 'Administrator', '$1$3BaXa6TV$FlY6sBRqwUZ13c7gC4DfK.',1)
;

