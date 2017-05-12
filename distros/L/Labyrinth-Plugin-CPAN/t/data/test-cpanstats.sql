DROP TABLE IF EXISTS `uploads`;
CREATE TABLE `uploads` (
  `uploadid` int(10) NOT NULL AUTO_INCREMENT,
  `type` varchar(10) NOT NULL,
  `author` varchar(32) NOT NULL,
  `dist` varchar(255) NOT NULL,
  `version` varchar(255) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `released` int(10) NOT NULL,
  PRIMARY KEY (`uploadid`),
  KEY `IXDIST` (`dist`),
  KEY `IXAUTH` (`author`),
  KEY `IXDATE` (`released`),
  KEY `IXVERS` (`dist`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `uploads` VALUES (1,'backpan','BARBIE','Acme-CPANAuthors-BackPAN-OneHundred','1.00','Acme-CPANAuthors-BackPAN-OneHundred-1.00.tar.gz',1401615057);
INSERT INTO `uploads` VALUES (2,'backpan','BARBIE','Acme-CPANAuthors-BackPAN-OneHundred','1.01','Acme-CPANAuthors-BackPAN-OneHundred-1.01.tar.gz',1402193203);
INSERT INTO `uploads` VALUES (3,'backpan','BARBIE','Acme-CPANAuthors-BackPAN-OneHundred','1.02','Acme-CPANAuthors-BackPAN-OneHundred-1.02.tar.gz',1403834704);
INSERT INTO `uploads` VALUES (4,'cpan','BARBIE','Acme-CPANAuthors-BackPAN-OneHundred','1.03','Acme-CPANAuthors-BackPAN-OneHundred-1.03.tar.gz',1408262115);
INSERT INTO `uploads` VALUES (5,'cpan','BARBIE','Acme-CPANAuthors-BackPAN-OneHundred','1.04','Acme-CPANAuthors-BackPAN-OneHundred-1.04.tar.gz',1412417073);
