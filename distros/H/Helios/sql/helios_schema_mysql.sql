# FILE CHANGE HISTORY:
# [2012-01-08]: Added CREATE DATABASE, CREATE USER, GRANT, AND USE lines.
# [2012-05-09]: Renamed helios_schema.sql to helios_schema_mysql.sql because 
# of newly added Oracle schema support.

CREATE DATABASE helios_db;

# Uncomment the lines below and edit them to match security policies for your
# environment.  The Helios user only needs the access outlined in the GRANT 
# statement below for the core Helios system to function. 
#CREATE USER 'helios'@'%' IDENTIFIED BY '';
#GRANT INSERT,DELETE,UPDATE,SELECT ON helios_db.* TO 'helios'@'%';
#

USE helios_db;

CREATE TABLE funcmap (
        funcid         INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE job (
        jobid           BIGINT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
        funcid          INT UNSIGNED NOT NULL,
        arg             MEDIUMBLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER UNSIGNED,
        run_after       INTEGER UNSIGNED NOT NULL,
        grabbed_until   INTEGER UNSIGNED NOT NULL,
        priority        SMALLINT UNSIGNED,
        coalesce        VARCHAR(255),
        INDEX (funcid, run_after),
        UNIQUE(funcid, uniqkey),
        INDEX (funcid, coalesce)
);

CREATE TABLE note (
        jobid           BIGINT UNSIGNED NOT NULL,
        notekey         VARCHAR(255),
        PRIMARY KEY (jobid, notekey),
        value           MEDIUMBLOB
);

CREATE TABLE error (
        error_time      INTEGER UNSIGNED NOT NULL,
        jobid           BIGINT UNSIGNED NOT NULL,
        message         VARCHAR(255) NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0,
        INDEX (funcid, error_time),
        INDEX (error_time),
        INDEX (jobid)
);

CREATE TABLE exitstatus (
        jobid           BIGINT UNSIGNED PRIMARY KEY NOT NULL,
        funcid          INT UNSIGNED NOT NULL DEFAULT 0,
        status          SMALLINT UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after    INTEGER UNSIGNED,
        INDEX (funcid),
        INDEX (delete_after)
);

CREATE TABLE helios_params_tb (
    host VARCHAR(64),
    worker_class VARCHAR(64),
    param VARCHAR(64),
    value VARCHAR(128)
);

CREATE TABLE helios_class_map (
    job_type VARCHAR(32),
    job_class VARCHAR(64)
);

CREATE TABLE helios_job_history_tb (
        jobid           BIGINT UNSIGNED NOT NULL,
        funcid          INT UNSIGNED NOT NULL,
        arg             MEDIUMBLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER UNSIGNED,
        run_after       INTEGER UNSIGNED NOT NULL,
        grabbed_until   INTEGER UNSIGNED NOT NULL,
        priority        SMALLINT UNSIGNED,
        coalesce        VARCHAR(255),
        complete_time   INTEGER UNSIGNED NOT NULL,
        exitstatus      SMALLINT UNSIGNED,
        INDEX(jobid)
);

CREATE TABLE helios_log_tb (
        log_time        INTEGER UNSIGNED NOT NULL,
        host            VARCHAR(64),
        process_id      INTEGER UNSIGNED,
        jobid           BIGINT UNSIGNED,
        funcid          INT UNSIGNED,
        job_class       VARCHAR(64),
        priority        VARCHAR(20),
        message         MEDIUMBLOB,
        INDEX(log_time)
);

CREATE TABLE helios_worker_registry_tb (
    register_time    INTEGER UNSIGNED NOT NULL,
    start_time       INTEGER UNSIGNED,
	worker_class     VARCHAR(64),
	worker_version   VARCHAR(10),
	host             VARCHAR(64),
	process_id       INTEGER UNSIGNED
);

