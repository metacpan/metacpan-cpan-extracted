--
-- Table structure for table `ixmp3s`
--

DROP TABLE IF EXISTS `ixmp3s`;
CREATE TABLE `ixmp3s` (
  `mp3id` int(10) unsigned NOT NULL,
  `lyricsid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`mp3id`,`lyricid`),
  KEY `IXMP3`   (`mp3id`),
  KEY `IXLYRIC` (`lyricid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ixreleases`
--

DROP TABLE IF EXISTS `ixreleases`;
CREATE TABLE `ixreleases` (
  `type` int(4) unsigned NOT NULL DEFAULT '1',
  `releaseid` int(10) unsigned NOT NULL,
  `linkid` int(10) unsigned NOT NULL,
  `orderno` int(4) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`type`,`releaseid`,`linkid`),
  KEY `IXTYPE`      (`type`),
  KEY `IXRELEASE`   (`releaesid`),
  KEY `IXLINK`      (`linkid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `release_forms`
--

DROP TABLE IF EXISTS `release_forms`;
CREATE TABLE `release_forms` (
  `relformid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `format` varchar(255) NOT NULL,
  PRIMARY KEY (`relformid`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `release_forms`
--

INSERT INTO `release_forms` VALUES (1,'Cassette');
INSERT INTO `release_forms` VALUES (2,'Vinyl');
INSERT INTO `release_forms` VALUES (3,'CD');
INSERT INTO `release_forms` VALUES (4,'VHS');
INSERT INTO `release_forms` VALUES (5,'DVD');
INSERT INTO `release_forms` VALUES (6,'Blu-Ray');
INSERT INTO `release_forms` VALUES (7,'USB');
INSERT INTO `release_forms` VALUES (8,'MP3');
INSERT INTO `release_forms` VALUES (9,'Unreleased');
INSERT INTO `release_forms` VALUES (10,'White-Label');

--
-- Table structure for table `release_ixformats`
--

DROP TABLE IF EXISTS `release_ixformats`;
CREATE TABLE `release_ixformats` (
  `ixformatid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `releaseid` int(10) unsigned NOT NULL,
  `relformid` int(10) unsigned NOT NULL,
  `catalogue` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ixformatid`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

--
-- Table structure for table `release_types`
--

DROP TABLE IF EXISTS `release_types`;
CREATE TABLE `release_types` (
  `reltypeid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  PRIMARY KEY (`reltypeid`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `release_types`
--

INSERT INTO `release_types` VALUES (2,'Single/EP');
INSERT INTO `release_types` VALUES (1,'Album');
INSERT INTO `release_types` VALUES (3,'Video/DVD');
INSERT INTO `release_types` VALUES (4,'Unreleased');
INSERT INTO `release_types` VALUES (5,'Demo');

--
-- Table structure for table `releases`
--

DROP TABLE IF EXISTS `releases`;
CREATE TABLE `releases` (
  `releaseid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reltypeid` int(10) unsigned NOT NULL,
  `title` varchar(255) DEFAULT 'NOTITLE',
  `releasedate` int(10) DEFAULT '0',
  `quickname` varchar(32) DEFAULT NULL,
  `publish` int(4) DEFAULT NULL,
  PRIMARY KEY (`releaseid`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
