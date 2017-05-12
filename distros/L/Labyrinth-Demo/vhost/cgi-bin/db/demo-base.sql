-- MySQL dump 10.13  Distrib 5.5.34, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: demo
-- ------------------------------------------------------
-- Server version	5.5.34-0ubuntu0.12.04.1

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
  INDEX FLDIX (`folderid`),
  INDEX GRPIX (`groupid`),
  INDEX USRIX (`userid`),
  INDEX ACSIX (`accessid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acls`
--

INSERT INTO `acls` VALUES (1,1,9,0,5);
INSERT INTO `acls` VALUES (2,1,1,0,1);
INSERT INTO `acls` VALUES (3,1,0,5,4);

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `articles`
--

INSERT INTO `articles` VALUES (1,1,'About Labyrinth',1,'1174863600',3,'about','',0,0,0,3);
INSERT INTO `articles` VALUES (2,1,'Terms &amp; Conditions',2,'1294012800',3,'terms',NULL,0,0,0,3);

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
INSERT INTO `groups` VALUES (3,'editors',1,'Editor');
INSERT INTO `groups` VALUES (4,'sponsors',1,'Sponsor');
INSERT INTO `groups` VALUES (5,'admins',1,'Admin');
INSERT INTO `groups` VALUES (9,'masters',1,'Master');

--
-- Table structure for table `hits`
--

DROP TABLE IF EXISTS `hits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hits` (
  `pageid` int(11) NOT NULL DEFAULT '0',
  `area` varchar(32) DEFAULT '',
  `photoid` int(11) NOT NULL DEFAULT '0',
  `counter` int(11) DEFAULT NULL,
  `query` varchar(255) DEFAULT '',
  `createdate` int(11) DEFAULT '0',
  INDEX PAGIX (`pageid`),
  INDEX PHTIX (`photoid`),
  INDEX AREIX (`area`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hits`
--


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
  `type` int(4) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  `dimensions` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`imageid`),
  INDEX TYPIX (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `images`
--

INSERT INTO `images` VALUES (1,NULL,'images/blank.png',1,NULL,NULL);

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
INSERT INTO `imagestock` VALUES (5,'Layout','images/layout');
INSERT INTO `imagestock` VALUES (9,'DRAFT','images/draft');

--
-- Table structure for table `imetadata`
--

DROP TABLE IF EXISTS `imetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `imetadata` (
  `imageid` int(10) unsigned NOT NULL DEFAULT '0',
  `tag` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`imageid`,`tag`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `imetadata`
--


--
-- Table structure for table `ipindex`
--

DROP TABLE IF EXISTS `ipindex`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipindex` (
  `ipaddr` varchar(255) NOT NULL DEFAULT '',
  `author` varchar(255) NOT NULL DEFAULT '',
  `type` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ipaddr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ipindex`
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
  PRIMARY KEY (`folderid`,`realmid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixfolderrealm`
--

INSERT INTO `ixfolderrealm` VALUES (1,1);
INSERT INTO `ixfolderrealm` VALUES (1,2);

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
  INDEX TYPIX (`type`),
  INDEX LNKIX (`linkid`),
  INDEX GRPIX (`groupid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ixusergroup`
--

INSERT INTO `ixusergroup` VALUES (1,1,1,1);
INSERT INTO `ixusergroup` VALUES (2,1,1,9);

--
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menus` (
  `menuid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `typeid` int(10) unsigned DEFAULT '1',
  `realmid` int(10) unsigned NOT NULL DEFAULT '0',
  `title` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `parentid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`menuid`),
  INDEX TYPIX (`typeid`),
  INDEX RLMIX (`realmid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

INSERT INTO `menus` VALUES (1,1,1,'','Public Menu',0);
INSERT INTO `menus` VALUES (2,1,2,'','Admin Menu',0);
INSERT INTO `menus` VALUES (3,1,1,'Links','Sidebar Menu',0);

--
-- Table structure for table `mxarticles`
--

DROP TABLE IF EXISTS `mxarticles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mxarticles` (
  `articleid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `metadata` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`articleid`,`metadata`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mxarticles`
--

INSERT INTO `mxarticles` VALUES (186,'release');

--
-- Table structure for table `optimages`
--

DROP TABLE IF EXISTS `optimages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `optimages` (
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `typeid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`optionid`,`typeid`),
  INDEX IMGIX (`imageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `optimages`
--


--
-- Table structure for table `options`
--

DROP TABLE IF EXISTS `options`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `options` (
  `optionid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `menuid` int(10) unsigned NOT NULL DEFAULT '0',
  `orderno` int(2) DEFAULT '0',
  `accessid` int(2) DEFAULT '0',
  `name` varchar(255) DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  `href` varchar(255) DEFAULT NULL,
  `section` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`optionid`),
  INDEX MENIX (`menuid`),
  INDEX ACSIX (`accessid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `options`
--

INSERT INTO `options` VALUES (1,1,1,1,NULL,'Home','/cgi-bin/pages.cgi?act=home-main',NULL);
INSERT INTO `options` VALUES (2,1,2,1,NULL,'About','/cgi-bin/pages.cgi?act=arts-item&amp;name=about',NULL);
INSERT INTO `options` VALUES (5,2,1,3,NULL,'Admin','/cgi-bin/pages.cgi?act=home-admin',NULL);
INSERT INTO `options` VALUES (7,2,2,2,NULL,'Site Pages','/cgi-bin/pages.cgi?act=arts-admin',NULL);
INSERT INTO `options` VALUES (9,2,3,4,NULL,'Menus','/cgi-bin/pages.cgi?act=menu-admin',NULL);
INSERT INTO `options` VALUES (10,2,4,2,NULL,'Hits','/cgi-bin/pages.cgi?act=hits-admin',NULL);
INSERT INTO `options` VALUES (11,2,5,4,NULL,'Users','/cgi-bin/pages.cgi?act=user-admin',NULL);
INSERT INTO `options` VALUES (12,1,3,1,NULL,'Login','/cgi-bin/pages.cgi?act=user-login',NULL);
INSERT INTO `options` VALUES (13,2,6,1,NULL,'Logout','/cgi-bin/pages.cgi?act=user-logout',NULL);
INSERT INTO `options` VALUES (14,3,1,1,NULL,'Perl','http://www.perl.org',NULL);
INSERT INTO `options` VALUES (15,3,2,1,NULL,'CPAN','http://www.cpan.org',NULL);
INSERT INTO `options` VALUES (16,3,3,1,NULL,'CPAN Testers','http://www.cpantesters.org',NULL);

--
-- Table structure for table `paragraphs`
--

DROP TABLE IF EXISTS `paragraphs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `paragraphs`
--

INSERT INTO `paragraphs` VALUES (1,1,1,2,0,NULL,'<h2>A Brief History</h2>\r\n<p>In 2000 a website management tool, Mephisto, was written, and then  implemented as intranets for a number of Local Education Authorities in  the UK. Although well designed, developed and deployed, it focused very  specifically at the Education market in the UK, and very tightly  combined its feature set to the core application. However, it did  highlight how it could be implemented for alternative markets and  clients.</p>\r\n<p>In late 2002, the design of Labyrinth began, taking many of the good  ideas of Mephisto, enhancing where possible, and restructuring the  interfaces to better implement websites for any type of use. Taking away  the focus of the Education specific features, making them more generic  and most importantly ... pluggable ... allowed the core application to  be tailored to whatever the client wanted. Adding many new features or  &quot;plugins&quot; extended Labyrinth even further.</p>\r\n<p>After 8 years of closed source development, despite being used for  many successful Open Source websites, it was time to release the code  for others to use, improve and adapt. The code base developed prior to  version 5.00 remains closed source. However, from version 5.00 the  Labyrinth code is now available within a <em>git</em> code repository.</p>',NULL);
INSERT INTO `paragraphs` VALUES (2,2,1,2,0,NULL,'<h2>Cookie Policy</h2>\r\n<h3>EU Cookie Directive</h3>\r\n<p>In order to comply with <strong><a title=\"Article 2 of Directive 2009/136/EC\" href=\"http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2009:337:0011:0036:EN:PDF\">Article 2 of Directive 2009/136/EC</a></strong>, which amends the <strong><a title=\"E-Privacy Directive 2002/58/EC\" href=\"http://eur-lex.europa.eu/LexUriServ/LexUriServ.do?uri=OJ:L:2002:108:0033:0050:EN:PDF\">E-Privacy Directive 2002/58/EC</a></strong>, within the <strong><a title=\"EU Electronic Communications Framework\" href=\"http://europa.eu/legislation_summaries/internal_market/single_market_services/l24216a_en.htm\">EU Electronic Communications Framework (ECF)</a></strong>, all businesses must now make you aware of the use of cookies on their site.</p>\r\n<h3>Our Cookie Usage</h3>\r\n<p>This website uses cookies to enable us to improve the site usage. Our  cookies fall into two categories; site usage and site analysis. Below  are a list of the specifc cookies we use and what they are used for.</p><p>No Third Party cookies are used or set by the Labyrinth Demo website.</p><p>Other useful links: <strong><a title=\"read more about cookies\" href=\"http://www.allaboutcookies.org\">http://www.allaboutcookies.org</a></strong>.</p>\r\n<table id=\"infotable\" border=\"0\" summary=\"The Cookies We Use\">\r\n\r\n<tr>\r\n<th>Cookie&nbsp;Name</th><th>Category</th><th>Purpose</th>\r\n</tr>\r\n<tr>\r\n<td valign=\"top\">sessionid</td>\r\n<td valign=\"top\">Usage</td>\r\n<td>A unique identifier given to each session.</td>\r\n</tr>\r\n<tr>\r\n<td valign=\"top\">_utma,<br />_utmc,<br />_utmz</td>\r\n<td valign=\"top\">Analysis</td>\r\n<td>Google Analytics cookies. For more detailed information about how these cookies are used, please see the <a title=\"Google Analytics Cookie Guide\" href=\"http://code.google.com/apis/analytics/docs/concepts/gaConceptsCookies.html\">Google Analytics Cookie Guide</a>. Please note all Google Analytics cookies are considered <strong>First Party Cookies</strong> and are only used to process anonymous site usage for this domain.</td>\r\n</tr>\r\n\r\n</table>\r\n<h3>Google Analytics</h3>\r\n<p>This website uses Google Analytics, a web analytics service provided  by Google, Inc. (\"Google\"). Google Analytics uses \"cookies\", which are  text files placed on your computer, to help the website analyze how  users use the site. The information generated by the cookie about your  use of the website (including your IP address) will be transmitted to  and stored by Google on servers in the United States . Google will use  this information for the purpose of evaluating your use of the website,  compiling reports on website activity for website operators and  providing other services relating to website activity and internet  usage. Google may also transfer this information to third parties where  required to do so by law, or where such third parties process the  information on Google\'s behalf. Google will not associate your IP  address with any other data held by Google. You may refuse the use of  cookies by selecting the appropriate settings on your browser, however  please note that if you do this you may not be able to use the full  functionality of this website. By using this website, you consent to the  processing of data about you by Google in the manner and for the  purposes set out above.</p>\r\n<h2>Links</h2>\r\n<p>The inclusion of a link to an organisation\'s or individual\'s website  does not constitute an endorsement or an approval by Miss Barbell Productions of any  product, service, policy or opinion of the organisation or individual. Miss Barbell Productions  is not responsible for the content of external websites.</p>',NULL);

--
-- Table structure for table `realms`
--

DROP TABLE IF EXISTS `realms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `realms` (
  `realmid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `realm` varchar(32) NOT NULL,
  `name` varchar(64) DEFAULT NULL,
  `command` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`realmid`),
  INDEX RLMIX (`realm`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `realms`
--

INSERT INTO `realms` VALUES (1,'public','Public Interface','home-main');
INSERT INTO `realms` VALUES (2,'admin','Admin Interface','home-admin');

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
  `realm` varchar(32) DEFAULT NULL,
  `folderid` int(10) unsigned NOT NULL DEFAULT '0',
  `optionid` int(10) unsigned NOT NULL DEFAULT '0',
  `timeout` int(11) unsigned NOT NULL DEFAULT '0',
  `langcode` char(2) NOT NULL DEFAULT 'en',
  `query` blob,
  PRIMARY KEY (`sessionid`),
  INDEX LABIX (`labyrinth`),
  INDEX USRIX (`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `updates`
--

DROP TABLE IF EXISTS `updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `updates` (
  `upid` int(11) NOT NULL AUTO_INCREMENT,
  `area` varchar(8) DEFAULT '',
  `pageid` int(11) DEFAULT NULL,
  `now` int(11) DEFAULT NULL,
  `pagets` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`upid`),
  INDEX AREIX (`area`),
  INDEX PAGIX (`pageid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `userid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accessid` int(10) unsigned NOT NULL DEFAULT '1',
  `imageid` int(10) unsigned NOT NULL DEFAULT '1',
  `nickname` varchar(255) DEFAULT NULL,
  `realname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `realm` varchar(32) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `aboutme` blob,
  `search` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`userid`),
  INDEX ACSIX (`accessid`),
  INDEX IMGIX (`imageid`),
  INDEX RLMIX (`realm`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

INSERT INTO `users` VALUES (1,1,1,'Guest','Guest','GUEST','public',SHA1('GUEST'),NULL,NULL,0);
INSERT INTO `users` VALUES (2,5,1,'Master','Master','master@example.com','admin',SHA1('Master'),'','',0);
INSERT INTO `users` VALUES (3,1,1,'','Test User','testuser@example.com','public',SHA1('testUser'),'http://labyrinth.missbarbell.co.uk','<p>test user</p>',1);

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-02-03 22:11:02
