CREATE TABLE notifications (
  date timestamp NOT NULL,
  uid varchar(255) NOT NULL,
  ref varchar(255) NOT NULL,
  cond varchar(255) DEFAULT NULL,
  xml bytea NOT NULL,
  done timestamp DEFAULT NULL,
  PRIMARY KEY (date, uid,ref)
)
