-- MySQL dump 10.11
--
-- Host: db27    Database: specieswiki
-- ------------------------------------------------------
-- Server version	4.0.40-wikimedia-log
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `user_groups`
--

DROP TABLE IF EXISTS `user_groups`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `user_groups` (
  `ug_user` int(5) unsigned NOT NULL default '0',
  `ug_group` varchar(16) binary NOT NULL default '',
  PRIMARY KEY  (`ug_user`,`ug_group`),
  KEY `ug_group` (`ug_group`)
) TYPE=InnoDB;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `user_groups`
--

LOCK TABLES `user_groups` WRITE;
/*!40000 ALTER TABLE `user_groups` DISABLE KEYS */;
INSERT INTO `user_groups` VALUES (1062,'bot'),(3560,'bot'),(3774,'bot'),(5652,'bot'),(7298,'bot'),(7369,'bot'),(7568,'bot'),(8033,'bot'),(9737,'bot'),(132832,'bot'),(6,'bureaucrat'),(42,'bureaucrat'),(67,'bureaucrat'),(210,'bureaucrat'),(568,'bureaucrat'),(1033,'bureaucrat'),(1387,'bureaucrat'),(2297,'bureaucrat'),(3194,'bureaucrat'),(4305,'bureaucrat'),(6748,'bureaucrat'),(6764,'bureaucrat'),(6873,'bureaucrat'),(6984,'bureaucrat'),(6,'sysop'),(42,'sysop'),(67,'sysop'),(78,'sysop'),(210,'sysop'),(410,'sysop'),(568,'sysop'),(1033,'sysop'),(1387,'sysop'),(2297,'sysop'),(2391,'sysop'),(3082,'sysop'),(3194,'sysop'),(4305,'sysop'),(6748,'sysop'),(6764,'sysop'),(6806,'sysop'),(6873,'sysop'),(6984,'sysop'),(7298,'sysop'),(8033,'sysop'),(9863,'sysop');
/*!40000 ALTER TABLE `user_groups` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-12-04 18:19:57
