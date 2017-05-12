-- MySQL dump 10.13  Distrib 5.5.37, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: yn2014
-- ------------------------------------------------------
-- Server version	5.5.37-0+wheezy1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `access`
--

DROP TABLE IF EXISTS `access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access` (
  `accessid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessname` varchar(255) DEFAULT NULL,
  `accesslevel` int(4) DEFAULT NULL,
  PRIMARY KEY (`accessid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `access`
--

INSERT INTO `access` VALUES (1,'reader',1);
INSERT INTO `access` VALUES (2,'editor',2);
INSERT INTO `access` VALUES (3,'publisher',3);
INSERT INTO `access` VALUES (4,'admin',4);
INSERT INTO `access` VALUES (5,'master',5);

--
-- Table structure for table `acls`
--

DROP TABLE IF EXISTS `acls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acls` (
  `aclid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned DEFAULT '0',
  `userid` int(10) unsigned DEFAULT '0',
  `accessid` int(4) DEFAULT NULL,
  PRIMARY KEY (`aclid`),
  KEY `IXFOLDER` (`folderid`),
  KEY `IXGROUP` (`groupid`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acls`
--

INSERT INTO `acls` VALUES (1,1,9,0,5);
INSERT INTO `acls` VALUES (2,1,1,0,1);
INSERT INTO `acls` VALUES (4,1,0,2,5);

--
-- Table structure for table `announce`
--

DROP TABLE IF EXISTS `announce`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `announce` (
  `announceid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hFrom` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `hSubject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `body` blob,
  `publish` int(4) DEFAULT NULL,
  PRIMARY KEY (`announceid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `announce`
--

INSERT INTO `announce` VALUES (1,'Barbie','The YAPC_CONF Survey - Your Keycode','Dear ENAME,\r\n\r\nPlease keep this email safe, as it contains your personal link to the YAPC_CONF Survey site.\r\n\r\nAs an attendee of YAPC_CONF, we would like to invite you to participate in the online conference surveys. Whether you are an attendee, speaker or sponsor, we would like to get your feedback regarding any talks and tutorials you attend, as well as the conference itself, with the aim of helping to improve the conference experience for future attendees.\r\n\r\nIn order to access the surveys, please bookmark the following link, and use it within your web browser of choice. \r\n\r\nhttp://YAPC_SURV/key/ECODE\r\n\r\nPlease note that although your answers will be stored anonymously, this link is specific to you, to prevent multiple submissions. \r\n\r\nThere are 2 types of survey available. The first is the main survey, which we would like everyone to complete once the conference is over, and will be made active at the end of the conference (usually during the closing speeches). Results from this survey will be published on the YAPC Conference Surveys website - http://yapc-surveys.org.\r\n\r\nThe second set of surveys are for talks or courses you attend, the results of which will be sent to speakers only. The talk evaluation surveys will be available during the conference, and will be made active from the start of the talk. Please only complete talk surveys for which you attended.\r\n\r\nIf you have any problems, please email Barbie at barbie@missbarbell.co.uk during or after the event.\r\n\r\nThe surveys will officially open on the YAPC_OPEN. If you could complete the surveys by YAPC_CLOSE, we will then aim to have the results of the survey published a week or two later.\r\n\r\nRegards,\r\nYAPC_HOST.\r\nYAPC_MAIL',3);
INSERT INTO `announce` VALUES (2,'Barbie','The YAPC_CONF Survey - Conference Survey Open','Dear ENAME,\r\n\r\nhttp://YAPC_SURV/key/ECODE\r\n\r\nThank you for attending YAPC_CONF. As an attendee, speaker or sponsor we would like to get some feedback about many aspects of your experience of the conference and the community.\r\n\r\nThe link above is your keycode into the survey website and is unique to you. On clicking the link, the page presented to you will contain The Conference Survey and all the Talk Evaluation forms.\r\n\r\nPlease take the time to at least take The Conference Survey, as it provides valuable information for the current workshop organisers, the future workshop organisers, as well as other conference or workshop organisers around the world.\r\n\r\nPlease note that all your responses are stored anonymously. Although the keycode identifies you specifically, it bears no relation to your actual response. Results will be collated at the close of the surveys, and will be made available on the YAPC Conference Surveys website - http://yapc-surveys.org. Please take a look at the\r\nwebsite to see the results of previous surveys.\r\n\r\nResults of the Talk Evaluation forms will NOT be made public, but will be sent to the respective speakers only. Note that all results sent to speakers will be anonymous, unless you explicitly identify yourself in the feedback.\r\n\r\nPlease complete the surveys by YAPC_CLOSE, after which we will then aim to have the results of the Conference Survey published and the Evaluation Surveys sent out to speakers within the following week. Announcements will be made on twitter (@missbarbell), so please keep an eye out for those if you\'re interested in seeing the results.\r\n\r\nIf you have any problems or issues with the surveys, please contact Barbie (barbie@missbarbell.co.uk). Also please use this email address for suggestions and feedback regarding the surveys or questions themselves.\r\n\r\nRegards,\r\nYAPC_HOST.\r\nYAPC_MAIL',3);
INSERT INTO `announce` VALUES (4,'Barbie','The YAPC_CONF Survey - Course Surveys Open','Dear ENAME,\r\n\r\nApologies for the delay in setting up the course evaluations, but you can now enter feedback for those courses you took after the YAPC::NA conference. As per the regular conference survey, and talk evaluations, please click the link below to access the site.\r\n\r\nhttp://YAPC_SURV/key/ECODE\r\n\r\nThe link above is your keycode into the survey website and is unique to you. On clicking the link, the page presented to you will contain The Conference Survey, all the Talk Evaluation forms and any Course Evaluation form for courses you took.\r\n\r\nPlease note that all your responses are stored anonymously. Although the keycode identifies you specifically, it bears no relation to your actual response. Results will be collated at the close of the surveys, and will be made available on the YAPC Conference Surveys website - http://yapc-surveys.org. Please take a look at the\r\nwebsite to see the results of previous surveys.\r\n\r\nResults of the Course and Talk Evaluation forms will NOT be made public, but will be sent to the respective speakers only. Note that all results sent to speakers will be anonymous, unless you explicitly identify yourself in the feedback.\r\n\r\nPlease complete the surveys by YAPC_CLOSE, after which we will then aim to have the results of the Evaluation Surveys sent out to speakers within the following week.\r\n\r\nIf you have any problems or issues with the surveys, please contact Barbie (barbie@missbarbell.co.uk). Also please use this email address for suggestions and feedback regarding the surveys or questions themselves.\r\n\r\nRegards,\r\nYAPC_HOST.\r\nYAPC_MAIL',3);
INSERT INTO `announce` VALUES (3,'Barbie','The YAPC_CONF Survey - Deadline Friday','Dear ENAME,\r\n\r\nThe YAPC_CONF surveys will close at midnight on YAPC_CLOSE. You still have time to complete the main Conference Survey, as well as any Talk Evaluations, for which you attended.\r\n\r\nAs a reminder your keycode login is given below.\r\n\r\nhttp://YAPC_SURV/key/ECODE\r\n\r\nWhile we appreciate not everyone is comfortable taking the time to respond to the surveys, we hope that you can find some time to provide us with your thoughts both about this year\'s YAPC_CONF, and for future events. Your feedback provides valuable information for the current organisers, as well as to the future organisers to help make these events better every year.\r\n\r\nResults will be collated at the close of the surveys, and will be made available on the YAPC Conference Surveys website [1], soon after the closing date.\r\n\r\nResults of the Talk Evaluation forms will NOT be made public, but will be sent to the respective speakers only. Note that all results sent to speakers will be anonymous, unless you explicitly identify yourself in the feedback.\r\n\r\nIf you have any problems or issues with the surveys, please contact Barbie by replying to this email.\r\n\r\n[1] http://yapc-surveys.org\r\n\r\nRegards,\r\nYAPC_HOST.\r\nYAPC_MAIL',3);

--
-- Table structure for table `course`
--

DROP TABLE IF EXISTS `course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `course` (
  `courseid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tutor` varchar(255) DEFAULT NULL,
  `course` varchar(255) DEFAULT NULL,
  `room` varchar(255) DEFAULT NULL,
  `datetime` int(10) DEFAULT '0',
  `talk` int(2) DEFAULT '0',
  `actuserid` int(10) unsigned NOT NULL DEFAULT '0',
  `acttalkid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`courseid`),
  KEY `IXTALK` (`acttalkid`),
  KEY `IXTUTOR` (`actuserid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course`
--


--
-- Table structure for table `evaluation`
--

DROP TABLE IF EXISTS `evaluation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluation` (
  `evalid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `courseid` int(10) unsigned NOT NULL,
  `name` varchar(32) DEFAULT NULL,
  `code` int(10) unsigned DEFAULT NULL,
  `value` text,
  PRIMARY KEY (`evalid`),
  KEY `IXCOURSE` (`courseid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evaluation`
--


--
-- Table structure for table `folders`
--

DROP TABLE IF EXISTS `folders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `folders` (
  `folderid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent` int(10) DEFAULT NULL,
  `accessid` int(10) NOT NULL DEFAULT '5',
  PRIMARY KEY (`folderid`),
  KEY `IXPATH` (`path`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `folders`
--

INSERT INTO `folders` VALUES (1,'public',0,1);

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `groupid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(255) DEFAULT NULL,
  `master` int(2) DEFAULT '0',
  `member` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `groups`
--

INSERT INTO `groups` VALUES (1,'public',1,'Guest');
INSERT INTO `groups` VALUES (2,'users',1,'User');
INSERT INTO `groups` VALUES (3,'editors',1,'Author');
INSERT INTO `groups` VALUES (4,'sponsors',1,'Sponsor');
INSERT INTO `groups` VALUES (5,'admins',1,'Admin');
INSERT INTO `groups` VALUES (6,'advertisers',1,'Advertiser');
INSERT INTO `groups` VALUES (9,'masters',1,'Master');
INSERT INTO `groups` VALUES (11,'speaker',0,'Speaker');
INSERT INTO `groups` VALUES (12,'organiser',0,'Organiser');
INSERT INTO `groups` VALUES (13,'attendee',0,'Attendee');
INSERT INTO `groups` VALUES (14,'sponsor',0,'Sponsor');
INSERT INTO `groups` VALUES (15,'guest',0,'Guest');
INSERT INTO `groups` VALUES (16,'staff',0,'Staff');

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `images` (
  `imageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tag` varchar(255) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  `type` int(4) DEFAULT NULL,
  `dimensions` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`imageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `images`
--

INSERT INTO `images` VALUES (1,'blank','images/blank.png',NULL,5,'1x1');

--
-- Table structure for table `imagestock`
--

DROP TABLE IF EXISTS `imagestock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `imagestock` (
  `stockid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`stockid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imagestock`
--

INSERT INTO `imagestock` VALUES (1,'Public','images/public');
INSERT INTO `imagestock` VALUES (2,'Random','images/public');
INSERT INTO `imagestock` VALUES (3,'Advert','images/adverts');
INSERT INTO `imagestock` VALUES (4,'User','images/users');
INSERT INTO `imagestock` VALUES (5,'Special','images/special');
INSERT INTO `imagestock` VALUES (6,'Covers','images/covers');
INSERT INTO `imagestock` VALUES (9,'DRAFT','images/upload');

--
-- Table structure for table `imetadata`
--

DROP TABLE IF EXISTS `imetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `imetadata` (
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `tag` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`imageid`,`tag`),
  KEY `IXTAG` (`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imetadata`
--


--
-- Table structure for table `inbox`
--

DROP TABLE IF EXISTS `inbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inbox` (
  `inboxid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `message` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`inboxid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inbox`
--


--
-- Table structure for table `ixannounce`
--

DROP TABLE IF EXISTS `ixannounce`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixannounce` (
  `announceid` int(10) unsigned NOT NULL,
  `userid` int(10) unsigned NOT NULL,
  `sentdate` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`announceid`,`userid`,`sentdate`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixannounce`
--


--
-- Table structure for table `ixcourse`
--

DROP TABLE IF EXISTS `ixcourse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixcourse` (
  `courseid` int(10) unsigned NOT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `completed` int(10) DEFAULT '0',
  PRIMARY KEY (`courseid`,`userid`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixcourse`
--


--
-- Table structure for table `ixfolderrealm`
--

DROP TABLE IF EXISTS `ixfolderrealm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixfolderrealm` (
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `realmid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`folderid`,`realmid`),
  KEY `IXREALM` (`realmid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixfolderrealm`
--

INSERT INTO `ixfolderrealm` VALUES (1,1);
INSERT INTO `ixfolderrealm` VALUES (1,2);

--
-- Table structure for table `ixsurvey`
--

DROP TABLE IF EXISTS `ixsurvey`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixsurvey` (
  `code` varchar(255) NOT NULL DEFAULT '',
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `completed` int(10) DEFAULT '0',
  `sentdate` int(10) DEFAULT '0',
  PRIMARY KEY (`code`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixsurvey`
--


--
-- Table structure for table `ixusergroup`
--

DROP TABLE IF EXISTS `ixusergroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ixusergroup` (
  `indexid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` int(1) unsigned NOT NULL DEFAULT '0',
  `linkid` int(10) unsigned NOT NULL DEFAULT '0',
  `groupid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`indexid`),
  KEY `IXTYPE` (`type`),
  KEY `IXLINK` (`linkid`),
  KEY `IXGROUP` (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixusergroup`
--

INSERT INTO `ixusergroup` VALUES (1,1,1,1);
INSERT INTO `ixusergroup` VALUES (2,1,2,9);

--
-- Table structure for table `realms`
--

DROP TABLE IF EXISTS `realms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `realms` (
  `realmid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `realm` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`realmid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `realms`
--

INSERT INTO `realms` VALUES (1,'public','Public Interface');
INSERT INTO `realms` VALUES (2,'admin','Admin Interface');

--
-- Table structure for table `sections`
--

DROP TABLE IF EXISTS `sections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sections` (
  `sectionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sectionkey` varchar(8) DEFAULT NULL,
  `sectionname` varchar(255) DEFAULT NULL,
  `orderno` int(4) DEFAULT '0',
  PRIMARY KEY (`sectionid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sections`
--

INSERT INTO `sections` VALUES (1,'fina','Receipts',1);
INSERT INTO `sections` VALUES (2,'arts','Articles',2);
INSERT INTO `sections` VALUES (3,'imgs','Images',12);
INSERT INTO `sections` VALUES (4,'news','News',4);
INSERT INTO `sections` VALUES (5,'nlet','Newsletter',3);
INSERT INTO `sections` VALUES (6,'talk','Talks',5);
INSERT INTO `sections` VALUES (7,'user','Users',7);
INSERT INTO `sections` VALUES (8,'grps','Groups',8);
INSERT INTO `sections` VALUES (9,'flds','Folders',9);
INSERT INTO `sections` VALUES (10,'bugs','Bugs',10);
INSERT INTO `sections` VALUES (11,'fact','Facts',11);
INSERT INTO `sections` VALUES (12,'sched','Schedule',6);
INSERT INTO `sections` VALUES (13,'map','Map',13);

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `sessionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `labyrinth` varchar(255) DEFAULT NULL,
  `userid` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `realm` varchar(255) DEFAULT NULL,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `timeout` int(10) unsigned NOT NULL DEFAULT '0',
  `langcode` char(2) NOT NULL DEFAULT 'en',
  `query` blob,
  PRIMARY KEY (`sessionid`),
  KEY `IXLAB` (`labyrinth`),
  KEY `IXTIMEOUT` (`timeout`),
  KEY `IXUSER` (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--


--
-- Table structure for table `survey`
--

DROP TABLE IF EXISTS `survey`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `survey` (
  `surveyid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT NULL,
  `code` int(10) unsigned DEFAULT NULL,
  `value` text,
  PRIMARY KEY (`surveyid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `survey`
--


--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `userid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessid` int(10) unsigned NOT NULL DEFAULT '1',
  `nickname` varchar(255) DEFAULT NULL,
  `realname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `realm` varchar(20) DEFAULT NULL,
  `search` int(1) DEFAULT NULL,
  `confirmed` int(1) DEFAULT '0',
  `mailed` int(1) DEFAULT '0',
  `password` varchar(255) DEFAULT NULL,
  `imageid` int(10) unsigned DEFAULT '0',
  `aboutme` blob,
  `actuserid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`userid`),
  KEY `IXACCESS` (`accessid`),
  KEY `IXIMAGE` (`imageid`),
  KEY `IXUSER` (`actuserid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES (1,1,'','Guest','GUEST','public',0,0,0,'c8d6ea7f8e6850e9ed3b642900ca27683a257201',0,NULL,0);
INSERT INTO `users` VALUES (2,1,'','Master','master@example.com','admin',0,1,0,SHA1('master'),1,NULL,0);
INSERT INTO `users` VALUES (3,1,'','Test User','test@example.com','public',0,1,0,SHA1('test'),0,NULL,0);
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-07-15 21:52:27
