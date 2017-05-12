-- This file contains the commands to setup a sample database for
-- Mail::Abuse::Processor::TableDBI under mySQL.

-- First, you should create a database "abuse", using the following
-- command. This helps maintain the tables and resources used by this
-- application, logically grouped together.

-- $ mysql --host=dbhost --user=root --password=pass create abuso

-- You should review the commands in this file and apply them, making
-- the required changes for your particular database backend

-- Select the "abuso" database created above. Change this if done
-- differently in your location.

USE abuso;

-- The table below is the __skeleton__ where your information will
-- be stored. The information to associate for different subnets,
-- must be in additional columns that will be passed into the
-- resulting structure.

-- You will need to use this table in your 'dbi table name' statement
-- so that Mail::Abuse::Processor::TableDBI can use it. You may want
-- to change this default name to one which is more suitable for your
-- organization.

CREATE TABLE IF NOT EXISTS StaticData
(
	CIDR_Start		INTEGER NOT NULL
	COMMENT 'Start of the CIDR range for which this tuple applies',
	CIDR_End		INTEGER NOT NULL
	COMMENT 'End of the CIDR range for which this tuple applies',
	TIME_Start		INTEGER NOT NULL
	COMMENT 'Start of the time window during which this tuple applies',
	TIME_End		INTEGER NOT NULL
	COMMENT 'End of the time window during which this tuple applies',

-- ADD YOUR ADDITIONAL COLUMNS HERE

	PRIMARY KEY (CIDR_Start, CIDR_End, TIME_Start, TIME_End)
);

-- You may want to add additional columns at a later time, issuing
-- a command such as

-- 	ALTER TABLE StaticData ADD COLUMN Foo VARCHAR(255)

-- Consult your database documentation for details and gotchas.

-- Don't forget to create and grant SELECT/INSERT rights to the users
-- that will be querying and updating the information in this table...