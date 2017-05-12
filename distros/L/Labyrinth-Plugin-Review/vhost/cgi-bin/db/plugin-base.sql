DROP TABLE IF EXISTS `retailers`;
CREATE TABLE `retailers` (
  `retailerid`      int(10) unsigned NOT NULL AUTO_INCREMENT,
  `retailer`        varchar(255) DEFAULT NULL,
  `retailerlink`    varchar(255) DEFAULT NULL,
  PRIMARY KEY (`retailerid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `reviews`;
CREATE TABLE `reviews` (
  `reviewid`        int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reviewtypeid`    int(10) unsigned NOT NULL DEFAULT '0',
  `folderid`        int(10) unsigned NOT NULL DEFAULT '0',
  `title`           varchar(255) DEFAULT NULL,
  `userid`          int(10) unsigned NOT NULL DEFAULT '0',
  `createdate`      varchar(255) DEFAULT NULL,

  `brand`           varchar(255) DEFAULT NULL,
  `itemcode`        varchar(255) DEFAULT NULL,
  `itemlink`        varchar(255) DEFAULT NULL,
  `retailerid`      int(10) unsigned NOT NULL DEFAULT '0',

  `imageid`         int(10) unsigned NOT NULL DEFAULT '0',
  `publish`         int(4) DEFAULT NULL,
  `snippet`         varchar(255) DEFAULT NULL,
  `additional`      varchar(255) DEFAULT NULL,
  `body`            blob,
  PRIMARY KEY (`reviewid`),
  KEY `IXFOLDER` (`folderid`),
  KEY `IXTYPE` (`reviewtypeid`),
  KEY `IXIMAGE` (`imageid`),
  KEY `IXPUBR` (`retailerid`),
  KEY `IXPUB` (`brand`)
  KEY `IXPUB` (`publish`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `reviewtypes`;
CREATE TABLE `reviewtypes` (
  `reviewtypeid`    int(10) unsigned NOT NULL AUTO_INCREMENT,
  `typename`        varchar(255) DEFAULT NULL,
  `typeabbr`        varchar(255) DEFAULT NULL,
  PRIMARY KEY (`reviewtypeid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

