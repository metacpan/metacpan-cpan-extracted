package DataAccess;
require ConfigPathes;

use strict;
use warnings;
use DBI;

my $dir=$ConfigPathes::persistent;
$dir=~s/\\/\//g; #DBD::CSV needs this.
our $dbh=DBI->connect("DBI:CSV:f_dir=$dir;") or die DBI::errstr;
#our $dbh=DBI->connect("DBI:CSV:f_dir=".$ConfigPathes::persistent.";")

#our $dbh=DBI->connect("DBI:mysql:database=$database;host=$hostname;port=$port", $user, $password); # for mysql

