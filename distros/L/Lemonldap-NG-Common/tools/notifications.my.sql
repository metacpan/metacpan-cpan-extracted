CREATE TABLE notifications (
  date datetime NOT NULL,
  uid varchar(255) NOT NULL,
  ref varchar(255) NOT NULL,
  cond varchar(255) DEFAULT NULL,
  xml longblob NOT NULL,
  done datetime DEFAULT NULL,
  PRIMARY KEY (date, uid,ref)
)
