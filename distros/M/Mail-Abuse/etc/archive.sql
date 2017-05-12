-- This file contains the commands to setup a sample database for
-- Mail::Abuse::Processor::ArchiveDBI under mySQL.

-- First, you should create a database "abuse", using the following
-- command. This helps maintain the tables and resources used by this
-- application, logically grouped together.

-- $ mysql --host=dbhost --user=root --password=pass create abuso

-- You should review the commands in this file and apply them, making
-- the required changes for your particular database backend

-- Select the "abuso" database created above. Change this if done
-- differently in your location.

USE abuso;

-- The tables below are used to store the index for the abuse
-- reports. Each column is probably referenced from the configuration
-- file for abuso. Please double-check this. Remember that you will
-- need to define and GRANT a user with enough privileges so as to
-- perform INSERTs into these tables.

-- Table "Reports". This table stores information about each abuse
-- report processed by Mail::Abuse. Tipically, you will want the
-- primary key to be the filesystem location of the report after
-- processing. You may also want to keep track of the score of this
-- report, number of incidents and processing time.

CREATE TABLE IF NOT EXISTS Reports
(
	Location		VARCHAR(255) NOT NULL
	COMMENT 'Where Mail::Abuse::Processor::Store stored the report',
	Score			INTEGER DEFAULT 1
	COMMENT 'What Mail::Abuse::Processor::Score gave this report',
	Time			INTEGER UNSIGNED DEFAULT 0
	COMMENT 'When this report was analyzed by Mail::Abuse',
	Incidents		INTEGER DEFAULT 0
	COMMENT 'Count of incidents within this report',
	PRIMARY KEY (Location)
);

-- Each report has a number of incidents that will be stored into the
-- "Incidents" table. Tipically you want a foreign key so that
-- incidents and reports could be paired. Items to store for an
-- incident often include the type, IP address and time.

CREATE TABLE IF NOT EXISTS Incidents
(
	Location		VARCHAR(255) NOT NULL
	COMMENT 'The location of the report where this incident belongs',
	Id			INTEGER NOT NULL
	COMMENT 'The ID of this incident within the report',
	Type			VARCHAR(255) NOT NULL
	COMMENT 'The type of this report',
	IP			VARCHAR(64) NOT NULL
	COMMENT 'The IP address that caused this incident',
	Time			INTEGER UNSIGNED NOT NULL
	COMMENT 'The time in which the incident occurred',
	PRIMARY KEY (Location, Id),
	FOREIGN KEY (Location) REFERENCES Reports(Location)
);

-- Based on what your processes are, you may need to create indexes
-- for specific searches you might need. For instance, you may want to
-- create an index for the IP addresses or type of incidents, so that
-- your day to day queries for abuse processes are faster.

-- This part is highly installation-dependant, so we will not dwelve
-- into it.
