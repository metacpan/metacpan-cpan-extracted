use testdb;

create table t1 (
  id int primary key auto_increment,
  name varchar(40),
  unique key `name` (name)
) engine=InnoDB;

create table t2 (
  id int primary key auto_increment,
  t int,
  constraint `t` foreign key (`t`) references t1 (`id`) on delete cascade
) engine=InnoDB;

create table t1a (
  id int primary key auto_increment,
  name varchar(40),
  unique key `name` (name)
) engine=InnoDB;

create table t3 (
  id int primary key auto_increment,
  t int not null,
  constraint `t` foreign key (`t`) references t1a (`id`) on delete cascade
) engine=InnoDB;

create table t1b (
  id int primary key auto_increment,
  name varchar(40),
  unique key `name` (name)
) engine=InnoDB;

create table t4 (
  id int primary key auto_increment,
  t varchar(40) not null,
  constraint `t` foreign key (`t`) references t1b (`name`) on delete cascade
) engine=InnoDB;
