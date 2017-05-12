require 5.005_03;  # need self-tie patch

use ExtUtils::MakeMaker;

$My{dbname} = "template1";	# Use a hash so perl doesn't complain about
$My{user}   = "";		# seeing the var only once.
$My{pass}   = "";

require "./db-info"
  if -r "./db-info";

print q{


The tests in this module need to connect to a Postgres
database.  You will need to provide a username, password, and the
name of the database.  Alternatively, the tests may be skipped.
};

$skip = ExtUtils::MakeMaker::prompt("Skip Tests?", "no");
if($skip =~ /^y/i) {
  unlink './db-info'
    if -f "./db-info";
} else {
  if(open D, ">db-info") {
    $My{dbname} = ExtUtils::MakeMaker::prompt("Database Name?", $My{dbname});
    $My{user}   = ExtUtils::MakeMaker::prompt("Database username? (type 'none' for no username)", $My{user});
    $My{pass}   = ExtUtils::MakeMaker::prompt("Database password? (type 'none' for no password)", $My{pass});

    $My{user} = "" if $My{user} eq "none";
    $My{pass} = "" if $My{pass} eq "none";
    print D qq{
\$My{dbname} = "$My{dbname}";
\$My{user}   = "$My{user}";
\$My{pass}   = "$My{pass}";
1;
};
    close D;
  } elsif(-r "db-info") {
    warn "Couldn't open db-info for writing -- using values in file.\n"
  } else {
    warn "Couldn't open db-info -- won't perform tests!\n";
  }
}

WriteMakefile(
    NAME	 => 'IO::BLOB::Pg',
    VERSION_FROM => 'lib/IO/BLOB/Pg.pm',
    'PREREQ_PM'  => {DBD::Pg => 0,
		     Test::More => 0,
		     DBI     => 0},
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
