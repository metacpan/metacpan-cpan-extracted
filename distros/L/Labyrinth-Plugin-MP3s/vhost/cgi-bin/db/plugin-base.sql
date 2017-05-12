DROP TABLE IF EXISTS `mp3cat`;
CREATE TABLE `mp3cat` (
  `mp3catid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`mp3catid`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

INSERT INTO `mp3cat` VALUES (1,'Recorded');
INSERT INTO `mp3cat` VALUES (2,'Live');
INSERT INTO `mp3cat` VALUES (3,'Unreleased');

DROP TABLE IF EXISTS `mp3s`;
CREATE TABLE `mp3s` (
  `mp3id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `mp3catid` int(10) unsigned NOT NULL,
  `orderno` int(3) DEFAULT '999',
  `source` varchar(255) DEFAULT NULL,
  `tracks` text,
  `notes` text,
  `publish` int(4) DEFAULT NULL,
  PRIMARY KEY (`mp3id`),
  KEY `IXMP3CAT` (`mp3catid`),
  KEY `IXPUB` (`publish`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

INSERT INTO `imagestock` set title='mp3s', path='mp3s';

