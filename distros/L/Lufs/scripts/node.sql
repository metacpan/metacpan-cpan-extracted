DROP TABLE node;
CREATE TABLE node (
	ino BIGSERIAL NOT NULL PRIMARY KEY,
	name TEXT,
	mode BIGINT,
	parent BIGINT REFERENCES node (ino),
	content oid,
	nlink BIGINT NOT NULL DEFAULT 1,
	uid INT NOT NULL DEFAULT 0,
	gid INT NOT NULL DEFAULT 0,
	rdev BIGINT,
	size BIGINT,
	blksize INT NOT NULL DEFAULT 512,
	blocks BIGINT,
	atime TIMESTAMP NOT NULL DEFAULT 'NOW()',
	mtime TIMESTAMP NOT NULL DEFAULT 'NOW()',
	ctime TIMESTAMP NOT NULL DEFAULT 'NOW()'
);

DROP FUNCTION abs_path ( BIGINT );
CREATE FUNCTION abs_path ( BIGINT ) RETURNS TEXT AS '
use DBD::PgSPI;
use DBIx::Simple;
my $dbx = DBIx::Simple->connect($pg_dbh);
my @nm;
my ($name, $node) = ("", $_[0]);
while (length(($dbx->query("SELECT name FROM node WHERE ino = ?", $node)->list)[0])) {
	push @nm, $node;
	($node) = $dbx->query("SELECT parent FROM node WHERE ino = ?", $node)->list;
} unless (@nm) { @nm = ($_[0]) } 
for (reverse@nm) {
	$name .= sprintf "/%s", ($dbx->query("SELECT name FROM node WHERE ino = ?", $_)->list)[0];
}
$name
' LANGUAGE plperlu;

INSERT INTO node ( name, mode, parent, size ) VALUES ( '' 	, 16877, 1, 4096 );
INSERT INTO node ( name, mode, parent, size ) VALUES ( 'sbin' , 16877, 1, 4096 );
INSERT INTO node ( name, mode, parent, size ) VALUES ( 'etc' 	, 16877, 1, 4096);

-- INSERT INTO node ( name, mode, parent ) VALUES ( 'passwd', 33188, 3 );

SELECT * FROM node;
