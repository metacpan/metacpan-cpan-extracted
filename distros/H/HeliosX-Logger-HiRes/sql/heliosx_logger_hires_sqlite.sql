CREATE TABLE helios_log_entry_tb (
    logid           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    log_time        DECIMAL(32,6) NOT NULL,
    host            VARCHAR(64),
    pid             INTEGER,
    jobid           INTEGER,
    jobtypeid       INTEGER,
    service         VARCHAR(128),
    priority        VARCHAR(20),
    message         BLOB
);
CREATE INDEX helios_let_lt_idx ON helios_log_entry_tb (log_time);
CREATE INDEX helios_let_lt_lid_idx ON helios_log_entry_tb (log_time, logid);
