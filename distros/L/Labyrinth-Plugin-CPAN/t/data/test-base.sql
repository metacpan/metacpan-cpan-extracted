DROP TABLE IF EXISTS `access`;
CREATE TABLE `access` (
  `accessid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessname` varchar(255) DEFAULT NULL,
  `accesslevel` int(4) DEFAULT NULL,
  PRIMARY KEY (`accessid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `access` VALUES (1,'reader',1);
INSERT INTO `access` VALUES (2,'editor',2);
INSERT INTO `access` VALUES (3,'publisher',3);
INSERT INTO `access` VALUES (4,'admin',4);
INSERT INTO `access` VALUES (5,'master',5);

DROP TABLE IF EXISTS `acls`;
CREATE TABLE `acls` (
  `aclid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned DEFAULT '0',
  `userid` int(10) unsigned DEFAULT '0',
  `accessid` int(4) DEFAULT NULL,
  PRIMARY KEY (`aclid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `acls` VALUES (1,1,9,0,5);
INSERT INTO `acls` VALUES (2,1,1,0,1);

DROP TABLE IF EXISTS `folders`;
CREATE TABLE `folders` (
  `folderid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent` int(10) DEFAULT NULL,
  `accessid` int(10) NOT NULL DEFAULT '5',
  PRIMARY KEY (`folderid`),
  KEY `IXPATH` (`path`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `folders` VALUES (1,'public',0,1);

DROP TABLE IF EXISTS `groups`;
CREATE TABLE `groups` (
  `groupid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `master` int(2) DEFAULT '0',
  `member` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `groups` VALUES (1,'public',1,'Guest');
INSERT INTO `groups` VALUES (2,'writers',1,'Writer');
INSERT INTO `groups` VALUES (3,'editors',1,'Editor');
INSERT INTO `groups` VALUES (5,'admins',1,'Admin');
INSERT INTO `groups` VALUES (9,'masters',1,'Master');

DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
  `imageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tag` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `link` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` int(4) DEFAULT NULL,
  `href` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dimensions` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`imageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `images` VALUES (1,NULL,'images/blank.png',1,NULL,NULL);

DROP TABLE IF EXISTS `imagestock`;
CREATE TABLE `imagestock` (
  `stockid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`stockid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `imagestock` VALUES (1,'Public','images/public');
INSERT INTO `imagestock` VALUES (2,'Random','images/public');
INSERT INTO `imagestock` VALUES (3,'Advert','images/adverts');
INSERT INTO `imagestock` VALUES (4,'User','images/users');
INSERT INTO `imagestock` VALUES (5,'Layout','images/layout');
INSERT INTO `imagestock` VALUES (9,'DRAFT','images/draft');
INSERT INTO `imagestock` VALUES (6,'Timesheets','data/timesheets');

DROP TABLE IF EXISTS `ixusergroup`;
CREATE TABLE `ixusergroup` (
  `indexid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` int(1) unsigned NOT NULL DEFAULT '0',
  `linkid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`indexid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `ixusergroup` VALUES (1,1,1,1);
INSERT INTO `ixusergroup` VALUES (2,1,1,9);

DROP TABLE IF EXISTS `realms`;
CREATE TABLE `realms` (
  `realmid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `realm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `command` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`realmid`),
  KEY `IXREALM` (`realm`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `realms` VALUES (1,'public','Public Interface','home-main');
INSERT INTO `realms` VALUES (2,'admin','Admin Interface','home-admin');

DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
  `sessionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `labyrinth` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `realm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `timeout` int(11) unsigned NOT NULL DEFAULT '0',
  `langcode` char(2) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'en',
  `query` blob,
  PRIMARY KEY (`sessionid`),
  KEY `IXLAB` (`labyrinth`),
  KEY `IXTIMEOUT` (`timeout`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `userid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned NOT NULL DEFAULT '1',
  `nickname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `realname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `realm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `aboutme` blob,
  `search` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`userid`),
  KEY `IXNAME` (`realname`),
  KEY `IXENMAIL` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `users` VALUES (1,1,1,'Guest','guest','GUEST','public','c8d6ea7f8e6850e9ed3b642900ca27683a257201',NULL,NULL,0);
INSERT INTO `users` VALUES (2,5,1,'Barbie','Barbie','barbie@example.com','admin',sha1('test'),'','',1);


DROP TABLE IF EXISTS `articles`;
CREATE TABLE `articles` (
  `articleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `createdate` varchar(255) DEFAULT NULL,
  `sectionid` int(10) unsigned NOT NULL DEFAULT '0',
  `quickname` varchar(32) DEFAULT NULL,
  `snippet` varchar(255) DEFAULT NULL,
  `imageid` int(10) unsigned DEFAULT '1',
  `front` int(1) DEFAULT '0',
  `latest` int(1) DEFAULT '0',
  `publish` int(4) DEFAULT NULL,
  PRIMARY KEY (`articleid`),
  INDEX FLDIX (`folderid`),
  INDEX USRIX (`userid`),
  INDEX SECIX (`sectionid`),
  INDEX NAMIX (`quickname`),
  INDEX PUBIX (`publish`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

DROP TABLE IF EXISTS `mxarticles`;
CREATE TABLE `mxarticles` (
  `articleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `metadata` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`articleid`,`metadata`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

DROP TABLE IF EXISTS `paragraphs`;
CREATE TABLE `paragraphs` (
  `paraid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `articleid` int(10) unsigned NOT NULL DEFAULT '0',
  `orderno` int(4) DEFAULT NULL,
  `type` int(4) DEFAULT NULL,
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `href` varchar(255) DEFAULT NULL,
  `body` blob,
  `align` int(4) DEFAULT NULL,
  PRIMARY KEY (`paraid`),
  INDEX ARTIX (`articleid`),
  INDEX IMGIX (`imageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

DROP TABLE IF EXISTS `profile`;
CREATE TABLE `profile` (
  `testerid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `pause` varchar(255) DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`testerid`),
  KEY `IXNAME` (`name`),
  KEY `IXPAUSE` (`pause`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `profile` VALUES (1,'Barbie','BARBIE','barbie@cpan.org');
INSERT INTO `profile` VALUES (2,'Barbie',NULL,'barbie@cpantesters.org');


DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
  `addressid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `testerid` int(10) unsigned NOT NULL DEFAULT '0',
  `address` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`addressid`),
  KEY `IXTESTER` (`testerid`),
  KEY `IXADDRESS` (`address`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO `address` VALUES (1,0,'neil@bowers.com','neil@bowers.com');
INSERT INTO `address` VALUES (2,2,'barbie@cpantesters.org','barbie@cpantesters.org');
INSERT INTO `address` VALUES (3,1,'barbie@missbarbell.co.uk (Barbie)','barbie@missbarbell.co.uk');
INSERT INTO `address` VALUES (4,1,'Barbie <barbie@missbarbell.co.uk>','barbie@missbarbell.co.uk');

DROP TABLE IF EXISTS `ixreport`;
CREATE TABLE `ixreport` (
  `id` int(10) unsigned NOT NULL,
  `guid` varchar(40) NOT NULL DEFAULT '',
  `addressid` int(10) unsigned NOT NULL,
  `fulldate` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`,`guid`),
  KEY `IXGUID` (`guid`),
  KEY `IXADDR` (`addressid`),
  KEY `fulldate` (`fulldate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO ixreport VALUES (1,'guid-test-1',1,'201411010001');
INSERT INTO ixreport VALUES (2,'guid-test-2',2,'201411010002');
INSERT INTO ixreport VALUES (3,'guid-test-3',3,'201411010003');
INSERT INTO ixreport VALUES (4,'guid-test-4',4,'201411010004');


DROP TABLE IF EXISTS `ixtester`;
CREATE TABLE `ixtester` (
  `userid` int(10) unsigned NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `confirm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `confirmed` int(2) DEFAULT '0',
  PRIMARY KEY (`userid`,`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


INSERT INTO ixtester VALUES (2,'barbie@cpan.org','',1);
INSERT INTO ixtester VALUES (2,'barbie@cpantesters.org','716b9e260702a9000b9d7dca40855e9485d8cb4e',0);
INSERT INTO ixtester VALUES (2,'barbie@missbarbell.co.uk','',1);


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

DROP TABLE IF EXISTS osname;
CREATE TABLE osname (
     id         int(10) unsigned NOT NULL auto_increment,
     osname     varchar(255),
     ostitle    varchar(255),
     PRIMARY KEY (id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `osname` VALUES (1,'aix','AIX');
INSERT INTO `osname` VALUES (2,'bsdos','BSD/OS');
INSERT INTO `osname` VALUES (3,'cygwin','Windows (Cygwin)');
INSERT INTO `osname` VALUES (4,'darwin','Mac OS X');
INSERT INTO `osname` VALUES (5,'dec_osf','Tru64');
INSERT INTO `osname` VALUES (6,'dragonfly','Dragonfly BSD');
INSERT INTO `osname` VALUES (7,'freebsd','FreeBSD');
INSERT INTO `osname` VALUES (8,'gnu','GNU Hurd');
INSERT INTO `osname` VALUES (9,'haiku','Haiku');
INSERT INTO `osname` VALUES (10,'hpux','HP-UX');
INSERT INTO `osname` VALUES (11,'irix','IRIX');
INSERT INTO `osname` VALUES (12,'linux','GNU/Linux');
INSERT INTO `osname` VALUES (13,'macos','Mac OS classic');
INSERT INTO `osname` VALUES (14,'midnightbsd','MidnightBSD');
INSERT INTO `osname` VALUES (15,'mirbsd','MirOS BSD');
INSERT INTO `osname` VALUES (16,'mswin32','Windows (Win32)');
INSERT INTO `osname` VALUES (17,'netbsd','NetBSD');
INSERT INTO `osname` VALUES (18,'openbsd','OpenBSD');
INSERT INTO `osname` VALUES (19,'os2','OS/2');
INSERT INTO `osname` VALUES (20,'os390','OS390/zOS');
INSERT INTO `osname` VALUES (22,'sco','SCO');
INSERT INTO `osname` VALUES (24,'vms','VMS');
INSERT INTO `osname` VALUES (23,'solaris','SunOS/Solaris');
INSERT INTO `osname` VALUES (25,'beos','BeOS');
INSERT INTO `osname` VALUES (26,'interix','Interix');
INSERT INTO `osname` VALUES (21,'gnukfreebsd','Debian GNU/kFreeBSD');
INSERT INTO `osname` VALUES (52698,'bitrig','BITRIG');
INSERT INTO `osname` VALUES (52697,'minix','MINIX');
INSERT INTO `osname` VALUES (27,'nto','QNX Neutrino');

DROP TABLE IF EXISTS `perl_version`;
CREATE TABLE `perl_version` (
  `version` varchar(255) NOT NULL DEFAULT '',
  `perl` varchar(32) DEFAULT NULL,
  `patch` tinyint(1) DEFAULT '0',
  `devel` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `perl_version` VALUES ('5.5.3','5.5.3',0,0);
INSERT INTO `perl_version` VALUES ('5.4.4','5.4.4',0,0);
INSERT INTO `perl_version` VALUES ('5.4.0','5.4.0',0,0);
INSERT INTO `perl_version` VALUES ('5.5.2','5.5.2',0,0);
INSERT INTO `perl_version` VALUES ('5.3.97','5.3.97',0,0);
INSERT INTO `perl_version` VALUES ('5.4.3','5.4.3',0,0);
INSERT INTO `perl_version` VALUES ('5.5.640','5.5.640',0,0);
INSERT INTO `perl_version` VALUES ('5.5.650','5.5.650',0,0);
INSERT INTO `perl_version` VALUES ('5.5.660','5.5.660',0,0);
INSERT INTO `perl_version` VALUES ('5.5.670','5.5.670',0,0);
INSERT INTO `perl_version` VALUES ('5.6.0','5.6.0',0,0);
INSERT INTO `perl_version` VALUES ('5.3.0','5.3.0',0,0);
INSERT INTO `perl_version` VALUES ('5.5.1','5.5.1',0,0);
INSERT INTO `perl_version` VALUES ('5.6.1','5.6.1',0,0);
INSERT INTO `perl_version` VALUES ('5.7.1','5.7.1',0,1);
INSERT INTO `perl_version` VALUES ('5.7.2','5.7.2',0,1);
INSERT INTO `perl_version` VALUES ('5.7.2 patch 13832','5.7.2',1,1);
INSERT INTO `perl_version` VALUES ('5.7.2 patch 14856','5.7.2',1,1);
INSERT INTO `perl_version` VALUES ('5.7.3 patch 15101','5.7.3',1,1);
INSERT INTO `perl_version` VALUES ('5.7.3 patch 15246','5.7.3',1,1);
INSERT INTO `perl_version` VALUES ('5.7.3','5.7.3',0,1);
