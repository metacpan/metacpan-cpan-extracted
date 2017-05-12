--
-- Table structure for table `imetadata`
--

DROP TABLE IF EXISTS `imetadata`;
CREATE TABLE `imetadata` (
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `tag` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY  (`imageid`,`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `ixpages`
--

DROP TABLE IF EXISTS `ixpages`;
CREATE TABLE `ixpages` (
  `eventid` int(10) unsigned NOT NULL DEFAULT '0',
  `pageid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY  (`eventid`,`pageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `mxpages`
--

DROP TABLE IF EXISTS `mxpages`;
CREATE TABLE `mxpages` (
  `pageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `metadata` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY  (`pageid`,`metadata`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `mxphotos`
--

DROP TABLE IF EXISTS `mxphotos`;
CREATE TABLE `mxphotos` (
  `photoid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `metadata` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY  (`photoid`,`metadata`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
CREATE TABLE `pages` (
  `pageid` int(11) NOT NULL AUTO_INCREMENT,
  `parent` int(11) DEFAULT '0',
  `area` int(11) NOT NULL DEFAULT '0',
  `title` varchar(64) DEFAULT NULL,
  `year` int(4) NOT NULL DEFAULT '0',
  `month` int(4) NOT NULL DEFAULT '0',
  `orderno` int(4) DEFAULT '0',
  `hide` int(1) DEFAULT '0',
  `path` varchar(64) NOT NULL DEFAULT '',
  `summary` blob,
  PRIMARY KEY  (`pageid`),
  KEY `YRIX` (`year`),
  KEY `MNIX` (`month`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO pages (pageid,title) VALUES (1,'Archive');


--
-- Table structure for table `photos`
--

DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos` (
  `photoid` int(11) NOT NULL AUTO_INCREMENT,
  `pageid` int(11) NOT NULL DEFAULT '0',
  `orderno` int(11) NOT NULL DEFAULT '0',
  `thumb` varchar(255) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `tagline` varchar(255) DEFAULT NULL,
  `hide` tinyint(4) NOT NULL DEFAULT '0',
  `cover` tinyint(4) NOT NULL DEFAULT '0',
  `dimensions` varchar(32) DEFAULT NULL,
  PRIMARY KEY  (`photoid`),
  KEY `PAGIX` (`pageid`),
  KEY `COVER` (`cover`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Table structure for table `updates`
--

DROP TABLE IF EXISTS `updates`;
CREATE TABLE `updates` (
  `upid` int(11) NOT NULL AUTO_INCREMENT,
  `area` varchar(8) DEFAULT '',
  `pageid` int(11) DEFAULT NULL,
  `now` int(11) DEFAULT NULL,
  `pagets` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`upid`),
  KEY `AREIX` (`area`),
  KEY `PAGIX` (`pageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

