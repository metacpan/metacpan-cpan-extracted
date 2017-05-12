CREATE TABLE helios_log_entry_tb (
    logid           BIGINT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    log_time        DECIMAL(32,6) UNSIGNED NOT NULL,
    host            VARCHAR(64),
    pid             INTEGER UNSIGNED,
    jobid           BIGINT UNSIGNED,
    jobtypeid       INT UNSIGNED,
    service         VARCHAR(128),
    priority        VARCHAR(20),
    message         MEDIUMBLOB,
    INDEX(log_time, logid)
);
CREATE INDEX helios_let_lt_idx ON helios_log_entry_tb (log_time);

