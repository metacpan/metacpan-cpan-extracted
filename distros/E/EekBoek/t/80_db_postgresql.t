# 80_db_postgresql.t -- Basic test PosgreSQL access
# Author          : Johan Vromans
# Created On      : Mon Jan 16 11:07:02 2006
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jun 14 22:15:34 2010
# Update Count    : 1

use strict;
use warnings;

use Test::More tests => 4;

# Some basic tests.

BEGIN {
    use_ok("DBI");
}

SKIP: {
    eval { require DBD::Pg };

    skip("DBI PostgreSQL driver (DBD::Pg) not installed", 3) if $@;

    # Check minimal Pg interface version.
    my $minpg = 1.31;
    ok($DBD::Pg::VERSION >= $minpg,
       "DBD::PG version = $DBD::Pg::VERSION, should be at east $minpg");

    SKIP: {
	skip("Database tests skipped on request", 2)
	  if $ENV{EB_SKIPDBTESTS};

	# Check whether we can contact the database.
	my @ds;
	eval {
	    @ds = DBI->data_sources("Pg");

	    diag("Connect error:\n\t" . ($DBI::errstr||"")) if $DBI::errstr;
	    skip("No access to database", 2)
	      if $DBI::errstr;# && $DBI::errstr =~ /FATAL:\s*(user|role) .* does not exist/;
	    diag("Connect error:\n\t" . ($DBI::errstr||"")) if $DBI::errstr;

	    ok(!$DBI::errstr, "Database Connect");
	};
	ok(@ds > 1, "Check databases");
    }
}
