-- MySQL dump 10.9
--
-- Host: fantom40.gsc.riken.jp    Database: eeDB_fantom4_may08
-- ------------------------------------------------------
-- Server version	4.1.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `assembly`
--

CREATE TABLE `assembly` (
  `assembly_id` int(11) NOT NULL auto_increment,
  `taxon_id` int(11) default NULL,
  `ncbi_version` varchar(32) default NULL,
  `ucsc_name` varchar(32) default NULL,
  `release_date` date default NULL,
  PRIMARY KEY  (`assembly_id`),
  UNIQUE KEY `uqasm` (`taxon_id`,`ncbi_version`,`ucsc_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `chrom`
--

CREATE TABLE `chrom` (
  `chrom_id` int(11) NOT NULL auto_increment,
  `chrom_name` char(64) default NULL,
  `assembly_id` int(11) default NULL,
  `chrom_length` int(11) default NULL,
  `chrom_type` char(64) default NULL,
  `description` char(255) default NULL,
  PRIMARY KEY  (`chrom_id`),
  UNIQUE KEY `uqname` (`chrom_name`,`assembly_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 ROW_FORMAT=FIXED;

--
-- Table structure for table `chrom_chunk`
--

CREATE TABLE `chrom_chunk` (
  `chrom_chunk_id` int(11) NOT NULL auto_increment,
  `chrom_id` int(11) default NULL,
  `chrom_start` int(10) unsigned default NULL,
  `chrom_end` int(10) unsigned default NULL,
  `chunk_len` int(11) default NULL,
  PRIMARY KEY  (`chrom_chunk_id`),
  UNIQUE KEY `uniq_chunk` (`chrom_id`,`chrom_start`,`chrom_end`),
  KEY `chrom_name_id` (`chrom_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `chrom_chunk_seq`
--

CREATE TABLE `chrom_chunk_seq` (
  `chrom_chunk_id` int(11) NOT NULL default '0',
  `length` int(10) NOT NULL default '0',
  `sequence` longtext NOT NULL,
  PRIMARY KEY  (`chrom_chunk_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=10000000 AVG_ROW_LENGTH=19000;

--
-- Table structure for table `experiment`
--

CREATE TABLE `experiment` (
  `experiment_id` int(11) NOT NULL auto_increment,
  `platform` varchar(255) NOT NULL default '',
  `exp_accession` varchar(255) NOT NULL default '',
  `display_name` varchar(255) NOT NULL default '',
  `series_name` varchar(255) NOT NULL default '',
  `series_point` float NOT NULL default '0',
  `is_active` char(1) NOT NULL default '',
  PRIMARY KEY  (`experiment_id`),
  UNIQUE KEY `experiment_unq_name` USING BTREE (`exp_accession`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `experiment_2_metadata`
--

CREATE TABLE `experiment_2_metadata` (
  `experiment_id` int(11) default NULL,
  `metadata_id` int(11) default NULL,
  UNIQUE KEY `experiment_2_metadata_uq` USING BTREE (`experiment_id`,`metadata_id`),
  KEY `experiment_id` USING BTREE (`experiment_id`),
  KEY `metadata_id` USING BTREE (`metadata_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `experiment_2_symbol`
--

CREATE TABLE `experiment_2_symbol` (
  `experiment_id` int(11) default NULL,
  `symbol_id` int(11) default NULL,
  UNIQUE KEY `experiment_2_symbol_uq` USING BTREE (`experiment_id`,`symbol_id`),
  KEY `symbol_id` (`symbol_id`),
  KEY `experiment_id` USING BTREE (`experiment_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Table structure for table `feature`
--

CREATE TABLE `feature` (
  `feature_id` int(11) NOT NULL auto_increment,
  `chrom_id` int(11) default NULL,
  `feature_source_id` int(11) NOT NULL default '0',
  `chrom_start` int(11) default NULL,
  `chrom_end` int(11) default NULL,
  `strand` char(1) default NULL,
  `primary_name` char(64) default NULL,
  `significance` double default '1',
  `last_update` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`feature_id`),
  KEY `chrom_id` (`chrom_id`),
  KEY `feature_set_id` (`feature_source_id`),
  KEY `feature_desc` (`primary_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `feature_2_chunk`
--

CREATE TABLE `feature_2_chunk` (
  `feature_id` int(11) default NULL,
  `chrom_chunk_id` int(11) default NULL,
  UNIQUE KEY `feature_2_chunk_uq` (`feature_id`,`chrom_chunk_id`),
  KEY `feature_id` (`feature_id`),
  KEY `chrom_chunk_id` (`chrom_chunk_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `feature_2_metadata`
--

CREATE TABLE `feature_2_metadata` (
  `feature_id` int(11) default NULL,
  `metadata_id` int(11) default NULL,
  UNIQUE KEY `feature_2_metadata_uq` USING BTREE (`feature_id`,`metadata_id`),
  KEY `feature_id` (`feature_id`),
  KEY `metadata_id` USING BTREE (`metadata_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `feature_2_symbol`
--

CREATE TABLE `feature_2_symbol` (
  `feature_id` int(11) default NULL,
  `symbol_id` int(11) default NULL,
  UNIQUE KEY `feature_2_symbol_uq` (`feature_id`,`symbol_id`),
  KEY `feature_id` (`feature_id`),
  KEY `symbol_id` (`symbol_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `expression`
--

CREATE TABLE `expression` (
  `expression_id` int(11) NOT NULL auto_increment,
  `experiment_id` int(11) NOT NULL default '0',
  `feature_id` int(11) NOT NULL default '0',
  `datatype_id` int(11) default NULL,
  `value` double default NULL,
  `sig_error` double default NULL,
  PRIMARY KEY  (`expression_id`),
  KEY `feature_id` (`feature_id`),
  UNIQUE KEY `express_uq` (`experiment_id`,`feature_id`, `datatype_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `expression_datatype`
--

CREATE TABLE `expression_datatype` (
  `datatype_id` int(11) NOT NULL auto_increment,
  `datatype` char(64) NOT NULL default '',
  PRIMARY KEY  (`datatype_id`),
  UNIQUE KEY `datatype_unq` (`datatype`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `edge`
--

CREATE TABLE `edge` (
  `edge_id` int(11) NOT NULL auto_increment,
  `edge_source_id` int(11) default NULL,
  `feature1_id` int(11) default NULL,
  `feature2_id` int(11) default NULL,
  `direction` char(1) default NULL,
  `sub_type` char(16) default NULL,
  `weight` float default NULL,
  PRIMARY KEY  (`edge_id`),
  KEY `feature1_id` (`feature1_id`),
  KEY `feature2_id` (`feature2_id`),
  KEY `edge_source_id` (`edge_source_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `edge_2_metadata`
--

CREATE TABLE `edge_2_metadata` (
  `edge_id` int(11) default NULL,
  `metadata_id` int(11) default NULL,
  UNIQUE KEY `edge_2_metadata_uq` USING BTREE (`edge_id`,`metadata_id`),
  KEY `edge_id` USING BTREE (`edge_id`),
  KEY `metadata_id` USING BTREE (`metadata_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `edge_2_symbol`
--

CREATE TABLE `edge_2_symbol` (
  `edge_id` int(11) default NULL,
  `symbol_id` int(11) default NULL,
  UNIQUE KEY `edge_2_symbol_uq` USING BTREE (`edge_id`,`symbol_id`),
  KEY `symbol_id` USING BTREE (`symbol_id`),
  KEY `edge_id` USING BTREE (`edge_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `edge_source`
--

CREATE TABLE `edge_source` (
  `edge_source_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `display_name` varchar(255) default NULL,
  `category` varchar(255) default NULL,
  `classification` varchar(64) default NULL,
  `is_active` char(1) NOT NULL default 'y',
  `is_visible` char(1) NOT NULL default 'y',
  `create_date` date default NULL,
  `f1_ext_peer` varchar(255)  default NULL,
  `f2_ext_peer` varchar(255)  default NULL,

  PRIMARY KEY  (`edge_source_id`),
  UNIQUE KEY `unq_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `edge_source_2_metadata`
--

CREATE TABLE `edge_source_2_metadata` (
  `edge_source_id` int(11) default NULL,
  `metadata_id` int(11) default NULL,
  UNIQUE KEY `edgesrc_2_metadata_unq` USING BTREE (`edge_source_id`,`metadata_id`),
  KEY `edge_source_id` (`edge_source_id`),
  KEY `metadata_id` (`metadata_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `edge_source_2_symbol`
--

CREATE TABLE `edge_source_2_symbol` (
  `edge_source_id` int(11) default NULL,
  `symbol_id` int(11) default NULL,
  UNIQUE KEY `edgesrc2sym_unq` USING BTREE (`edge_source_id`,`symbol_id`),
  KEY `edge_source_id` (`edge_source_id`),
  KEY `symbol_id` (`symbol_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `feature_source`
--

CREATE TABLE `feature_source` (
  `feature_source_id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `category` varchar(255) default NULL,
  `is_active` char(1) NOT NULL default '',
  `is_visible` char(1) NOT NULL default '',
  `import_source` varchar(255) default NULL,
  `import_date` date default NULL,
  `feature_count` int(11) default NULL,  
  PRIMARY KEY  (`feature_source_id`),
  UNIQUE KEY `fsrc_unq` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `feature_source_2_metadata`
--

CREATE TABLE `feature_source_2_metadata` (
  `feature_source_id` int(11) default NULL,
  `metadata_id` int(11) default NULL,
  UNIQUE KEY `fsrc2mdata_unq` (`metadata_id`,`feature_source_id`),
  KEY `feature_source_id` (`feature_source_id`),
  KEY `metadata_id` (`metadata_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `feature_source_2_symbol`
--

CREATE TABLE `feature_source_2_symbol` (
  `feature_source_id` int(11) default NULL,
  `symbol_id` int(11) default NULL,
  UNIQUE KEY `fsrc2sym_unq` (`symbol_id`,`feature_source_id`),
  KEY `feature_source_id` (`feature_source_id`),
  KEY `symbol_id` (`symbol_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `metadata`
--

CREATE TABLE `metadata` (
  `metadata_id` int(11) NOT NULL auto_increment,
  `data_type` varchar(255) character set utf8 collate utf8_bin default NULL,
  `data` mediumtext character set utf8 collate utf8_bin,
  PRIMARY KEY  USING BTREE (`metadata_id`),
  KEY `data_prefix` (`data`(13)),
  KEY `type` (`data_type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 MIN_ROWS=10000000;


--
-- Table structure for table `peer`
--

CREATE TABLE `peer` (
  `uuid` varchar(255) NOT NULL default '',
  `alias` varchar(255) NOT NULL default '',
  `is_self` tinyint(1) default '0',
  `db_url` varchar(255) default NULL,
  `web_url` varchar(255) default NULL,
  PRIMARY KEY  (`uuid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
--
-- Table structure for table `symbol`
--

CREATE TABLE `symbol` (
  `symbol_id` int(11) NOT NULL auto_increment,
  `sym_type` char(32) default NULL,
  `sym_value` char(128) default NULL,
  PRIMARY KEY  (`symbol_id`),
  UNIQUE KEY `symbol_unq` (`sym_type`,`sym_value`),
  KEY `sym_type` (`sym_type`),
  KEY `sym_value` (`sym_value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MIN_ROWS=10000000;

--
-- Table structure for table `taxon`
--

CREATE TABLE `taxon` (
  `taxon_id` int(10) unsigned NOT NULL default '0',
  `genus` varchar(50) default NULL,
  `species` varchar(50) default NULL,
  `sub_species` varchar(50) default NULL,
  `common_name` varchar(100) default NULL,
  `classification` mediumtext,
  PRIMARY KEY  (`taxon_id`),
  KEY `genus` (`genus`,`species`),
  KEY `common_name` (`common_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
