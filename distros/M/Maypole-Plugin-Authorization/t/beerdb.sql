-- SQL file to create SQLite 'beerdb' database for
-- Maypole::Plugin::Authorization tests

BEGIN TRANSACTION;
CREATE TABLE brewery (
    id integer  primary key,
    name varchar(30),
    url varchar(50),
    notes text
);
INSERT INTO "brewery" VALUES(1, 'St Peter''s Brewery', 'http://www.stpetersbrewery.co.uk/', NULL);

CREATE TABLE beer (
    id integer  primary key,
    brewery integer,
    style integer,
    name varchar(30),
    url varchar(120),

    score integer(2),
    price varchar(12),
    abv varchar(10),
    notes text
);
INSERT INTO "beer" VALUES(1, 1, NULL, 'Organic Best Bitter', NULL, NULL, NULL, '4.1', NULL);

CREATE TABLE handpump (
    id integer  primary key,
    beer integer,
    pub integer
);
INSERT INTO "handpump" VALUES(1, 1, 1);

CREATE TABLE pub (
    id integer  primary key,
    name varchar(60),
    url varchar(120),
    notes text
);
INSERT INTO "pub" VALUES(1, 'Turf Tavern', NULL, NULL);

CREATE TABLE style (
    id integer  primary key,
    name varchar(60),
    notes text
);

CREATE TABLE users (
    id              INT NOT NULL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    UID             VARCHAR(20) NOT NULL,
    password        VARCHAR(20) NOT NULL
);
INSERT INTO "users" VALUES(1, 'test', 'test', 'test');

CREATE TABLE auth_roles (
    id              INT NOT NULL PRIMARY KEY,
    name            VARCHAR(40) NOT NULL
);
INSERT INTO "auth_roles" VALUES(1, 'default');

CREATE TABLE role_assignments (
    id              INT NOT NULL PRIMARY KEY,
    user_id         INT NOT NULL,
    auth_role_id    INT NOT NULL
);
INSERT INTO "role_assignments" VALUES(1, 1, 1);

CREATE TABLE permissions (
    id              INT NOT NULL PRIMARY KEY,
    auth_role_id    INT NOT NULL,
    model_class     VARCHAR(100) NOT NULL,
    method          VARCHAR(100) NOT NULL
);
INSERT INTO "permissions" VALUES(1, 1, 'BeerDB::Beer', 'list');
INSERT INTO "permissions" VALUES(2, 1, 'BeerDB::Beer', 'classes');
INSERT INTO "permissions" VALUES(3, 1, 'BeerDB::Beer', 'methods');
COMMIT;
