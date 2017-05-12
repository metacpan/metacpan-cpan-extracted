-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sat Dec 12 16:12:47 2009
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

DROP TABLE IF EXISTS `posts`;

--
-- Table: `posts`
--
CREATE TABLE `posts` (
  `post_id` integer NOT NULL auto_increment,
  `feed_id` varchar(255) NOT NULL,
  `url` text NOT NULL,
  `title` text NOT NULL,
  `posted_on` datetime NOT NULL,
  `summary` text,
  `body` text NOT NULL,
  `summary_filtered` text,
  `body_filtered` text,
  INDEX posts_idx_feed_id (`feed_id`),
  PRIMARY KEY (`post_id`),
  UNIQUE `url` (`url`),
  CONSTRAINT `posts_fk_feed_id` FOREIGN KEY (`feed_id`) REFERENCES `feed` (`id`)
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


