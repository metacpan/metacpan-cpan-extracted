
create table brewery (
    id integer auto_increment primary key,
    name varchar(30),
    url varchar(50),
    notes text
);

create table beer (
    id integer auto_increment primary key,
    brewery integer,
    style integer,
    name varchar(30),
    url varchar(120),
#    tasted date,
    score integer(2),
    price varchar(12),
    abv varchar(10),
    notes text
);

create table handpump (
    id integer auto_increment primary key,
    beer integer,
    pub integer
);

create table pub (
    id integer auto_increment primary key,
    name varchar(60),
    url varchar(120),
    notes text
);

create table style (
    id integer auto_increment primary key,
    name varchar(60),
    notes text
);
