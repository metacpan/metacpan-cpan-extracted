CREATE TABLE style (
    id integer UNSIGNED NOT NULL primary key auto_increment,
    name varchar(60),
    notes text
);

CREATE TABLE pub (
    id integer UNSIGNED NOT NULLprimary key auto_increment,
    name varchar(60),
    url varchar(120),
    notes text
);

CREATE TABLE handpump (
    id integer UNSIGNED NOT NULL primary key auto_increment,
    beer integer,
    pub integer
);

CREATE TABLE beer (
    id integer UNSIGNED NOT NULL primary key auto_increment,
    brewery integer,
    style integer,
    name varchar(30),
    score integer(2),
    price varchar(12),
    abv varchar(10),
    notes text,
	tasted date
);

CREATE TABLE brewery (
    id integer UNSIGNED NOT NULL primary key auto_increment,
    name varchar(30),
    url varchar(50),
    notes text
);

CREATE TABLE drinker (
  id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  person INTEGER UNSIGNED NOT NULL,
  handle VARCHAR(20) NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id),
  INDEX drinker_FKIndex1(person)
);

CREATE TABLE person (
  id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(50) NULL,
  sur_name VARCHAR(50) NULL,
  dob DATE NULL,
  username VARCHAR(20) NULL,
  password VARCHAR(20) NULL,
  email VARCHAR(255) NULL,
  PRIMARY KEY(id)
);

CREATE TABLE pint (
  id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  drinker INTEGER UNSIGNED NOT NULL,
  handpump INTEGER UNSIGNED NOT NULL,
  date_and_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id)
);


