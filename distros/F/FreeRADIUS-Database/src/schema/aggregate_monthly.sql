-- MySQL dump 10.11
--
-- Host: localhost    Database: radius
-- ------------------------------------------------------
-- Server version	5.0.77

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
-- Table structure for table `aggregate_monthly`
--

DROP TABLE IF EXISTS `aggregate_monthly`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `aggregate_monthly` (
  `MTotAcctId` bigint(21) NOT NULL auto_increment,
  `UserName` varchar(64) NOT NULL default '',
  `AcctDate` date NOT NULL default '0000-00-00',
  `ConnNum` bigint(12) default NULL,
  `ConnTotDuration` bigint(12) default NULL,
  `ConnMaxDuration` bigint(12) default NULL,
  `ConnMinDuration` bigint(12) default NULL,
  `InputOctets` bigint(20) unsigned default NULL,
  `OutputOctets` bigint(20) unsigned default NULL,
  `NASIPAddress` varchar(15) default NULL,
  PRIMARY KEY  (`MTotAcctId`),
  KEY `UserName` (`UserName`),
  KEY `AcctDate` (`AcctDate`),
  KEY `UserOnDate` (`UserName`,`AcctDate`),
  KEY `NASIPAddress` (`NASIPAddress`)
) ENGINE=MyISAM AUTO_INCREMENT=1045785 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-10-13 15:31:39
