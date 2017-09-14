package t::helper;

sub exec_sql_stmts_in_file { #_{

  my $dbh      = shift;
  my $filename = shift;

  open (my $sql, '<', $filename) or die "Could not open $filename";
  
  while (my $stmt = <$sql>) {
    chomp $stmt;
    $stmt =~ s/--.*//;
    next unless $stmt =~ /\S/;
    $dbh->do($stmt) or die "Could not execute $stmt";
  }
  
  close $sql;
} #_}

1;
