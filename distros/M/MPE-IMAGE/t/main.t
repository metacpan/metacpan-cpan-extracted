# use Carp;
# use Data::Dumper;
use Test;
use strict;

BEGIN { plan tests => 39 }

use MPE::IMAGE ':all';

my %tests_done;

sub weed_sets { 
  # Remove sets which would not be acceptable for testing:
  #   1) Automatic Masters
  #   2) Full sets
  #   3) Details with paths

  my $db = shift;
  my @set_info;

  foreach (@_) {
    # We can't use dset_info because we need entry count
    push @set_info,{ DbInfo($db,205,$_) };  
  }
  @set_info = grep {
    $_->{type} ne 'A' and
    $_->{entries} < $_->{'max cap'}
  } @set_info;
  my @master_set_info;
  if (@master_set_info = grep { $_->{type} eq 'M' } @set_info) {
    @set_info = @master_set_info;
  } else {
    @set_info = grep { (DbInfo($db,301,$_->{name})) == 0 } @set_info;
  }
  return map { $_->{name} } @set_info;
}
  
# First check on $DbError
ok($DbError eq '');
my $db = DbOpen('Blahsville','Yawn',5);
ok($DbStatus[0] == -11);
ok($DbError eq 'BAD DATABASE NAME OR PRECEDING BLANKS MISSING');
$tests_done{'$DbError'} = 1;
$tests_done{'@DbStatus'} = 1;

print "# Three tests done so far\n";
my $test_write = '';
print STDERR "\n\nIf you answer yes to the following, I will create a single\n";
print STDERR "record in a dataset of the test database, update and then\n";
print STDERR "delete that record.\n\n";
while ($test_write !~ /^y/i and $test_write !~ /^n/i and $test_write ne '//') {
  print STDERR "Do you wish to test DbPut, DbUpdate and DbDelete? ";
  chomp($test_write = <>);
}
exit if $test_write eq '//';
$test_write = ($test_write =~ /^y/i);
my $update_only = '';
my $write_target = '';
my $find_target  = '';
my $find_item    = '';
my $keyed_target = '';
my @sets;
my @nonempty_sets;
my @set_info;
my $open_mode = ($test_write) ? 1 : 5;
my $database;
my $pass = '';

DB_QUERY: {
  print STDERR "\nTo test the IMAGE::MPE module, I need the name of an\n";
  print STDERR "existing IMAGE database: ";
  chomp($database = <>);
  exit if $database eq '//';

  PASS_QUERY: {
    print STDERR "\nPlease provide me with a password which will give me\n";
    print STDERR ($test_write) ? "WRITE" : "read-only";
    print STDERR " access to $database: ";
    chomp($pass = <>);
    exit if $pass eq '//';
    print STDERR "\n";

    # Open the test database (prefer 1/5 so we can test DbLock)
    $db = DbOpen($database,$pass,$open_mode);
    if ($DbStatus[0] == 0) {
      last PASS_QUERY;
    } elsif ($DbStatus[0] == -13 or $DbStatus[0] == -21) {
      print STDERR "Problems.  That password isn't working for me.\n";
      print STDERR "IMAGE says: $DbError\n\n";
      print STDERR "Please re-enter the password (// to exit)\n";
      redo PASS_QUERY;
    } else {
      unless ($DbStatus[0] == -1 and 
              $DbStatus[1] ==  0 and 
              $DbStatus[2] == 48) {
        print STDERR "Problems.  I'm unable to open $database.\n";
        print STDERR "IMAGE says: $DbError\n\n";
        print STDERR "Please re-enter the database (// to exit)\n";
        redo DB_QUERY;
      }
    }

    # If we get here, we could not open it due to it already being open
    # mode 2, 4, 6 or 8.
    $open_mode = ($test_write) ? 4 : 6;
    $db = DbOpen($database,$pass,$open_mode);
    if ($DbStatus[0] == 0) {
      last PASS_QUERY;
    } else {
      unless ($DbStatus[0] == -32 or 
               ($DbStatus[0] == -1 and 
                $DbStatus[1] == 0 and
                $DbStatus[2] == 90)
              ) {
        print STDERR "Problems.  I'm unable to open $database.\n";
        print STDERR "IMAGE says: $DbError\n\n";
        print STDERR "Please re-enter the database (// to exit)\n";
        redo DB_QUERY;
      }
    }

    # We won't reach this unless $test_write is true
    $open_mode = ($DbStatus[0] == -1) ? 2 : 6;
    $db = DbOpen($database,$pass,$open_mode);
    if ($DbStatus[0] != 0 and $DbStatus[0] != -32) {
      print STDERR "Problems.  I'm unable to open $database.\n";
      print STDERR "IMAGE says: $DbError\n\n";
      print STDERR "Please re-enter the database (// to exit)\n";
      redo DB_QUERY;
    }

    if ($DbStatus[0] == -32) {
      $open_mode = 6;
      $db = DbOpen($database,$pass,$open_mode);
      if ($DbStatus[0] != 0) {
        print STDERR "Problems.  I'm unable to open $database.\n";
        print STDERR "IMAGE says: $DbError\n\n";
        print STDERR "Please re-enter the database (// to exit)\n";
        redo DB_QUERY;
      }
    }
      
    if ($open_mode == 6) {
      print STDERR "$database is either open mode 4 or 8 or is currently\n";
      print STDERR "being DBSTOREd.  We've opened it mode 6 and will\n";
      print STDERR "only test the read functions.\n\n";
      $test_write = '';
    } else {
      print STDERR "$database is already open mode 2, so we've also\n";
      print STDERR "opened it mode 2 and will only test DbUpdate using the\n";
      print STDERR "null list so that we don't disturb any current data.\n\n";
      $update_only = 1;
    }
  
  } # PASS_QUERY

  my %db_info = DbInfo($db,406);
  $tests_done{'DbInfo mode 406'} = 1;
  DbExplain unless $DbStatus[0] == 0;
  print STDERR "Successfully opened $db_info{name} mode $db_info{mode}.\n\n";

  # Check to see if this database can be used.
  @sets = DbInfo($db,203);
  DbExplain unless $DbStatus[0] == 0;
  $tests_done{'DbInfo mode 203'} = 1;
  @set_info = map { { DbInfo($db,205,$_) } } @sets;
  DbExplain unless $DbStatus[0] == 0;
  $tests_done{'DbInfo mode 205'} = 1;

  # Empty sets are of no use in any of our tests
  my @indicies = grep { $set_info[$_]->{entries} > 0 } (0..$#sets);
  @nonempty_sets = @sets[@indicies];
  @set_info = @set_info[@indicies];
  
  if ($test_write) {
    my @writeable_sets = weed_sets($db,grep { $_ < 0 } @sets);
      
    unless ($update_only or @writeable_sets) {
      my $answer = '';
      while ($answer !~ /^y/i and $answer !~ /^n/i and $answer ne '//') {
        print STDERR "There are no sets to which I can do a DbPut, shall I\n";
        print STDERR "test only the update capabilities? ";
        chomp($answer = <>);
        exit if $answer eq '//';
        print STDERR "\n";
      }
      if ($answer =~ /^n/i) {
        DbClose($db,1);
        print STDERR "Please enter a new password . . . \n\n";
        goto PASS_QUERY;
      } else {
        $update_only = 1;
      }
    }

    unless (@writeable_sets) {
      foreach (@nonempty_sets) {
        my @items = DbInfo($db,104,$_);
        DbExplain unless $DbStatus[0] == 0;
        if (grep { $_ < 0 } @items) {
          push(@writeable_sets,$_);
        }
      }

      @writeable_sets = weed_sets($db,@writeable_sets);
    }

    unless (@writeable_sets) {
      my $answer = '';
      while ($answer !~ /^y/i and $answer !~ /^n/i and $answer ne '//') {
        print STDERR "There are no sets to which I can do a DbUpdate, shall\n";
        print STDERR "I test only the read capabilities? ";
        chomp($answer = <>);
        exit if $answer eq '//';
        print STDERR "\n";
      }
      if ($answer =~ /^n/i) {
        DbClose($db,1);
        print STDERR "Please re-enter the database (// to exit)\n";
        redo DB_QUERY;
      } else {
        $test_write = '';
      }
    } else {
      $write_target = 
        dset_name($db,$writeable_sets[int(rand(@writeable_sets))]);
      print STDERR "I've chosen $write_target as the ";
      print STDERR 
        (($update_only) ? "DbUpdate " : "DbPut/DbUpdate/DbDelete\n");
      print STDERR "target dataset.\n\n";
    }
    
  }

  my @detail_sets = map { $_->{name} } grep { $_->{type} eq 'D' } @set_info;
  my @paths = map { [ DbInfo($db,301,$_) ] } @detail_sets;
  $tests_done{'DbInfo mode 301'} = 1;
  @indicies = grep { @{$paths[$_]} > 0 } (0..$#detail_sets);
  my @find_candidates = @detail_sets[@indicies];
  @paths = @paths[@indicies];
  foreach (@paths) {
    @{$_} = grep { 
      my %path = %{$_};
      my $set = abs($path{set}); 
      grep { abs($_) == $set } @nonempty_sets 
    } @{$_};
  }
  @find_candidates = @find_candidates[
    grep { @{$paths[$_]} > 0 } (0..$#find_candidates) 
  ];

  if (@find_candidates) {
    my $num = int(rand(@find_candidates));
    $find_target = dset_name($db,$find_candidates[$num]);
    $keyed_target = dset_name($db,$paths[$num][0]{'set'});
    $find_item = item_name($db,$paths[$num][0]{'search'});
    print STDERR "I've chosen to use $find_target and $keyed_target (which\n";
    print STDERR "are linked by $find_item) ";
    print STDERR "in testing DBFIND, and I'll use\n";
    print STDERR "$keyed_target for testing mode 7 of DBGET.\n\n";
  } else {
    print STDERR "I was unable to find a Detail/Master pair to use\n";
    print STDERR "in testing DBFIND.\n\n";

    # See if there is a master for which we can read the key
    my @master_sets = map { $_->{name} } grep { $_->{type} eq 'M' } @set_info;
    @master_sets = grep {
       my @items = map { abs($_) } DbInfo($db,104,$_);
       my $key = (DbInfo($db,302,$_))[0];
       grep { $_ == $key } @items;
    } @master_sets;

    if (@master_sets) {
      $keyed_target = dset_name($db,$master_sets[int(rand(@master_sets))]);

      print STDERR "I'll use $keyed_target to test mode 7 of DBGET.\n\n";
    } else {
      print STDERR "I couldn't find a master set to use for DBGET mode 7.\n\n";
    }
  }

} # DB_QUERY

ok(defined($db));
$tests_done{'DbOpen'} = 1;
print "# Done with DbOpen (should be test 4)\n";

my($mode2_target);
if ($find_target) {
  $mode2_target = $find_target;
} elsif ($keyed_target) {
  $mode2_target = $keyed_target;
} elsif ($write_target) {
  $mode2_target = $write_target;
} elsif (@nonempty_sets) {
  $mode2_target = $nonempty_sets[rand(@nonempty_sets)];
} else {
  die "There are no available sets on which to perform any tests.";
}

# We need to get the item list because using @; might not be safe.  If you 
# don't have read access to all the items in a dataset, @; will fail.

my @mode2_items = map { abs($_) } DbInfo($db,104,$mode2_target);
ok($DbStatus[0] == 0);
$tests_done{'DbInfo mode 104'} = 1;

my %rec1 = DbGet($db,2,$mode2_target,\@mode2_items);
DbExplain unless $DbStatus[0] == 0;
ok($DbStatus[0] == 0);
$tests_done{'DbGet mode 2'} = 1;
  
my $mode4_rec = ($DbStatus[2] << 16) | ($DbStatus[3] & 0xffff);
my %rec2 = DbGet($db,4,$mode2_target,undef,$mode4_rec);  # Uses same list
DbExplain unless $DbStatus[0] == 0;
ok($DbStatus[0] == 0);
ok(scalar(keys %rec1) == scalar(keys %rec2));
$tests_done{'DbGet mode 4'} = 1;

my $ok = 1;
MATCHECK: foreach (keys %rec1) {
  if ($rec1{$_} ne $rec2{$_}) {
    if (ref($rec1{$_}) eq ref($rec2{$_}) and
        ref($rec1{$_}) eq 'ARRAY') {
      if (@{$rec1{$_}} != @{$rec2{$_}}) {
        $ok = '';
        print "$_ is not an array member in both records\n";
        last MATCHECK;
      } else {
        foreach my $memb (0..$#{$rec1{$_}}) {
          if (${$rec1{$_}}[$memb] ne ${$rec2{$_}}[$memb]) {
            $ok = '';
            print "Difference in array member $memb of $_\n";
            last MATCHECK;
          }
        }
      }
    } else {
      $ok = '';
      print "Difference with item $_: $rec1{$_} vs. $rec2{$_}\n";
      last MATCHECK;
    }
  }
}
ok($ok);
print "# Nine done to this point.\n";

my %rec3;
if ($keyed_target) {
  # The way in which $keyed_target was picked implies that it is a master
  my $key_item = item_name($db,(DbInfo($db,302,$keyed_target))[0]);
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbInfo mode 302'} = 1;
  
  my @mode7_items = map { abs($_) } DbInfo($db,104,$keyed_target);
  @mode7_items = map { item_name($db,$_) } @mode7_items;

  %rec3 = DbGet($db,7,$keyed_target,join(', ',@mode7_items),$rec2{$key_item});
  DbExplain unless $DbStatus[0] == 0;
  ok($DbStatus[0] == 0);
  $tests_done{'DbGet mode 7'} = 1;
  ok($rec3{$key_item} eq $rec2{$key_item});
  %rec3 = DbGet($db,7,$keyed_target,undef,$rec2{$key_item});
  DbExplain unless $DbStatus[0] == 0;
  ok($DbStatus[0] == 0);
  $tests_done{'DbGet mode 7 with undef list'} = 1;
  ok($rec3{$key_item} eq $rec2{$key_item});
  %rec3 = DbGet($db,7,$keyed_target,$rec2{$key_item});
  DbExplain unless $DbStatus[0] == 0;
  ok($DbStatus[0] == 0);
  $tests_done{'DbGet mode 7 with no list'} = 1;
  ok($rec3{$key_item} eq $rec2{$key_item});

  if ($find_target) {
    DbFind($db,$find_target,$find_item,$rec3{$key_item});
    DbExplain unless $DbStatus[0] == 0;
    ok($DbStatus[0] == 0);
    $tests_done{'DbFind'} = 1;
   
    $DbStatus[0] = 0;
    my $mode5_rec = -1;
    until ($DbStatus[0] or $mode4_rec == $mode5_rec) {
      DbGet($db,5,$find_target,0);  # Don't get any fields, just record nums
      $mode5_rec = ($DbStatus[2] << 16) | ($DbStatus[3] & 0xffff);
    }
    DbExplain unless ($DbStatus[0] == 0);
    ok($mode4_rec == $mode5_rec);
    $tests_done{'DbGet mode 5'} = 1;
  } else {
    skip('Skipped: Find target not available','DbFind');
    skip('Skipped: Find target not available','DbGet mode 5');
  }
} else {
  skip('Skipped: Keyed target not available','DbInfo mode 302');
  skip('Skipped: Keyed target not available','DbGet mode 7');
  skip('Skipped: Keyed target not available','$rec3{$key_item} eq $rec2{$key_item}');
  skip('Skipped: Keyed target not available','DbGet mode 7 with undef list');
  skip('Skipped: Keyed target not available','$rec3{$key_item} eq $rec2{$key_item}');
  skip('Skipped: Keyed target not available','DbGet mode 7 with no list');
  skip('Skipped: Keyed target not available','$rec3{$key_item} eq $rec2{$key_item}');
  skip('Skipped: Keyed target not available','DbFind');
  skip('Skipped: Keyed target not available','DbGet mode 5');
}
print "# Another nine completed (making 18 total)\n";

# DbMemo test
DbMemo($db,'MPE::IMAGE Testing DbMemo');
DbExplain unless ($DbStatus[0] == 0);
ok($DbStatus[0] == 0);
$tests_done{'DbMemo'} = 1;

# Note: The DbBegin/DbEnd testing will be cleaned up once there is something
# to put between the begin and the end :-).

# Test DbBegin/DbEnd here as we will use the dynamic form later
DbBegin($db,1,'MPE::IMAGE Testing DbBegin mode 1');
DbExplain unless ($DbStatus[0] == 0);
ok($DbStatus[0] == 0);
$tests_done{'DbBegin mode 1'} = 1;
print "# Two more (that's 20 now)\n";

if ($test_write) {
  if ($update_only) {
    my %update_rec = DbGet($db,2,$write_target);
    DbExplain unless $DbStatus[0] == 0 or $DbStatus[0] == 11;

    if ($DbStatus[0] == 0) {
      if ($open_mode == 1) {
        print STDERR "Locking $write_target . . .\n";
        DbLock($db,3,$write_target);
        DbExplain unless ($DbStatus[0] == 0);
        ok($DbStatus[0] == 0);
        $tests_done{'DbLock mode 3'} = 1;
        print STDERR "Locked.\n";
      } else {
        skip('Skipped: database not open mode 1','DbLock');
      }

      DbUpdate($db,$write_target,'0;',''); # So as to not disturb any data
      DbExplain unless ($DbStatus[0] == 0);
      ok($DbStatus[0] == 0);
      $tests_done{'DbUpdate'} = 1;

      if ($open_mode == 1) {
        DbUnlock($db);
        DbExplain unless ($DbStatus[0] == 0);
        ok($DbStatus[0] == 0);
        $tests_done{'DbUnlock'} = 1;
      } else {
        skip('Skipped: database not open mode 1','DbUnlock');
      }

    } else {
      skip('Skipped: Could not get record to update','DbLock mode 3');
      skip('Skipped: Could not get record to update','DbUpdate');
      skip('Skipped: Could not get record to update','DbUnlock');
    }
    skip('Skipped: Only update-capable','DbLock mode 5');
    skip('Skipped: Only update-capable','DbPut');
    skip('Skipped: Only update-capable','DbDelete');
  } else { # test DbPut, DbUpdate and DbDelete

    my %setinfo = DbInfo($db,205,$write_target);

    # First find critical items:
    my $key_item = undef;
    if ($setinfo{'type'} eq 'M') {
      $key_item = (DbInfo($db,302,$write_target))[0];
    }

    # Now look for items which can be changed 
    my @set_items = map { abs($_) } DbInfo($db,104,$write_target);
    my @non_critical;
    if (defined($key_item)) {
      @non_critical = grep { $_ != $key_item } @set_items;
    } else { 
      @non_critical = @set_items;
    } 
    my @changeable = grep { DbInfo($db,101,$_) < 0 } @non_critical;
  
    $key_item = item_name($db,$key_item) if defined($key_item);

    my $update_item;
    if (defined($key_item) or @changeable) {
      if (@changeable) {
        $update_item = item_name($db,$changeable[rand(@changeable)]);
      }

      my %data;
      my $cnt = 0;
      if (defined($key_item)) {
        DbGet($db,7,$write_target,++$cnt);
        DbExplain unless $DbStatus[0] == 0 or $DbStatus[0] == 17;
        while ($DbStatus[0] == 0) {
          DbGet($db,7,$write_target,++$cnt);
          DbExplain unless $DbStatus[0] == 0 or $DbStatus[0] == 17;
        }
        $data{$key_item} = $cnt;
      }
      if (defined($update_item) and !exists($data{$update_item})) {
        $data{$update_item} = ++$cnt;
      }

      print STDERR "\n\nDbPutting the following record to $write_target:\n";
      foreach (sort keys %data) {
        print STDERR "$_: $data{$_}\n";
      }
      print STDERR "\n";

      if ($open_mode == 1) {
        print STDERR "Trying to lock $write_target . . .\n\n";

        DbLock($db,3,$write_target);
        DbExplain unless $DbStatus[0] == 0;
        ok($DbStatus[0] == 0);
        $tests_done{'DbLock mode 3'} = 1;
        print STDERR "\n\nLocked.\n\n" if $DbStatus[0] == 0;;
      } else {
        skip('Skipped: database not open mode 1','DbLock');
      }

      DbPut($db,$write_target,%data);
      DbExplain unless ($DbStatus[0] == 0);
      ok($DbStatus[0] == 0);
      $tests_done{'DbPut'} = 1;

      print STDERR "\n\nRecord created\n\n" if $DbStatus[0] == 0;

      if (defined($key_item)) {
        DbUnlock($db);
        DbExplain unless $DbStatus[0] == 0;
       
        DbLock($db,5, [ $write_target, "$key_item=$data{$key_item}" ]);
        DbExplain unless $DbStatus[0] == 0;
        ok($DbStatus[0] == 0);
        $tests_done{'DbLock mode 5'} = 1;
      } else {
        skip('Skipped: No key item available for lock','DbLock mode 5');
      }

      $update_item = '0' unless defined($update_item);
      DbUpdate($db,$write_target,{ $update_item => 0 }); # Change the value
      DbExplain unless ($DbStatus[0] == 0);
      ok($DbStatus[0] == 0);
      $tests_done{'DbUpdate'} = 1;

      print STDERR "\n\nRecord updated\n\n" if $DbStatus[0] == 0;

      if (defined($key_item)) {
        DbUnlock($db);
        DbExplain unless $DbStatus[0] == 0;
       
        DbLock($db,3,$write_target);
        DbExplain unless $DbStatus[0] == 0;
      }

      DbDelete($db,$write_target);
      DbExplain unless ($DbStatus[0] == 0);
      ok($DbStatus[0] == 0);
      $tests_done{'DbDelete'} = 1;

      print STDERR "\n\nRecord deleted.\n\n" if $DbStatus[0] == 0;

      if ($open_mode == 1) {
        DbUnlock($db);
        DbExplain unless ($DbStatus[0] == 0);
        ok($DbStatus[0] == 0);
        $tests_done{'DbUnlock'} = 1;
      } else {
        skip('Skipped: database not open mode 1','DbUnlock');
      }

    } else {
      print STDERR "Error: Could not find any critical or changeable items\n";
      ok(0) for (1..6);
    }
  }
} else {
  skip('Skipped: not testing write capabilities','DbLock mode 3');
  skip('Skipped: not testing write capabilities','DbLock mode 5');
  skip('Skipped: not testing write capabilities','DbPut');
  skip('Skipped: not testing write capabilities','DbUpdate');
  skip('Skipped: not testing write capabilities','DbDelete');
  skip('Skipped: not testing write capabilities','DbUnlock');
}
print "# Five more completed, giving 25 total.\n";

DbEnd($db,2,'MPE::IMAGE Testing DbEnd mode 2');
DbExplain unless ($DbStatus[0] == 0);
ok($DbStatus[0] == 0);
$tests_done{'DbEnd mode 2'} = 1;
print "# There's another.  We're up to 26.\n";
 
unless ($open_mode == 2) {
  DbXBegin($db,1,'MPE::IMAGE Testing DbXBegin mode 1');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbXBegin mode 1'} = 1;
  
  DbXEnd($db,1,'MPE::IMAGE Testing DbXEnd mode 1');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbXEnd mode 1'} = 1;
   
  DbXBegin($db,1,'MPE::IMAGE Testing DbXBegin mode 1');
  DbExplain unless ($DbStatus[0] == 0);
  
  DbXUndo($db,1,'MPE::IMAGE Testing DbXUndo mode 1');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbXUndo mode 1'} = 1;
} else {
  skip('Skipped: Db opened mode 2','DbXBegin mode 1');
  skip('Skipped: Db opened mode 2','DbXEnd mode 1');
  skip('Skipped: Db opened mode 2','DbXUndo mode 1');
}
print "# Three more makes 29.\n";

# Attempt to open the database again to test multiple-db form
my($db2,$multi_db);
if ($open_mode != 4) {
  $db2 = DbOpen($database,$pass,$open_mode);
  $multi_db = ($DbStatus[0] == 0);
} else {
  $multi_db = 0;
}

if ($multi_db) {
  DbBegin([$db,$db2],3,'MPE::IMAGE Testing DbBegin mode 3');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbBegin mode 3'} = 1;

  DbEnd([$db,$db2],3,'MPE::IMAGE Testing DbEnd mode 3');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbEnd mode 3'} = 1;

  my $transid = DbBegin([$db,$db2],4,'MPE::IMAGE Testing DbBegin mode 4');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbBegin mode 4'} = 1;

  DbEnd($transid,4,'MPE::IMAGE Testing DbEnd mode 4');
  DbExplain unless ($DbStatus[0] == 0);
  ok($DbStatus[0] == 0);
  $tests_done{'DbEnd mode 4'} = 1;

  unless ($open_mode == 2) {
    DbControl($db,7);
    DbExplain unless ($DbStatus[0] == 0);
    ok($DbStatus[0] == 0);
    $tests_done{'DbControl mode 7'} = 1;
  
    DbControl($db2,7);
    DbExplain unless ($DbStatus[0] == 0);
  
    $transid = DbXBegin([$db,$db2],3,'MPE::IMAGE Testing DbXBegin mode 3');
    DbExplain unless ($DbStatus[0] == 0);
    ok($DbStatus[0] == 0);
    $tests_done{'DbXBegin mode 3'} = 1;
  
    DbXEnd($transid,3,'MPE::IMAGE Testing DbXEnd mode 3');
    DbExplain unless ($DbStatus[0] == 0);
    ok($DbStatus[0] == 0);
    $tests_done{'DbXEnd mode 3'} = 1;
  
    $transid = DbXBegin([$db,$db2],3,'MPE::IMAGE Testing DbXBegin mode 3');
    DbExplain unless ($DbStatus[0] == 0);
  
    DbXUndo($transid,3,'MPE::IMAGE Testing DbXUndo mode 3');
    DbExplain unless ($DbStatus[0] == 0);
    ok($DbStatus[0] == 0);
    $tests_done{'DbXUndo mode 3'} = 1;
  } else {
    skip('Skipped: Db opened mode 2','DbControl mode 7');
    skip('Skipped: Db opened mode 2','DbXBegin mode 3');
    skip('Skipped: Db opened mode 2','DbXEnd mode 3');
    skip('Skipped: Db opened mode 2','DbXUndo mode 3');
  }
} else {
  skip('Skipped: Could not open db a second time','DbBegin mode 3');
  skip('Skipped: Could not open db a second time','DbEnd mode 3');
  skip('Skipped: Could not open db a second time','DbBegin mode 4');
  skip('Skipped: Could not open db a second time','DbEnd mode 4');
  skip('Skipped: Could not open db a second time','DbControl mode 7');
  skip('Skipped: Could not open db a second time','DbXBegin mode 3');
  skip('Skipped: Could not open db a second time','DbXEnd mode 3');
  skip('Skipped: Could not open db a second time','DbXUndo mode 3');
}
print "# And another eight gives 37.\n";

# Close the base
DbClose($db,1);
DbExplain unless ($DbStatus[0] == 0);
ok($DbStatus[0] == 0);
$tests_done{'DbClose'} = 1;
print "# That's the last.  I count 38 in all.\n";

print STDERR "\n\nTests performed:\n",join("\n",sort keys %tests_done),"\n\n";
