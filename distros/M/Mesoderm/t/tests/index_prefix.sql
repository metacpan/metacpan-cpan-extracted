use testdb;

create table t1 (
  id int primary key auto_increment,
  name varchar(40),
  unique key `name` (name(10))
) engine=InnoDB;


