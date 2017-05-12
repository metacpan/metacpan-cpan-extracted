#!perl

use strict;
use Test::More;
use Test::Exception;
use MMapDB qw/:all/;
use Fcntl qw/:flock/;

my @fmts=('', undef, qw/L N J/);
eval {my $x=pack 'Q', 0; push @fmts, 'Q'};
#my @fmts=('');
plan tests=>167*@fmts;
#plan 'no_plan';
#use Data::Dumper; $Data::Dumper::Useqq=1;

sub note; *note=sub {
  print '# '.join('', @_)."\n";
} unless defined &note;

sub doone {
  my ($fmt)=@_;
  my $rfmt=$fmt||'N';

  print "# TESTING FORMAT $rfmt\n";

  unlink 'tmpdb';			# make sure
  unlink 'tmpdb.lock';			# make sure
  die "Please move tmpdb out of the way!\n" if -e 'tmpdb';

  my %positions;

  my $d=MMapDB->new(filename=>"tmpdb", intfmt=>$fmt);
  my $r=MMapDB->new(filename=>"tmpdb", readonly=>1);

  isa_ok $d, 'MMapDB', '$d is a MMapDB';
  isa_ok $r, 'MMapDB', '$r is a MMapDB';

  is $d->intfmt, $rfmt, 'format is '.$rfmt;

  $d->start;
  {
    no warnings 'uninitialized';
    my @l=$d->index_lookup($d->mainidx, qw/key0 1 2 3/);
    is scalar @l, 0, 'key0: not found (initial db)';
    @l=$d->index_lookup;
    is scalar @l, 0, 'index_lookup without params (initial db)'; 
    @l=$d->index_lookup($d->mainidx);
    is scalar @l, 0, 'index_lookup 1 param (initial db)';
  }
  $r->start;

  lives_ok {$d->begin} 'started transaction';
  ok !-f 'tmpdb.lock', 'lockfile does not exist yet';
  throws_ok {$r->begin} qr/SCALAR/, 'readonly';
  is $@, E_READONLY, 'E_READONLY';
  cmp_ok ${$@}, 'eq', 'database is read-only', '${E_READONLY()}';

  ##########################################################################
  # insert a few things
  ##########################################################################

  my ($id, $pos);
  lives_ok {($id, $pos)=$d->insert(['key1', 'sort1', 'data1'])} 'insert1';

  is $id, 1, "got ID 1 at position $pos";

  lives_ok {($id, $pos)=$d->insert([['key1'], 'sort2', 'data2'])} 'insert2';
  lives_ok {($id, $pos)=$d->insert([['key1', 'key2'],'sort3','data3'])}
    'insert3';

  ##########################################################################
  # ok, that last insert made the transaction uncommitable
  ##########################################################################

  throws_ok {$d->commit} qr/SCALAR/, 'duplicate';
  is $@, E_DUPLICATE, 'E_DUPLICATE';

  ##########################################################################
  # insert without transaction is forbidden
  ##########################################################################

  throws_ok {($id, $pos)=$d->insert(['key1', 'sort1', 'data1'])} qr/SCALAR/,
    'transaction';
  is $@, E_TRANSACTION, 'E_TRANSACTION';

  ##########################################################################
  # lets start anew
  ##########################################################################

  $d->lockfile=$d->filename.'.lock';
  lives_ok {$d->begin} 'started transaction';
  ok -f 'tmpdb.lock', 'lockfile has been created';
  ok !do {my $fh; open $fh, '>tmpdb.lock' and flock($fh, LOCK_SH|LOCK_NB)},
    'and is exclusively locked';
  lives_ok {($id, $pos)=$d->insert(['key1', 'sort1', 'data1'])} 'insert1';
  $positions{$id}=$pos;

  is $id, 1, "got ID 1 at position $pos";

  lives_ok {($id, $pos)=$d->insert([['key1'], 'sort2', 'data2'])} 'insert2';
  $positions{$id}=$pos;
  lives_ok {($id, $pos)=$d->insert([['key2', 'key2'],'sort2','data2'])}
    'insert3';
  $positions{$id}=$pos;

  is $d->is_valid, undef, 'database is still not valid';
  lives_ok {$d->commit} 'transaction committed';
  is $d->is_valid, 1, 'database is now valid';

  ##########################################################################
  # read it back via ID index iterator
  ##########################################################################

  my $dataend=$d->mainidx;
  my ($it, $nitems);

  $it=$d->id_index_iterator;
  is ref($it), 'MMapDB::Iterator', 'got id index iterator';
  my %h;
  my $n=0;
  while( my @el=$it->() ) {
    is $positions{$el[0]}, $el[1], 'correct element position';
    cmp_ok $el[1], '<', $dataend, "position is lower than dataend ($dataend)";
    is $d->is_datapos($el[1]), 1, "is_datapos() agrees";
    $n++;
  }
  is $n, scalar keys %positions, "got as many elements as inserted";

  (undef, $nitems)=$d->id_index_iterator;
  is $nitems, $n, "nitems returned by id_index_iterator ($n)";

  is $it->nelem, $n, "id_index_iterator->nelem()=$n";

  is $it->cur, $n, "id_index_iterator->cur()=$n";

  $it->nth(1);			# VOID context
  is $it->cur, 1, "id_index_iterator->cur() reset to 1";
  $n=0;
  $n++ while($it->());
  is $n, scalar(keys %positions)-1, "id_index_iterator after repositioning";

  {
    my @el=$it->nth(1);
    is $positions{$el[0]}, $el[1], 'correct element position';
    is $it->cur, 2, "id_index_iterator->cur() after nth(1) in list context";
  }

  throws_ok {$it->nth(15)} qr/SCALAR/, 'moving iterator out of range';
  is $@, E_RANGE, 'E_RANGE';

  throws_ok {$it->nth(-1)} qr/SCALAR/, 'moving iterator out of range';
  is $@, E_RANGE, 'E_RANGE';

  ##########################################################################
  # test main index iterator
  ##########################################################################

  $it=$d->index_iterator($d->mainidx);
  is ref($it), 'MMapDB::Iterator', 'got main index iterator';
  $n=0;
  %h=(); undef @h{qw/key1 key2/};
  my @datapos=(1, '');		# key1: is datapos, key2: is not
  while( my @el=$it->() ) {
    delete $h{$el[0]};
    is $d->is_datapos($el[1]), shift(@datapos), "is_datapos()";
    $n++;
  }
  is $n, 2, 'got 2 elements';
  is scalar keys %h, 0, 'with correct keys';

  (undef, $nitems)=$d->index_iterator($d->mainidx);
  is $nitems, 2, 'nitems returned by index_iterator';

  is $it->nelem, 2, "index_iterator->nelem()=$n";

  is $it->cur, 2, "index_iterator->cur()=$n";

  $it->nth(1);			# VOID context
  is $it->cur, 1, "index_iterator->cur() reset to 1";
  $n=0;
  $n++ while($it->());
  is $n, 1, "index_iterator after repositioning";

  {
    my @el=$it->nth(1);
    is $el[0], "key2", 'correct element position';
    is $it->cur, 2, "index_iterator->cur() after nth(1) in list context";
  }

  throws_ok {$it->nth(15)} qr/SCALAR/, 'moving iterator out of range';
  is $@, E_RANGE, 'E_RANGE';

  throws_ok {$it->nth(-1)} qr/SCALAR/, 'moving iterator out of range';
  is $@, E_RANGE, 'E_RANGE';

  ##########################################################################
  # test index lookup
  ##########################################################################

  {
    my @l=$d->index_lookup;
    is scalar @l, 0, 'index_lookup without params';
    @l=$d->index_lookup($d->mainidx);
    is scalar @l, 0, 'index_lookup 1 param';
    @l=$d->index_lookup($d->mainidx, qw/key0 1 2 3/);
    is scalar @l, 0, 'key0 1 2 3: not found';
    @l=$d->index_lookup($d->mainidx, qw/key0/);
    is scalar @l, 0, 'key0: not found';
    @l=$d->index_lookup($d->mainidx, 'key11');
    is scalar @l, 0, 'key11: not found';
    @l=$d->index_lookup($d->mainidx, 'key3');
    is scalar @l, 0, 'key3: not found';
  }

  my @el=$d->index_lookup(0, 'key1');
  is scalar @el, 2, 'key1: 2 positions';
  cmp_ok $el[0], '<', $dataend, '0th pos < dataend';
  cmp_ok $el[1], '<', $dataend, '1st pos < dataend';

  is_deeply( $d->data_record($el[0]),
	     [['key1'], 'sort1', 'data1',
	      (grep {$_->[1]==$el[0]} map {[$_, $positions{$_}]}
	       keys %positions)[0]->[0]],
	     'fetch 1st data record' );
  is $d->data_value($el[0]), 'data1', 'fetch 1st data value';
  is $d->data_sort($el[0]), 'sort1', 'fetch 1st sort value';
  is_deeply( $d->data_record($el[1]),
	     [['key1'], 'sort2', 'data2',
	      (grep {$_->[1]==$el[1]} map {[$_, $positions{$_}]}
	       keys %positions)[0]->[0]],
	     'fetch 2nd data record' );
  is $d->data_value($el[1]), 'data2', 'fetch 2nd data value';
  is $d->data_sort($el[1]), 'sort2', 'fetch 2nd sort value';

  is_deeply( [$d->data_record(@el)],
	     [
	      [['key1'], 'sort1', 'data1',
	       (grep {$_->[1]==$el[0]} map {[$_, $positions{$_}]}
		keys %positions)[0]->[0]],
	      [['key1'], 'sort2', 'data2',
	       (grep {$_->[1]==$el[1]} map {[$_, $positions{$_}]}
		keys %positions)[0]->[0]],
	     ], 'data_record( @POS )' );
  is_deeply( [$d->data_value(@el)], [qw/data1 data2/], 'data_value( @POS )' );
  is_deeply( [$d->data_sort(@el)], [qw/sort1 sort2/], 'data_sort( @POS )' );

  is_deeply( [$d->index_lookup_records(0, 'key1')],
	     [
	      [['key1'], 'sort1', 'data1',
	       (grep {$_->[1]==$el[0]} map {[$_, $positions{$_}]}
		keys %positions)[0]->[0]],
	      [['key1'], 'sort2', 'data2',
	       (grep {$_->[1]==$el[1]} map {[$_, $positions{$_}]}
		keys %positions)[0]->[0]],
	     ], 'index_lookup_records' );
  is_deeply( [$d->index_lookup_records(0, 'non-existent')], [],
	     'index_lookup_records (non-existent)');
  is_deeply( [$d->index_lookup_records(0, 'key2')], [],
	     'index_lookup_records (index)');

  is_deeply( [$d->index_lookup_values(0, 'key1')], [qw/data1 data2/],
	     'index_lookup_values' );
  is_deeply( [$d->index_lookup_values(0, 'non-existent')], [],
	     'index_lookup_values (non-existent)');
  is_deeply( [$d->index_lookup_values(0, 'key2')], [],
	     'index_lookup_values (index)');

  is_deeply( [$d->index_lookup_sorts(0, 'key1')], [qw/sort1 sort2/],
	     'index_lookup_sorts' );
  is_deeply( [$d->index_lookup_sorts(0, 'non-existent')], [],
	     'index_lookup_sorts (non-existent)');
  is_deeply( [$d->index_lookup_sorts(0, 'key2')], [],
	     'index_lookup_sorts (index)');

  @el=$d->index_lookup($d->mainidx, 'key2');
  is scalar @el, 1, 'key1: 1 positions';
  cmp_ok $el[0], '>=', $dataend, '0th pos >= dataend';

  ##########################################################################
  # test index_lookup_position
  ##########################################################################

  note "test index_lookup_position";

  #use Data::Dumper; $Data::Dumper::Useqq=1;
  #$d->datamode=DATAMODE_SIMPLE;
  #note Dumper $d->main_index;

  is_deeply [$d->index_lookup_position($d->mainidx, 'key1')],
    [$d->mainidx, 0], 'nth=0';
  is_deeply [$d->index_lookup_position($d->mainidx, 'key11')],
    [$d->mainidx, 1], 'nth=1';
  is_deeply [$d->index_lookup_position($d->mainidx, 'key2')],
    [$d->mainidx, 1], 'nth=1';
  is_deeply [$d->index_lookup_position($d->mainidx, 'key22')],
    [$d->mainidx, 2], 'nth=2';

  is_deeply [$d->index_lookup_position($d->mainidx, 'key1', 'not found')],
    [], 'not found';
  is_deeply [$d->index_lookup_position($d->mainidx, 'not found', 'not found')],
    [], 'not found';

  is_deeply [$d->index_lookup_position($d->mainidx, 'key2', 'key2')],
    [($d->index_lookup($d->mainidx, 'key2'))[0], 0], 'key2 key2';
  is_deeply [$d->index_lookup_position($d->mainidx, 'key2', 'key21')],
    [($d->index_lookup($d->mainidx, 'key2'))[0], 1], 'key2 key21';

  is_deeply [$d->index_lookup_position($d->mainidx, 'key2', 'key2', '...')],
    [], 'key2 key2 not_found';
  is_deeply [$d->index_lookup_position($d->mainidx, 'key2', 'key21', '...')],
    [], 'key2 key21 not_found';

  ##########################################################################
  # test tie interface
  ##########################################################################

  is join( ':', keys %{$d->main_index} ), 'key1:key2', 'keys %main_index';
  is join( ':', keys %{$d->id_index} ), '1:2:3', 'keys %id_index';

  is scalar %{$d->main_index}, '2/2', 'scalar %main_index';
  is scalar %{$d->id_index}, '3/3', 'scalar %id_index';

  is ref($d->id_index->{1}), 'ARRAY', '$d->id_index->{1} is an ARRAY';
  is ref(tied @{$d->id_index->{1}}), '', '$d->id_index->{1} is not tied';

  is ref($d->main_index->{key1}), 'ARRAY', '$d->main_index->{key1} is an ARRAY';
  is ref(tied @{$d->main_index->{key1}}), 'MMapDB::Data',
    '$d->main_index->{key1} tied';

  is ref($d->main_index->{key2}), 'HASH', '$d->main_index->{key2} is a HASH';
  is ref(tied %{$d->main_index->{key2}}), 'MMapDB::Index',
    '$d->main_index->{key2} tied';

  is ref($d->main_index->{key2}->{key2}), 'ARRAY',
    '$d->main_index->{key2}->{key2} is an ARRAY';
  is ref(tied @{$d->main_index->{key2}->{key2}}), 'MMapDB::Data',
    '$d->main_index->{key2}->{key2} tied';

  ok exists($d->main_index->{key2}->{key2}),
    'exists $d->main_index->{key2}->{key2}';
  ok !exists($d->main_index->{key2}->{key3}),
    '!exists $d->main_index->{key2}->{key3}';
  ok !exists($d->main_index->{key2}->{key1}),
    '!exists $d->main_index->{key2}->{key1}';

  is_deeply( $d->id_index->{3},
	     [['key2', 'key2'],'sort2','data2', 3],
	     'fetch 3rd data record' );
  is scalar @{$d->main_index->{key1}}, 2, '2==@{$d->main_index->{key1}}';

  eval {$d->main_index->{huhu}=1};
  like $@, qr/Modification of a read-only value attempted at/,
    'MMapDB::Index is read-only';

  eval {$d->main_index->{key1}->[3]=1};
  like $@, qr/Modification of a read-only value attempted at/,
    'MMapDB::Data is read-only';

  {
    $d->datamode=DATAMODE_SIMPLE;
    map {
      # note explain $_;
      local $_=42;              # this is also a write access
      # note explain $_;
      is_deeply $_, 42, 'map {local $_} values %{$d->main_index}';
    } (values(%{$d->main_index}),
       @{$d->main_index->{key1}},
       $d->main_index->{key1}->[0],
       values(%{$d->id_index}));
    $d->datamode=DATAMODE_NORMAL;
  }

  ##########################################################################
  # test update
  ##########################################################################

  is $r->main_index, undef, 'uninitialized $r->main_index';

  is $r->is_valid, undef, '$r is still not valid';
  $r->start;
  is $r->is_valid, 1, '$r is now valid';
  is scalar @{$r->main_index->{key1}}, 2, '2==@{$r->main_index->{key1}}';

  {
    $d->backup;
    ok -f('tmpdb.BACKUP'), 'tmpdb.BACKUP exists';
    my $backup=MMapDB->new(filename=>'tmpdb.BACKUP');
    isa_ok $backup, 'MMapDB', '$backup is a MMapDB';
    isa_ok $backup->start, 'MMapDB', 'starts OK';
    is $backup->is_valid, 1, 'and is valid';
    is exists $backup->main_index->{key2}, 1, '$backup: exists key2}';
    $backup->begin;
    $backup->delete_by_id(3);
    $backup->commit;
    is exists $backup->main_index->{key2}, '', '$backup: !exists key2}';
    is exists $d->main_index->{key2}, 1, '$d: exists key2}';
    $d->restore;
    ok !-f('tmpdb.BACKUP'), 'tmpdb.BACKUP vanished';
    is exists $d->main_index->{key2}, '', '$: !exists key2} after restore';
  }

  $d->begin;
  {
    my $backup=$d->new(filename=>'newdb'); # clone
    isa_ok $backup, 'MMapDB', '$backup is a MMapDB';
    $backup->begin;
    $backup->commit(1);
    ok -f('newdb'), 'newdb exists';
    $backup->stop;
    $backup=MMapDB->new(filename=>'newdb');
    ok $backup->start, 'backup connected';
    $backup->begin;
    is $backup->delete_by_id(1), 1, 'deleted id 1 (backup)';
    $backup->commit;
    unlink 'newdb';
  }

  is $d->delete_by_id(1), 1, 'deleted id 1';
  $d->commit;

  is scalar @{$d->main_index->{key1}}, 1, '1==@{$d->main_index->{key1}}';
  is scalar @{$r->main_index->{key1}}, 2, '2==@{$r->main_index->{key1}}';

  $r->start;
  is scalar @{$r->main_index->{key1}}, 1, '1==@{$r->main_index->{key1}}';

  $d->begin;
  is $d->delete_by_id(1), undef, 'try to delete id 1 again';
  is_deeply $d->delete_by_id(2,1), [['key1'], 'sort2', 'data2', 2],
    'say goodbye to element 2';
  is $d->clear, undef, 'clear DB';
  $d->commit;

  $r->start;
  is exists $r->main_index->{key1}, '', '!exists $r->main_index->{key1}';

  ##########################################################################
  # test ID overlow
  ##########################################################################

  $d->begin;

  ($id, $pos)=$d->insert([['key1'], 'sort2', 'data2']);
  is $id, 4, 'nextid is 4';

  my $maxid_minus_1=(unpack( $rfmt, pack $rfmt, -1 )>>1)-1;
  printf "# maxid_minus_1=%#x\n", $maxid_minus_1;
  $d->_nextid=$maxid_minus_1;

  ($id, $pos)=$d->insert([['key1'], 'sort1', 'data3']);
  is $id, $maxid_minus_1, 'nextid is '.$maxid_minus_1;

  ($id, $pos)=$d->insert([['key1'], 'sort9', 'data4']);
  is $id, $maxid_minus_1+1, 'nextid is '.($maxid_minus_1+1);

  ($id, $pos)=$d->insert([['key1'], 'sort4', 'data5']);
  is $id, 1, 'nextid is 1 after overflow';

  ($id, $pos)=$d->insert([['key1'], 'sort5', 'data6']);
  is $id, 2, 'nextid is 2 after overflow';

  ($id, $pos)=$d->insert([['key1'], 'sort7', 'data7']);
  is $id, 3, 'nextid is 3 after overflow';

  ($id, $pos)=$d->insert([['key1'], 'sort6', 'data8']);
  is $id, 5, 'nextid is 5 after overflow -- skipping 4';

  $d->commit;

  $r->start;

  is_deeply( $r->main_index,
	     {
	      "key1" => [[["key1"], "sort1", "data3", $maxid_minus_1],
			 [["key1"], "sort2", "data2", 4],
			 [["key1"], "sort4", "data5", 1],
			 [["key1"], "sort5", "data6", 2],
			 [["key1"], "sort6", "data8", 5],
			 [["key1"], "sort7", "data7", 3],
			 [["key1"], "sort9", "data4", $maxid_minus_1+1]]
	     },
	     '$r->main_index' );

  tied(%{$r->main_index})->datamode=DATAMODE_SIMPLE;
  is_deeply( $r->main_index,
	     {
	      "key1" => ["data3",
			 "data2",
			 "data5",
			 "data6",
			 "data8",
			 "data7",
			 "data4",],
	     },
	     '$r->main_index (DATAMODE_SIMPLE)' );
}

for my $fmt (@fmts) {
  doone $fmt;
}
