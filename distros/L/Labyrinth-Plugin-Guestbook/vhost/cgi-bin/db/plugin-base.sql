DROP TABLE IF EXISTS `guestbook`;
CREATE TABLE `guestbook` (
  `entryid` int(11) NOT NULL auto_increment,
  `realname` varchar(64) default NULL,
  `email` varchar(64) default NULL,
  `url` varchar(64) default NULL,
  `city` varchar(64) default NULL,
  `country` varchar(64) default NULL,
  `createdate` int(16) default '0',
  `publish` int(4) default '1',
  `ipaddr` varchar(255) NOT NULL default '',
  `comments` blob,
  PRIMARY KEY  (`entryid`),
  KEY `IXPUB` (`publish`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
