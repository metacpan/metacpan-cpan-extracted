CREATE TABLE `identificators` (
    `id`    INTEGER PRIMARY KEY AUTO_INCREMENT,
    `jid`   VARCHAR(255) NOT NULL,

    UNIQUE(`jid`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `messages` (
    `sender`    INTEGER,
    `sender_resource` VARCHAR(255) DEFAULT '',

    `recipient` INTEGER,
    `recipient_resource` VARCHAR(255) DEFAULT '',

    `id`        VARCHAR(255) DEFAULT NULL,
    `type`      VARCHAR(255) DEFAULT NULL,
    `body`      TEXT,
    `thread`    VARCHAR(255) DEFAULT NULL,

    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(`sender`)
        REFERENCES `identificators`(`id`),

    FOREIGN KEY(`recipient`)
        REFERENCES `identificators`(`id`)
) DEFAULT CHARSET=utf8;
