CREATE TABLE `job` (
    `jobid`       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `funcname`    VARCHAR(200) NOT NULL,
    `arg`         MEDIUMBLOB,
    `uniqkey`     VARCHAR(255) NULL,
    `run_after`   INT UNSIGNED NOT NULL,
    `coalesce`    VARCHAR(255) NULL,
    `flag`        ENUM('controller', 'shim') DEFAULT 'shim',
    `failcount`   TINYINT UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (jobid),
    INDEX (run_after),
    UNIQUE (funcname, uniqkey)
) ENGINE=InnoDB;
