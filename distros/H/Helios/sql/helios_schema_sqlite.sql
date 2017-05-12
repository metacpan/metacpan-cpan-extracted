CREATE TABLE funcmap (
        funcid         INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        funcname       VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);


CREATE TABLE job (
        jobid           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        funcid          INTEGER NOT NULL,
        arg             BLOB,
        uniqkey         VARCHAR(255),
        insert_time     INTEGER,
        run_after       INTEGER NOT NULL,
        grabbed_until   INTEGER NOT NULL,
        priority        INTEGER,
        coalesce        VARCHAR(255),
        UNIQUE(funcid, uniqkey)
);
CREATE INDEX job_fid_ra_idx ON job (funcid, run_after);
CREATE INDEX job_fid_c_idx ON job (funcid, coalesce);
CREATE INDEX job_fid_uk_index ON job (funcid, uniqkey);


CREATE TABLE note (
        jobid           INTEGER NOT NULL,
        notekey         VARCHAR(255),
        value           BLOB,
        PRIMARY KEY (jobid, notekey)
);


CREATE TABLE error (
        error_time      INTEGER NOT NULL,
        jobid           INTEGER NOT NULL,
        message         VARCHAR(255) NOT NULL,
        funcid          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX error_fid_et_idx ON error (funcid, error_time);
CREATE INDEX error_et_idx ON error (error_time);
CREATE INDEX error_jid_idx ON error (jobid);


CREATE TABLE exitstatus (
        jobid           INTEGER PRIMARY KEY NOT NULL,
        funcid          INTEGER NOT NULL DEFAULT 0,
        status          INTEGER UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after    INTEGER UNSIGNED
);
CREATE INDEX exitstatus_fid_idx ON exitstatus (funcid);
CREATE INDEX exitstatus_da_idx ON exitstatus (delete_after);


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
        jobid           INTEGER NOT NULL,
        funcid          INTEGER NOT NULL,
        arg             BLOB,
        uniqkey         VARCHAR(255) NULL,
        insert_time     INTEGER,
        run_after       INTEGER NOT NULL,
        grabbed_until   INTEGER NOT NULL,
        priority        INTEGER,
        coalesce        VARCHAR(255),
        complete_time   INTEGER NOT NULL,
        exitstatus      INTEGER
);
CREATE INDEX helios_jht_ct_idx ON helios_job_history_tb (complete_time);
CREATE INDEX helios_jht_jid_idx ON helios_job_history_tb (jobid);


CREATE TABLE helios_log_tb (
        log_time        INTEGER NOT NULL,
        host            VARCHAR(64),
        process_id      INTEGER,
        jobid           INTEGER,
        funcid          INTEGER,
        job_class       VARCHAR(64),
        priority        VARCHAR(20),
        message         BLOB
);
CREATE INDEX helios_lt_lt_idx ON helios_log_tb (log_time);


CREATE TABLE helios_worker_registry_tb (
    register_time    INTEGER NOT NULL,
    start_time       INTEGER,
	worker_class     VARCHAR(64),
	worker_version   VARCHAR(10),
	host             VARCHAR(64),
	process_id       INTEGER
);

