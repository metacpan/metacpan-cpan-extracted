#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use MMapDB qw/:error/;
use utf8;
use Encode qw/is_utf8/;

sub enc($); *enc=\&Encode::encode_utf8;

sub note; *note=sub {
  print '# '.join('', @_)."\n";
} unless defined &note;

plan tests=>102;
#plan 'no_plan';
#use Data::Dumper; $Data::Dumper::Useqq=1;

unlink 'tmpdb';			# make sure
unlink 'tmpdb.lock';		# make sure
die "Please move tmpdb out of the way!\n" if -e 'tmpdb';

my (@pos, $got, $expected);

my $d=MMapDB->new(filename=>"tmpdb");

my @key1=("Äpfel", 'für', 'Opi');
my @key1e=map {enc $_} @key1;
my @val1=('груши для ксении', 'Birnen für Xenia');
my @val1e=map {enc $_} @val1;

my @key2=("Äpfel", 'für', 'Bärbel');
my @key2e=map {enc $_} @key2;
my @val2=('Birnen für Xenia');
my @val2e=map {enc $_} @val2;

$d->start;
$d->begin();
my $sort="AAAA";
foreach my $v (@val1) {
  $d->insert([\@key1, $sort++, $v]);
}
foreach my $v (@val2) {
  $d->insert([\@key2, $sort++, $v]);
}
foreach my $v (@val1e) {
  $d->insert([\@key1e, $sort++, $v]);
}
foreach my $v (@val2e) {
  $d->insert([\@key2e, $sort++, $v]);
}
is $d->dbformat_out, 1, 'dbformat_out is 1';
$d->commit;
$d->stop;

$d->start;

####### Checking key1 ##############################################
note "Checking key1 (utf8)";

@pos=$d->index_lookup($d->mainidx, @key1);
is scalar @pos, 2, 'got 2 records';
ok $d->is_datapos($pos[0]), 'pos[0] is data';
ok $d->is_datapos($pos[1]), 'pos[1] is data';

# read 1st data record

$got=$d->data_record($pos[0]); pop @$got; # ignore IDs
$expected=[[qw/Äpfel für Opi/], "AAAA", "груши для ксении"];
is_deeply $got, $expected, 'data_record[0]';

# check utf8 flags

$expected=[1,1,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[0]: utf8 flags in key';

$expected=[0,1];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[0]: utf8 flags in sort and data';

# read 2nd data record

$got=$d->data_record($pos[1]); pop @$got; # ignore IDs
$expected=[[qw/Äpfel für Opi/], "AAAB", "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[1]';

$expected=[1,1,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[1]: utf8 flags in key';

$expected=[0,1];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[1]: utf8 flags in sort and data';

####### Checking key1e ##############################################
note "Checking key1e (non utf8)";

@pos=$d->index_lookup($d->mainidx, @key1e);
is scalar @pos, 2, 'got 2 records';
ok $d->is_datapos($pos[0]), 'pos[0] is data';
ok $d->is_datapos($pos[1]), 'pos[1] is data';

# read 1st data record

$got=$d->data_record($pos[0]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/],
	   "AAAD", enc("груши для ксении")];
is_deeply $got, $expected, 'data_record[0]';

# check utf8 flags

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[0]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[0]: utf8 flags in sort and data';

# read 2nd data record

$got=$d->data_record($pos[1]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/],
	   "AAAE", enc("Birnen für Xenia")];
is_deeply $got, $expected, 'data_record[1]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[1]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[1]: utf8 flags in sort and data';

####### Partkey lookup (utf8) #######################################
note "Checking partkey lookup and iterator (utf8)";

@pos=$d->index_lookup($d->mainidx, qw/Äpfel für/);
is scalar @pos, 1, 'got 1 record';
ok !$d->is_datapos($pos[0]), 'pos[0] is index';

my ($it, $nitems)=$d->index_iterator($pos[0]);
is $nitems, 2, 'index contains 2 items';

$expected=[['Bärbel', $d->index_lookup($d->mainidx, @key2)],
	   ['Opi', $d->index_lookup($d->mainidx, @key1)],
	  ];
for( my $i=0; (my $partkey, @pos)=$it->(); $i++ ) {
  is_deeply [$partkey, @pos], $expected->[$i], "index[$i]: @{$expected->[$i]}"
}

####### Partkey lookup (non utf8) ###################################
note "Checking partkey lookup and iterator (non utf8)";

@pos=$d->index_lookup($d->mainidx, map {enc $_} qw/Äpfel für/);
is scalar @pos, 1, 'got 1 record';
ok !$d->is_datapos($pos[0]), 'pos[0] is index';

($it, $nitems)=$d->index_iterator($pos[0]);
is $nitems, 2, 'index contains 2 items';

$expected=[[enc('Bärbel'), $d->index_lookup($d->mainidx, @key2e)],
	   [enc('Opi'), $d->index_lookup($d->mainidx, @key1e)],
	  ];
for( my $i=0; (my $partkey, @pos)=$it->(); $i++ ) {
  is_deeply [$partkey, @pos], $expected->[$i], "index[$i]: @{$expected->[$i]}"
}

$d->stop;

####### Write DBFMT0 format #########################################
note "Using DBFMT0";

$d->start;
$d->begin(0);         # convert to format 0
is $d->dbformat_in, 1, 'dbformat_in is 1';
is $d->dbformat_out, 0, 'dbformat_out is 0';
$d->commit;
$d->stop;

$d->start;

####### Checking key1 ##############################################
note "Checking key1 (utf8)";

@pos=$d->index_lookup($d->mainidx, @key1);
is scalar @pos, 4, 'got 2 records';
ok $d->is_datapos($pos[0]), 'pos[0] is data';
ok $d->is_datapos($pos[1]), 'pos[1] is data';
ok $d->is_datapos($pos[2]), 'pos[2] is data';
ok $d->is_datapos($pos[3]), 'pos[3] is data';

# read 1st data record

$got=$d->data_record($pos[0]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAA", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[0]';

# check utf8 flags

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[0]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[0]: utf8 flags in sort and data';

# read 2nd data record

$got=$d->data_record($pos[1]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAB", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[1]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[1]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[1]: utf8 flags in sort and data';

# read 3rd data record

$got=$d->data_record($pos[2]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAD", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[2]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[2]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[2]: utf8 flags in sort and data';

# read 4th data record

$got=$d->data_record($pos[3]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAE", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[3]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[3]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[3]: utf8 flags in sort and data';

####### Checking key1e ##############################################
note "Checking key1e (non utf8)";

@pos=$d->index_lookup($d->mainidx, @key1e);
is scalar @pos, 4, 'got 2 records';
ok $d->is_datapos($pos[0]), 'pos[0] is data';
ok $d->is_datapos($pos[1]), 'pos[1] is data';
ok $d->is_datapos($pos[2]), 'pos[2] is data';
ok $d->is_datapos($pos[3]), 'pos[3] is data';

# read 1st data record

$got=$d->data_record($pos[0]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAA", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[0]';

# check utf8 flags

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[0]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[0]: utf8 flags in sort and data';

# read 2nd data record

$got=$d->data_record($pos[1]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAB", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[1]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[1]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[1]: utf8 flags in sort and data';

# read 3rd data record

$got=$d->data_record($pos[2]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAD", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[2]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[2]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[2]: utf8 flags in sort and data';

# read 4th data record

$got=$d->data_record($pos[3]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAE", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[3]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[3]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[3]: utf8 flags in sort and data';

####### Partkey lookup (utf8) #######################################
note "Checking partkey lookup and iterator (utf8)";

@pos=$d->index_lookup($d->mainidx, qw/Äpfel für/);
is scalar @pos, 1, 'got 1 record';
ok !$d->is_datapos($pos[0]), 'pos[0] is index';

($it, $nitems)=$d->index_iterator($pos[0]);
is $nitems, 2, 'index contains 2 items';

$expected=[[enc 'Bärbel', $d->index_lookup($d->mainidx, @key2)],
	   [enc 'Opi', $d->index_lookup($d->mainidx, @key1)],
	  ];
for( my $i=0; (my $partkey, @pos)=$it->(); $i++ ) {
  is_deeply [$partkey, @pos], $expected->[$i], "index[$i]: @{$expected->[$i]}"
}

####### Partkey lookup (non utf8) ###################################
note "Checking partkey lookup and iterator (non utf8)";

@pos=$d->index_lookup($d->mainidx, map {enc $_} qw/Äpfel für/);
is scalar @pos, 1, 'got 1 record';
ok !$d->is_datapos($pos[0]), 'pos[0] is index';

($it, $nitems)=$d->index_iterator($pos[0]);
is $nitems, 2, 'index contains 2 items';

$expected=[[enc 'Bärbel', $d->index_lookup($d->mainidx, @key2e)],
	   [enc 'Opi', $d->index_lookup($d->mainidx, @key1e)],
	  ];
for( my $i=0; (my $partkey, @pos)=$it->(); $i++ ) {
  is_deeply [$partkey, @pos], $expected->[$i], "index[$i]: @{$expected->[$i]}"
}

$d->stop;

####### Write newest format #########################################
note "Using newest format";

$d->start;
$d->flags=0x403;
$d->begin(-1);         # convert to newest format
is $d->dbformat_in, 0, 'dbformat_in is 0';
is $d->dbformat_out, 1, 'dbformat_out is 1';
$d->commit;
$d->stop;

$d->start;

is $d->flags, 0x3, 'flags in format 1';

####### Checking key1 ##############################################
note "Checking key1 (utf8)";

@pos=$d->index_lookup($d->mainidx, @key1);
is scalar @pos, 0, 'got 0 records -- key is utf8';

####### Checking key1e ##############################################
note "Checking key1e (non utf8)";

@pos=$d->index_lookup($d->mainidx, @key1e);
is scalar @pos, 4, 'got 2 records';
ok $d->is_datapos($pos[0]), 'pos[0] is data';
ok $d->is_datapos($pos[1]), 'pos[1] is data';
ok $d->is_datapos($pos[2]), 'pos[2] is data';
ok $d->is_datapos($pos[3]), 'pos[3] is data';

# read 1st data record

$got=$d->data_record($pos[0]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAA", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[0]';

# check utf8 flags

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[0]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[0]: utf8 flags in sort and data';

# read 2nd data record

$got=$d->data_record($pos[1]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAB", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[1]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[1]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[1]: utf8 flags in sort and data';

# read 3rd data record

$got=$d->data_record($pos[2]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAD", enc "груши для ксении"];
is_deeply $got, $expected, 'data_record[2]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[2]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[2]: utf8 flags in sort and data';

# read 4th data record

$got=$d->data_record($pos[3]); pop @$got; # ignore IDs
$expected=[[map {enc $_} qw/Äpfel für Opi/], "AAAE", enc "Birnen für Xenia"];
is_deeply $got, $expected, 'data_record[3]';

$expected=[0,0,0];
is_deeply [map {is_utf8($_)?1:0} @{$got->[0]}],
          $expected, 'data_record[3]: utf8 flags in key';

$expected=[0,0];
is_deeply [map {is_utf8($_)?1:0} @$got[1,2]],
          $expected, 'data_record[3]: utf8 flags in sort and data';

####### Partkey lookup (utf8) #######################################
note "Checking partkey lookup and iterator (utf8)";

@pos=$d->index_lookup($d->mainidx, qw/Äpfel für/);
is scalar @pos, 0, 'got 0 record -- key is utf8';

####### Partkey lookup (non utf8) ###################################
note "Checking partkey lookup and iterator (non utf8)";

@pos=$d->index_lookup($d->mainidx, map {enc $_} qw/Äpfel für/);
is scalar @pos, 1, 'got 1 record';
ok !$d->is_datapos($pos[0]), 'pos[0] is index';

($it, $nitems)=$d->index_iterator($pos[0]);
is $nitems, 2, 'index contains 2 items';

$expected=[[enc 'Bärbel', $d->index_lookup($d->mainidx, @key2e)],
	   [enc 'Opi', $d->index_lookup($d->mainidx, @key1e)],
	  ];
for( my $i=0; (my $partkey, @pos)=$it->(); $i++ ) {
  is_deeply [$partkey, @pos], $expected->[$i], "index[$i]: @{$expected->[$i]}"
}

$d->stop;
