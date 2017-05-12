--
-- This file has table definitions and some data 
-- for guests demo
--

--
-- Table structure for table `guests`
--

CREATE TABLE guests (
  rid int(10) unsigned NOT NULL auto_increment,
  date date default NULL,
  lname varchar(25) default NULL,
  fname varchar(25) default NULL,
  comment varchar(50) default NULL,
  mrktbl_code varchar(6) default NULL,
  intrst_code varchar(6) default NULL,
  note varchar(255) default NULL,
  email varchar(100) default NULL,
  cityname varchar(17) default NULL,
  streetname varchar(21) default NULL,
  housenum varchar(6) default NULL,
  zipcode int(11) default '0',
  phone1 varchar(15) default NULL,
  phone2 varchar(15) default NULL,
  sid varchar(20) default NULL,
  PRIMARY KEY  (rid)
) TYPE=MyISAM;

--
-- Table structure for table `tbl`
--

CREATE TABLE tbl (
  rid int(11) NOT NULL auto_increment,
  tbl varchar(6) default NULL,
  langug_code varchar(6) default NULL,
  code varchar(6) default NULL,
  name varchar(50) default NULL,
  number float default NULL,
  note varchar(255) default NULL,
  realm_id int(11) default NULL,
  PRIMARY KEY  (rid),
  UNIQUE KEY ux_tbl (tbl,langug_code,code),
  KEY x_langug_code (langug_code)
) TYPE=MyISAM;


--
-- Dumping data for table `tbl`
--


INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (129,'','en','LANGUG','labguage table',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (136,'','en','MRKTBL','טבלת ציונים',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (138,'','en','INTRST','Intersts',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (188,'INTRST','en','1','Linux',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (190,'INTRST','en','2','Internet',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (192,'INTRST','en','3','Intranet',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (194,'INTRST','en','4','Client Server',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (196,'INTRST','en','5','Apache',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (198,'INTRST','en','6','Perl',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (200,'INTRST','en','7','Merge',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (202,'INTRST','en','8','Magic',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (204,'INTRST','en','9','Informix',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (206,'INTRST','en','10','Oracle',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (208,'INTRST','en','11','MySql',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (210,'INTRST','en','12','Visual Basic',0,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (212,'LANGUG','','en','ISO-8859-1',0,'LTR',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (219,'MRKTBL','en','1','1',1,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (221,'MRKTBL','en','2','2',2,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (223,'MRKTBL','en','3','3',3,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (225,'MRKTBL','en','4','4',4,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (227,'MRKTBL','en','5','5',5,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (229,'MRKTBL','en','6','6',6,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (231,'MRKTBL','en','7','7',7,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (233,'MRKTBL','en','8','8',8,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (235,'MRKTBL','en','9','9',9,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (237,'MRKTBL','en','10','10',10,'',0);
INSERT INTO tbl (rid, tbl, langug_code, code, name, number, note, realm_id) VALUES (239,'NULL','en','FRMSTR','Form strings',0,'NULL',0);

--
-- Dumping data for table `guests`
--

INSERT INTO guests (rid, date, lname, fname, comment, mrktbl_code, intrst_code, note, email, cityname, streetname, housenum, zipcode, phone1, phone2, sid) VALUES (1,'2001-01-07','Illouz','Roi','nice site','9','1','','','','','',0,'','','987299');
INSERT INTO guests (rid, date, lname, fname, comment, mrktbl_code, intrst_code, note, email, cityname, streetname, housenum, zipcode, phone1, phone2, sid) VALUES (47,'2001-03-22','illouz','Roi','shlom','9','5','','','','','',0,'','','98509');
INSERT INTO guests (rid, date, lname, fname, comment, mrktbl_code, intrst_code, note, email, cityname, streetname, housenum, zipcode, phone1, phone2, sid) VALUES (46,'2001-03-22','Oval','shape','nice !!!','7','8','','','','','',0,'','','9850979');
INSERT INTO guests (rid, date, lname, fname, comment, mrktbl_code, intrst_code, note, email, cityname, streetname, housenum, zipcode, phone1, phone2, sid) VALUES (54,'2001-05-31','Rabbit','Rogger','Nice Site!','8','2','','','Haifa','','',0,'','','9899');

