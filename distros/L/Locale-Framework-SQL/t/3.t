# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { 
	use_ok('Locale::Framework');
	use_ok('Locale::Framework::SQL');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $TABLE="lang_sql_trans_test";

### Locale::Framework::wxLocale testing

my $DSN=$ENV{"DSN"};
my $DBUSER=$ENV{"DBUSER"};
my $DBPASS=$ENV{"DBPASS"};

SKIP: {
  skip "You need to specify a DSN to run this test",5 unless ($DSN);
  skip "You need to specify a DBUSER to run this test",5 unless ($DBUSER);

  Locale::Framework::init(new Locale::Framework::SQL(DSN => $DSN,DBUSER => $DBUSER,DBPASS => $DBPASS, TABLE => $TABLE));

  ok(_T("This is a test") eq "This is a test","Lang with Locale::Framework::SQL backend");

  ### Set language

  Locale::Framework::language("nl");
  ok((not _T("This is a test") eq "Dit is een test"),"Lang with Locale::Framework::SQL backend");

  ### Set translation and reread translation

  Locale::Framework::language("de");
  ok((Locale::Framework::set_translation("This is a test","Dies ist ein test")),"Lang with Locale::Framework::SQL backend");

  Locale::Framework::language("nl");
  ok((Locale::Framework::set_translation("This is a test","Dit is een test")),"Lang with Locale::Framework::SQL backend");
  Locale::Framework::clear_cache();
  ok(_T("This is a test") eq "Dit is een test","Lang with Locale::Framework::SQL backend");

  ### Cleanup

  my $dbh=DBI->connect($DSN,$DBUSER,$DBPASS);
  my $driver=lc($dbh->{Driver}->{Name});

  if ($driver eq "pg") {
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  } elsif ($driver eq "mysql") {
    $dbh->do("DROP INDEX $TABLE"."_idx ON $TABLE");
    $dbh->do("DROP TABLE $TABLE");
  } elsif ($driver eq "sqlite") {
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  } else {			# Hope for the best
    $self->{"dbh"}->{"PrintError"}=0;
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  }

  $dbh->disconnect();

}

