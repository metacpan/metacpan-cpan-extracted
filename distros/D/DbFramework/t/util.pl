
sub drop_create {
  my($db,$table,$c,$sql,$dbh) = @_;
  my $rv = $dbh->do("DROP TABLE $table");

  ## init catalog
  if ( defined $c ) {
    my $c_sql = qq{
      DELETE FROM c_key
      WHERE db_name      = '$db'
      AND   ( table_name = '$table' )
    };
    my $sth = do_sql($c->dbh,$c_sql); $sth->finish;
    $c_sql = qq{
      DELETE FROM c_relationship
      WHERE db_name    = '$db'
      AND   ( fk_table = '$table' )
    };
    $sth = do_sql($c->dbh,$c_sql); $sth->finish;
  }

  return $dbh->do($sql) || die $dbh->errstr;
}

sub do_sql {
  my($dbh,$sql) = @_;
  #print STDERR "$sql\n";
  my $sth = $dbh->prepare($sql) || die($dbh->errstr);
  my $rv  = $sth->execute       || die($sth->errstr);
  return $sth;
}  

sub connect_args($$) {
  my %driver      = %t::Config::driver;
  my($driver,$db) = @_;
  my $catalog_db  = $DbFramework::Catalog::db;
  my($db_name,$dsn,$u,$p);

 SWITCH: {
    ($db eq 'catalog') && do {
      $db_name  = $catalog_db;
    };
    ($db eq 'test') && do {
      delete $driver{$driver}->{$catalog_db};
      ($db_name) = keys %{$driver{$driver}};
    };
  }
  $dsn = $driver{$driver}->{$db_name}->{dsn};
  $u   = $driver{$driver}->{$db_name}->{u};
  $p   = $driver{$driver}->{$db_name}->{p};
  return($db_name,$dsn,$u,$p);
}

1;
