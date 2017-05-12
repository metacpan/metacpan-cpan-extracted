use EZDBI;
BEGIN{
  unlink('t/test.stb');
  unlink('t/02connect.db');
  unlink('t/TEST.dbf');
}


my $id=1;
local $" = ', ';
sub increment{ return $id++, scalar localtime; }


my $DBD;
my %DBD = (
#!	   File     =>[0, 'File:f_dir=t/'],
	   Sprite   =>[0, 'Sprite:t/02connect'],
	   SQLite   =>[0, 'SQLite:dbname=t/02connect.db'],
	   WTSprite =>[0, 'WTSprite:t/02connect'],        #Untested, but should work
	   XBase    =>[0.232, 'XBase:t/'],		  #Untested, but should work
	  );
foreach my $dbd ( keys %DBD ){
  eval "require DBD::$dbd";
  unless( $@ || ${'DBD::'.$dbd.'::VERSION'} < $DBD{$dbd}->[0] ){
    $DBD = $dbd;
    last;
  }
}
unless( $DBD ){
  print "1..0 #Skipped: None of @{[sort keys %DBD]}\n";
  exit 0;
}


print "1..31\n";


eval { Connect $DBD{$DBD}->[1]; };
print 'not ' if $@;
printf "ok %2i # Connected using DBD::$DBD\n", $id++;


eval { Sql 'Create Table TEST (id INTEGER, sql CHAR(42), time CHAR(24))'; };
print 'not ' if $@;
printf "ok %2i # Create Table TEST (id INTEGER, sql CHAR(42), time CHAR(24))\n", $id++;


#Check Insert, hashref style and reworked ??L code
{
  my $where = 'Into TEST';
  my @r = increment();
  eval{ Insert $where, {id=>$r[0], sql=>$where, time=>$r[1]};};
  print 'not ' if $@;
  printf "ok %2i # Insert a la hashref\n", $r[0];
  foreach my $sql ($where, "$where (id, sql, time)" ){
    foreach my $opts(
		     [$sql,                   increment()],
		     ["$sql Values",          increment()],
		     ["$sql Values ??L",      increment()],
		     ["$sql Values(??L)",     increment()],
		     ["$sql Values(?, ?, ?)", increment()]
		    ){
      eval {Insert @{$opts}[0,1,0,2];};
      print 'not ' if $@;
      printf "ok %2i # Insert $opts->[0]\n", $opts->[1];
    }
    @r = increment();
    eval{Insert "$sql Values('$r[0]', '$sql Values(INLINE)', '$r[1]')";};
    print 'not ' if $@;
    printf "ok %2i # Insert $sql Values(INLINE)\n", $r[0];
  }
}


{
  my @F = eval{Select '* From TEST'};
  print 'not ' if $@;
  printf "ok %i # Select *\n", $id++;
  if( $@ ){
    printf("ok %i # Skipped\n", $id++) for 17..29;
  }
  else{
    foreach ( @F ){
      printf "ok %i # [@{[map{qq('$_')} @$_]}]\n", $id++;
    }
  }
}


#Check Update hashref style
eval{ Update 'TEST', {time=>0}; };
print 'not ' if $@;
printf "ok %i # Update a la hashref\n", $id++;


#XXX Select and check for non 0 times


eval {Sql 'Drop Table TEST'; };
print 'not ' if $@;
printf "ok %i # Drop Table TEST\n", $id++;
