--- tables for mailing lists

CREATE TABLE mailing_list (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(100) UNIQUE NOT NULL,
    title   VARCHAR(100) NOT NULL,
    owner   INTEGER NOT NULL,
    from_address VARCHAR(100) NOT NULL,
    response_page            VARCHAR(50),
    validation_page          VARCHAR(50),
    validation_response_page VARCHAR(50),
    validate_template BLOB,
    confirm_template BLOB,
    FOREIGN KEY (owner) REFERENCES user(id)
);
CREATE TABLE mailing_list_member (
    id              INTEGER PRIMARY KEY,
    listid          INTEGER NOT NULL,
    email           VARCHAR(100) NOT NULL,
    validation_code VARCHAR(255) UNIQUE,
    approved        BOOL,
    register_ts     INTEGER,
    name            VARCHAR(100),

    FOREIGN KEY (listid) REFERENCES user(id)
);

--- tables to collect RSS and Atom feeds

CREATE TABLE feed_collector (
    id          INTEGER PRIMARY KEY,
    name        VARCHAR(100) UNIQUE NOT NULL,
    owner       INTEGER NOT NULL,
    created_ts  INTEGER NOT NULL,
    FOREIGN KEY (owner) REFERENCES user(id)
);

CREATE TABLE feeds (
    id          INTEGER PRIMARY KEY,
    collector   INTEGER,
    title       VARCHAR(100),
    url         VARCHAR(255),
    feed        VARCHAR(255),
    FOREIGN KEY (collector) REFERENCES feed_collector(id)
);
CREATE TABLE site_config (
    id              INTEGER PRIMARY KEY,
    siteid          INTEGER NOT NULL,
    name            VARCHAR(100) NOT NULL,
    value           VARCHAR(100)
);
PRAGMA user_version=1;
