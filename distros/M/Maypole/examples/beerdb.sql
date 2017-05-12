CREATE TABLE style (
    id integer primary key auto_increment,
    name varchar(60),
    notes text
);

CREATE TABLE pub (
    id integer primary key auto_increment,
    name varchar(60),
    url varchar(120),
    notes text
);

CREATE TABLE handpump (
    id integer primary key auto_increment,
    beer integer,
    pub integer
);

CREATE TABLE beer (
    id integer primary key auto_increment,
    brewery integer,
    style integer,
    name varchar(30),
    url varchar(120),
    score integer(2),
    price varchar(12),
    abv varchar(10),
    notes text,
	tasted date
);

CREATE TABLE brewery (
    id integer  primary key auto_increment,
    name varchar(30),
    url varchar(50),
    notes text
);
