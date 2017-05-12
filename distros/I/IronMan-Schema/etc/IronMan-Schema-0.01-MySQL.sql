-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sat Dec 12 15:38:01 2009
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `feed`;

--
-- Table: `feed`
--
CREATE TABLE `feed` (
  `id` varchar(255) NOT NULL,
  `url` text,
  `link` text,
  `title` text,
  `owner` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `url` (`url`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `tag`;

--
-- Table: `tag`
--
CREATE TABLE `tag` (
  `id` integer NOT NULL auto_increment,
  `name` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `feed_tag_map`;

--
-- Table: `feed_tag_map`
--
CREATE TABLE `feed_tag_map` (
  `feed` integer NOT NULL,
  `tag` integer NOT NULL,
  INDEX feed_tag_map_idx_feed (`feed`),
  INDEX feed_tag_map_idx_tag (`tag`),
  PRIMARY KEY (`feed`, `tag`),
  CONSTRAINT `feed_tag_map_fk_feed` FOREIGN KEY (`feed`) REFERENCES `feed` (`id`),
  CONSTRAINT `feed_tag_map_fk_tag` FOREIGN KEY (`tag`) REFERENCES `tag` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;


