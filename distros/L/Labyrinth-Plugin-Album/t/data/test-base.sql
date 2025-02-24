DROP TABLE IF EXISTS `access`;
CREATE TABLE `access` (
  `accessid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessname` varchar(255) DEFAULT NULL,
  `accesslevel` int(4) DEFAULT NULL,
  PRIMARY KEY (`accessid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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


INSERT INTO `pages` VALUES (2,0,1,'Home Page',2005,8,0,0,'photos/20050830','');
INSERT INTO `pages` VALUES (3,0,1,'Test Page',2005,8,0,0,'photos/20050830','');
INSERT INTO `pages` VALUES (4,3,1,'Test Sub Page 1',2005,8,0,0,'photos/20050830','');
INSERT INTO `pages` VALUES (5,3,1,'Test Sub Page 2',2005,8,0,0,'photos/20050830','');

INSERT INTO `photos` VALUES (1,3,1,'20050830/dscf5903-thumb.jpg','20050830/dscf5903.jpg',NULL,0,1,'800x600');
INSERT INTO `photos` VALUES (2,3,2,'20050830/dscf5904-thumb.jpg','20050830/dscf5904.jpg',NULL,0,0,'800x600');
INSERT INTO `photos` VALUES (3,4,1,'20050830/dscf5905-thumb.jpg','20050830/dscf5905.jpg',NULL,0,1,'800x600');
INSERT INTO `photos` VALUES (4,5,1,'20050830/dscf5906-thumb.jpg','20050830/dscf5906.jpg',NULL,0,0,'800x600');

INSERT INTO `mxphotos` VALUES (1,'Test');
INSERT INTO `mxphotos` VALUES (2,'Labyrinth');
INSERT INTO `mxphotos` VALUES (3,'Barbie');
INSERT INTO `mxphotos` VALUES (4,'Perl');
INSERT INTO `mxphotos` VALUES (3,'Perl');
INSERT INTO `mxphotos` VALUES (1,'Labyrinth');

INSERT INTO `updates` VALUES (1,'site',0,1368390442,'2013-05-12 20:27:22');
INSERT INTO `updates` VALUES (2,'album',1,1174906863,'2007-03-26 12:01:46');
INSERT INTO `updates` VALUES (3,'album',2,1175169089,'2007-03-29 12:52:10');
INSERT INTO `updates` VALUES (4,'album',3,1175169089,'2007-03-29 12:52:10');
