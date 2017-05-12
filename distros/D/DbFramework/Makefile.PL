#! /usr/bin/perl -w
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use ExtUtils::MakeMaker;
use lib qw(lib);
use DbFramework::Util;
require 't/util.pl';

$catalog_db = 'dbframework_catalog';
%keytypes   = (primary => 0, foreign => 1, index => 2);

prompt(<<EOF);

Because there is so much variation in the syntax for creating
databases between different engines, DbFramework requires that you
create some databases before it can be installed.  Please ensure that
each engine you wish to test DbFramework against contains the catalog
database '$catalog_db' and a database which can be used for testing.

Press return to continue.
EOF

my $config = 't/Config.pm';

unless ( -f $config && prompt("$config exists, use it?", "Y") =~ /^y/i ) {
  # select drivers to test
  my @drivers = qw/mysql mSQL Pg/;
  my $drivers = prompt("Enter (space seperated) DBI drivers to test:", join(" ", @drivers));
  @drivers = split /\s/,$drivers;
  $test_db = 'test';

  my %driver;
  for my $driver ( @drivers ) {
    $test_db = prompt("\nConfiguring for driver 'DBI:$driver'\nEnter the name of your test database:", $test_db);
    print "\n";
    for my $db ( $catalog_db, $test_db ) {
      print "Configuring database '$db'\n";
      my $dsn;
      if ($driver eq "mysql") {
        $dsn = "database=$db";
      } elsif ($driver eq "mSQL") {
        $dsn = "database=$db";
      } elsif ($driver eq "Pg") {
        $dsn = "dbname=$db";
      } else {
        die "unknown DBI driver: $db";
      }
      $_ = prompt(qq{Enter the portion of the DSN that DBD::$driver will use to connect()
to $db i.e. 'DBI:$driver:[dsn_string]':}, $dsn);
      $driver{$driver}->{$db}->{dsn} = "DBI:$driver:$_";
      ($driver{$driver}->{$db}->{u},$driver{$driver}->{$db}->{p})
	= DbFramework::Util::get_auth();
      if ( $db eq $catalog_db ) {
	if ( prompt("Create schema for '$catalog_db' in DBI:$driver?", "N") !~ /^n/i ) {
	  # create catalog schema
	  my %sql = %{catalog_schema()};
	  # default to mysql DDL syntax
	  $ddl = (exists $sql{$driver}) ? $driver : 'mysql';
	  $dsn = $driver{$driver}->{$db}->{dsn};
	  $u   = $driver{$driver}->{$db}->{u};
	  $p   = $driver{$driver}->{$db}->{p};
	  my $dbh = DbFramework::Util::get_dbh($dsn,$u,$p);
	  $dbh->{PrintError} = 0;
	  for my $table ( qw/c_db c_key c_relationship c_table/ ) {
	    drop_create($catalog_db,$table,undef,$sql{$ddl}->{$table},$dbh);
	  }
	  my($t1,$t2) = ('foo','bar');
	  
	  ## set db
	  my $sql = qq{
	    INSERT INTO c_db
	      VALUES('$test_db')};
	  my $sth = do_sql($dbh,$sql);  $sth->finish;
	  
	  ## set tables
	  $sql = qq{
	    INSERT INTO c_table
	      VALUES('$t1','$test_db','bar')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  $sql = qq{
	    INSERT INTO c_table
	      VALUES('$t2','$test_db',NULL)};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  
	  ## set primary keys
	  $sql = qq{
	    INSERT INTO c_key
	      VALUES('$test_db','$t1','primary',$keytypes{primary},'foo:bar')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  $sql = qq{
	    INSERT INTO c_key
	      VALUES('$test_db','$t2','primary',$keytypes{primary},'foo')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  
	  ## set keys (indexes)
	  $sql = qq{
	    INSERT INTO c_key
	      VALUES('$test_db','$t1','foo',$keytypes{index},'bar:baz')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  $sql = qq{
	    INSERT INTO c_key
	      VALUES('$test_db','$t1','bar',$keytypes{index},'baz:quux')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  
	  ## set foreign keys
	  $sql = qq{
	    INSERT INTO c_key
	      VALUES('$test_db','$t2','f_foo',$keytypes{foreign},'foo_foo:foo_bar')};
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  $sql = qq{
	    INSERT INTO c_relationship
	      VALUES('$test_db','$t2','f_foo','$t1')
	    };
	  $sth = do_sql($dbh,$sql);  $sth->finish;
	  print "Done.\n";
	  $dbh->disconnect;
	}
      }
    }
  }

  open(CONFIG,">$config") || die "Couldn't open config file: $config: $!";
  print "Writing config file: $config\n";
  print CONFIG qq{package t::Config;

\$test_db = '$test_db';
\@drivers = qw/@drivers/;
\%driver  = (};

  while ( my($k,$v) = each %driver ) {
    print CONFIG "$k => { \n";
    while ( my($k,$v) = each %$v ) {
      print CONFIG "$k => { \n";
      while ( my($k,$v) = each %$v ) {
	print CONFIG "$k => '$v',";
      }
      print CONFIG "},\n";
    }
    print CONFIG "},\n";
  }
		  
  print CONFIG qq{);

1;

};
  
  close CONFIG;
  print <<EOF;

If you have supplied sensitive information you should remove $config
after ensuring that 'make test' passes all tests.

EOF

}

# return a hashref containing DDL to create the catalog for various drivers
sub catalog_schema {
  return { Pg => { c_db => q{
CREATE TABLE c_db (
		   db_name varchar(50) DEFAULT '' NOT NULL,
		   PRIMARY KEY (db_name)
		  )
},
		      c_key => q{
CREATE TABLE c_key (
		    db_name varchar(50) DEFAULT '' NOT NULL,
		    table_name varchar(50) DEFAULT '' NOT NULL,
		    key_name varchar(50) DEFAULT '' NOT NULL,
		    key_type int DEFAULT '0' NOT NULL,
		    key_columns varchar(255) DEFAULT '' NOT NULL,
		    PRIMARY KEY (db_name,table_name,key_name)
		   )
},
		      c_relationship => q{
CREATE TABLE c_relationship (
			     db_name varchar(50) DEFAULT '' NOT NULL,
			     fk_table varchar(50) DEFAULT '' NOT NULL,
			     fk_key varchar(50) DEFAULT '' NOT NULL,
			     pk_table varchar(50) DEFAULT '' NOT NULL,
			     PRIMARY KEY (db_name,fk_table,fk_key,pk_table)
			    )
},
		      c_table => q{
CREATE TABLE c_table (
		      table_name varchar(50) DEFAULT '' NOT NULL,
		      db_name varchar(50) DEFAULT '' NOT NULL,
		      labels varchar(127) DEFAULT '',
		      PRIMARY KEY (table_name,db_name)
		     )
} },
	   CSV => { c_db => q{
CREATE TABLE c_db (
		   db_name varchar(50)
		  )
},
		    c_key => q{
CREATE TABLE c_key (
		    db_name varchar(50),
		    table_name varchar(50),
		    key_name varchar(50),
		    key_type int,
		    key_columns varchar(255)
		   )
},
		    c_relationship => q{
CREATE TABLE c_relationship (
			     db_name varchar(50),
			     fk_table varchar(50),
			     fk_key varchar(50),
			     pk_table varchar(50)
			    )
},
		    c_table => q{
CREATE TABLE c_table (
		      table_name varchar(50),
		      db_name varchar(50),
		      labels varchar(127)
		     )
} },
	   mysql => { c_db => q{
CREATE TABLE c_db (
		   db_name varchar(50) DEFAULT '' NOT NULL,
		   PRIMARY KEY (db_name)
		  )
},
		      c_key => q{
CREATE TABLE c_key (
		    db_name varchar(50) DEFAULT '' NOT NULL,
		    table_name varchar(50) DEFAULT '' NOT NULL,
		    key_name varchar(50) DEFAULT '' NOT NULL,
		    key_type int DEFAULT '0' NOT NULL,
		    key_columns varchar(255) DEFAULT '' NOT NULL,
		    PRIMARY KEY (db_name,table_name,key_name)
		   )
},
		      c_relationship => q{
CREATE TABLE c_relationship (
			     db_name varchar(50) DEFAULT '' NOT NULL,
			     fk_table varchar(50) DEFAULT '' NOT NULL,
			     fk_key varchar(50) DEFAULT '' NOT NULL,
			     pk_table varchar(50) DEFAULT '' NOT NULL,
			     PRIMARY KEY (db_name,fk_table,fk_key,pk_table)
			    )
},
		      c_table => q{
CREATE TABLE c_table (
		      table_name varchar(50) DEFAULT '' NOT NULL,
		      db_name varchar(50) DEFAULT '' NOT NULL,
		      labels varchar(127) DEFAULT '' NULL,
		      PRIMARY KEY (table_name,db_name)
		     )
} },
	   mSQL => { c_db => q{
CREATE TABLE c_db (
		   db_name char(50) NOT NULL
		  )
},
		     c_key => q{
CREATE TABLE c_key (
		    db_name char(50) NOT NULL,
		    table_name char(50) NOT NULL,
		    key_name char(50) NOT NULL,
		    key_type int NOT NULL,
		    key_columns char(255) NOT NULL
)
},
		     c_relationship => q{
CREATE TABLE c_relationship (
			     db_name char(50) NOT NULL,
			     fk_table char(50) NOT NULL,
			     fk_key char(50) NOT NULL,
			     pk_table char(50) NOT NULL
			    )
},
		     c_table => q{
CREATE TABLE c_table (
		      table_name char(50) NOT NULL,
		      db_name char(50) NOT NULL,
		      labels char(127)
		     )
} }
	 }
}

# LICENSE is only availabe since ExtUtils::MakeMaker 6.30_01
use vars qw(%license $eummver);
%license = qw();
$eummver = $ExtUtils::MakeMaker::VERSION;
$eummver =~ s/_//;
%license = (LICENSE => "perl") if $eummver > 6.30;

WriteMakefile(
    NAME		=> "DbFramework",
    VERSION		=> "1.12",
    ABSTRACT		=> "Classes for Manipulating DBI Databases, Based on the CDIF Data Model Subject Area",
    AUTHOR		=> "imacat <imacat\@mail.imacat.idv.tw>",
    %license,
    PREREQ_PM		=> {
        "Alias"			=> 0,
        "DBI"			=> 1.06,
        "CGI"			=> 0,
        "Text::FillIn"		=> 0,
        "URI::Escape"		=> 0,
        "Term::ReadKey"		=> 0,
    },
    PL_FILES		=> { },
    SIGN		=> 1,
    
    dist		=> {
        COMPRESS	=> "gzip -9",
        SUFFIX		=> ".gz",
    },
    clean		=> {
        FILES		=> "t/Config.pm TAGS",
    },
);
