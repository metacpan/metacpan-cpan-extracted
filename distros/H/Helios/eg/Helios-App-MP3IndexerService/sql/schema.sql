CREATE TABLE mp3_index_tb (
	mp3id INTEGER UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
	pathname   VARCHAR(255),
	year       CHAR(4),
	artist     VARCHAR(255),
	title      VARCHAR(255),
	album      VARCHAR(255),
	tracknum   VARCHAR(7),
	tagversion VARCHAR(32),
	genre      VARCHAR(32),
	bitrate    SMALLINT UNSIGNED,
	tracksize  INTEGER UNSIGNED,
	tracktime  VARCHAR(10),
	comment    VARCHAR(255)
);

