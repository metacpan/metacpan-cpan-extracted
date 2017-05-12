DROP TABLE IF EXISTS `subscriptions`;
CREATE TABLE `subscriptions` (
  `subscriptionid`  int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name`            varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email`           varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `code`            varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`subscriptionid`),
  KEY `IXEMAIL` (`email`),
  KEY `IXCODE` (`code`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

DROP TABLE IF EXISTS `ixsubscriptions`;
CREATE TABLE `ixsubscriptions` (
  `articleid`       int(10) unsigned NOT NULL,
  `subscriptionid`  int(10) unsigned NOT NULL,
  `datesent`        int(10) unsigned NOT NULL,
  KEY (`articleid`),
  KEY (`subscriptionid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


