use strict;
use warnings;
use utf8;
use lib qw( ../lib lib );

package Local::Fixtures;
our $VERSION = 0.2;

=head1 NAME

Local::Fixtures - test library

=head1 DESCRIPTION

Provides a test database, and content against which to test.

Did try L<Test::Database|Test::Database> but it did not auto-configure,
which may be me or the module - ticket opened in RT on 2011-01-06.

Instead tries common usernames and passwords on the MySQL 'test' DB.

=head1 AUTHOR

Copyright (C) Lee Goddard, 2010-2011. All Rights Reserved.

=cut

use Test::More;
use DBI;

our ($test_user, $test_password, $dbh);
our $test_dsn = $ENV{'DBI_DSN'} || 'DBI:mysql:database=test';

my @cred = (
		($ENV{DBI_USER}? ([$ENV{DBI_USER} => $ENV{DBI_PASS} || '']) : ()),
		[root => ''],
		[root => 'password'],
		[root => 'pass'],
);



# Try Test::Database
eval 'require Test::Database';
if (not $@){
	use Data::Dumper;
	my @handles = Test::Database->handles( { dbd => 'mysql' } );
	$dbh = $handles[0]->dbh() if $handles[0];
}

if (not $dbh){
	foreach my $cred (@cred){
		($test_user, $test_password) = @$cred;
		$dbh = eval {
			DBI->connect( $test_dsn, $test_user, $test_password, {
				PrintWarn => 0,
				PrintError => 0,
			} );
		};
		last if $dbh;
	}
}

our $table_name = 'test_98127645';

END {
	$dbh->do("DROP TABLE $table_name") if $dbh and not $ENV{LEE_TESTING};	
}

our $col_comment = 'My Tiny Integer Signed';
our $table_comment = 'This is a test table; delete it, please.';
our $default_text = 'This is default text';

if ($dbh and ref $dbh){
	
	$dbh->{PrintWarn}  = 1;
	$dbh->{PrintError} = 1;
	
	$dbh->do("DROP TABLE IF EXISTS $table_name ");
	$dbh->do("CREATE TABLE $table_name (
		my_tinyint_s TINYINT NOT NULL COMMENT '$col_comment',
		my_tinyint_u TINYINT UNSIGNED NOT NULL,
		my_smallint_s SMALLINT NOT NULL,
		my_smallint_u SMALLINT UNSIGNED NOT NULL,
		my_mediumint_s MEDIUMINT NOT NULL,
		my_mediumint_u MEDIUMINT UNSIGNED NOT NULL,
		my_int_s INT NOT NULL,
		my_int_u INT UNSIGNED NOT NULL,
		my_bigint_s BIGINT NOT NULL,
		my_bigint_u BIGINT UNSIGNED NOT NULL,
		my_float FLOAT NOT NULL,
		my_floatn FLOAT(3) NOT NULL,
		my_floatnm FLOAT(3,2) NOT NULL,
		my_real REAL NOT NULL,
		my_double DOUBLE NOT NULL,
		my_double_precision DOUBLE PRECISION NOT NULL,
		my_decimal DECIMAL NOT NULL,
		my_numeric NUMERIC NOT NULL,
		my_decimalmd DECIMAL(5,2) NOT NULL,
		my_numericmd NUMERIC(5,2) NOT NULL,
		my_bit BIT(4) NOT NULL,
		my_bit1 BIT(1) NOT NULL,
		my_datetime DATETIME NOT NULL,
		my_date DATE NOT NULL,
		my_timestamp TIMESTAMP NOT NULL,
		my_time TIME NOT NULL,
		my_year YEAR NOT NULL,
		my_year4 YEAR(4) NOT NULL,
		my_year2 YEAR(2) NOT NULL,
		my_char CHAR(23) NOT NULL,
		my_varchar VARCHAR(23) NOT NULL,
		my_binary BINARY(23) NOT NULL,
		my_varbinary VARBINARY(23) NOT NULL,
		my_tinyblob TINYBLOB NOT NULL,
		my_blob BLOB NOT NULL,
		my_mediumblob MEDIUMBLOB NOT NULL,
		my_longblob LONGBLOB NOT NULL,
		my_tinytext TINYTEXT NOT NULL,
		my_text TEXT NOT NULL,
		my_mediumtext MEDIUMTEXT NOT NULL,
		my_longtext LONGTEXT NOT NULL,
		my_enum ENUM('one', 'two', 'three', 'comma,', 'apostrophe''') NOT NULL,
		my_set SET('one', 'two', 'three') NOT NULL,
		my_true_boolean BIT(1) NOT NULL,
		my_default_text VARCHAR(100) DEFAULT '$default_text'
	
	) Engine=InnoDB COMMENT='$table_comment' DEFAULT CHARSET=utf8");
	
	$dbh->do("INSERT INTO $table_name SET my_tinyint_s = -128");
	
	while (my $d = <DATA>){
		chomp $d;
		next unless $d;
		my ($col, $val) = split /\s*=\s*/, $d;
		# No dbi->quote, so we can control quoting in DATA
		$dbh->do("UPDATE $table_name SET `$col` = $val");
		if ($dbh->err){
			BAIL_OUT $dbh->errstr;	
		}
	}
	
	close DATA;
}

# End of fixture set-up
1;

__DATA__

my_tinyint_u = 255
my_smallint_s = -32768
my_smallint_u = 65535
my_mediumint_s = -8388608
my_mediumint_u = 16777215
my_int_s = -2147483648
my_int_u = 4294967295
my_bigint_s = -9223372036854775808
my_bigint_u = 18446744073709551615
my_float = 123.456
my_floatn = 123
my_floatnm = 999.99
my_real = 123.456
my_double = 123.456
my_double_precision = 123.456
my_decimal = 123.45
my_numeric = 123.45
my_bit = 101
my_bit1 = 1
my_datetime = '0000-00-00 00:00:00'
my_date = '0000-00-00'
my_timestamp = '0000-00-00 00:00:00'
my_time = '00:00:00'
my_year = '0000'
my_year2 = '00'
my_year4 = '2010'
my_char = '123456789_'
my_varchar = '123456789_'
my_binary = 'Gödöllő'
my_varbinary = 'Gödöllő'
my_tinyblob = 'Gödöllő'
my_blob = 'Gödöllő'
my_mediumblob = 'Gödöllő'
my_longblob = 'Gödöllő'
my_tinytext = 'Gödöllő'
my_text = 'Gödöllő'
my_mediumtext = 'Gödöllő'
my_longtext = 'Gödöllő'
my_enum = 'three' 
my_set = 'two,three' 
my_true_boolean = 1
my_default_text = 'Not the db-set default value'
my_numericmd = 999.99
my_decimalmd = 999.99
