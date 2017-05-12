DROP TABLE IF EXISTS attachments;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS assets;

create table attachments (
    id integer NOT NULL AUTO_INCREMENT,
    message_id integer NOT NULL,
    filename varchar(120),
    contenttype varchar(200),
    encoding varchar(20),
    attachment TEXT,
    PRIMARY KEY (id)
);

create table messages (
    id integer NOT NULL AUTO_INCREMENT,
    from_address varchar(255),
    subject varchar(255),
    received DATETIME,
    content TEXT,
    PRIMARY KEY (id)
);
create index message_from_ix on messages (from_address,id);
create index subject_ix on messages (subject,id);

create table assets (
    id integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
    message_id integer NOT NULL,
    creator varchar(128),
    asset TEXT
);
create index creator_ix on assets (creator,message_id);
