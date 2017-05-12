--
-- Table structure for table `linkcat`
--

DROP TABLE IF EXISTS `linkcat`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `linkcat` (
  `catid`       int(10) unsigned NOT NULL auto_increment,
  `orderno`     int(2) default '99',
  `category`    varchar(255) default NULL,
  PRIMARY KEY  (`catid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `linkcat`
--

INSERT INTO `linkcat` VALUES (1,1,'Category 1');
INSERT INTO `linkcat` VALUES (2,2,'Category 2');
INSERT INTO `linkcat` VALUES (3,3,'Category 3');

--
-- Table structure for table `links`
--

DROP TABLE IF EXISTS `links`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `links` (
  `linkid`      int(10) unsigned NOT NULL auto_increment,
  `catid`       int(10) unsigned NOT NULL default '1',
  `href`        varchar(255) NOT NULL default '',
  `title`       varchar(255) NOT NULL default '',
  `body`        blob,
  PRIMARY KEY  (`linkid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `links`
--

INSERT INTO `links` VALUES (1,1,'http://www.example.com','Example Link 1',NULL);
INSERT INTO `links` VALUES (2,2,'http://www.example.com','Example Link 2',NULL);
INSERT INTO `links` VALUES (3,3,'http://www.example.com','Example Link 3',NULL);
