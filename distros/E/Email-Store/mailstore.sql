CREATE TABLE mail (
    message_id varchar(255) NOT NULL primary key,
    message text
);

CREATE TABLE list (
    id integer NOT NULL auto_increment primary key,
    name varchar(255),
    posting_address varchar(255)
);

CREATE TABLE list_post (
    id integer NOT NULL auto_increment primary key,
    list integer,
    mail integer
);
