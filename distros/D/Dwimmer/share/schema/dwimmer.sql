CREATE TABLE config (
    id              INTEGER PRIMARY KEY,
    name            VARCHAR(30) UNIQUE NOT NULL,
    value           VARCHAR(100)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_config_name ON config (name);

CREATE TABLE user (
    id              INTEGER PRIMARY KEY,
    name            VARCHAR(30) UNIQUE NOT NULL,
    sha1            VARCHAR(255),
    email           VARCHAR(100) UNIQUE NOT NULL,
    fname           VARCHAR(100),
    lname           VARCHAR(100),
    country         VARCHAR(100),
    state           VARCHAR(100),
    validation_key  VARCHAR(255),
    verified        BOOL DEFAULT 0,
    register_ts     INTEGER DEFAULT NOW
);
-- record if the person was added manually of s/he registered?

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_email ON user (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_name  ON user (name);

CREATE TABLE site (
    id            INTEGER PRIMARY KEY,
    name          VARCHAR(100) UNIQUE NOT NULL,
    owner         INTEGER NOT NULL,
    creation_ts   INTEGER NOT NULL DEFAULT NOW ,
    FOREIGN KEY (owner) REFERENCES user(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_site_name ON site (name);

CREATE TABLE page (
    id          INTEGER PRIMARY KEY,
    revision    INTEGER NOT NULL,
    siteid      INTEGER NOT NULL,
    filename    VARCHAR(255) NOT NULL,
    redirect    VARCHAR(255),
    FOREIGN KEY (siteid) REFERENCES site(id)
);
-- the revision should be the max revision in the page_history of the same id

CREATE TABLE page_history (
    id          INTEGER PRIMARY KEY,
    pageid      INTEGER NOT NULL,
    revision    INTEGER NOT NULL,
    siteid      INTEGER NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        BLOB,
    description VARCHAR(255),
    abstract    BLOB,
    filename    VARCHAR(255) NOT NULL,
    timestamp   INTEGER NOT NULL,
    author      INTEGER NOT NULL,
    FOREIGN KEY (siteid) REFERENCES site(id),
    FOREIGN KEY (author) REFERENCES user(id),
    FOREIGN KEY (pageid) REFERENCES page(id)
);


