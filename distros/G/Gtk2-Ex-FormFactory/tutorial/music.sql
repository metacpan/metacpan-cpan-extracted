create table artist (
        id              int     	not null auto_increment,
	name		varchar(255)	not null,
	notes		mediumtext,
	primary key (id)
);

create table genre (
        id              int     	not null auto_increment,
	name		varchar(255)	not null,
	primary key (id)
);

create table album (
        id              int     	not null auto_increment,
	artist		int		not null,
	genre		int,
	title		varchar(255)	not null,
	year		int,
	notes		mediumtext,
	primary key (id)
);

create table song (
        id              int     	not null auto_increment,
	album		int		not null,
	title		varchar(255)	not null,
	nr		int		not null,
	primary key (id)
);
