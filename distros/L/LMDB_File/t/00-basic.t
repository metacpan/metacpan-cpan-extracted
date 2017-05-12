#!perl

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('LMDB_File') };

LMDB_File->import(':all');

my $fail = 0;
foreach my $constname (qw(
	MDB_APPEND MDB_APPENDDUP MDB_BAD_RSLOT MDB_CORRUPTED MDB_CREATE
	MDB_CURRENT MDB_CURSOR_FULL MDB_DBS_FULL MDB_DUPFIXED MDB_DUPSORT
	MDB_FIRST MDB_FIRST_DUP MDB_FIXEDMAP MDB_GET_BOTH MDB_GET_BOTH_RANGE
	MDB_GET_CURRENT MDB_GET_MULTIPLE MDB_INCOMPATIBLE MDB_INTEGERDUP
	MDB_INTEGERKEY MDB_INVALID MDB_KEYEXIST MDB_LAST MDB_LAST_DUP
	MDB_LAST_ERRCODE MDB_MAPASYNC MDB_MAP_FULL MDB_MAP_RESIZED MDB_MULTIPLE
	MDB_NEXT MDB_NEXT_DUP MDB_NEXT_MULTIPLE MDB_NEXT_NODUP MDB_NODUPDATA
	MDB_NOMETASYNC MDB_NOOVERWRITE MDB_NOSUBDIR MDB_NOSYNC MDB_NOTFOUND
	MDB_NOTLS MDB_PAGE_FULL MDB_PAGE_NOTFOUND MDB_PANIC MDB_PREV
	MDB_PREV_DUP MDB_PREV_NODUP MDB_RDONLY MDB_READERS_FULL MDB_RESERVE
	MDB_REVERSEDUP MDB_REVERSEKEY MDB_SET MDB_SET_KEY MDB_SET_RANGE
	MDB_SUCCESS MDB_TLS_FULL MDB_TXN_FULL MDB_VERSION_FULL
	MDB_VERSION_MAJOR MDB_VERSION_MINOR MDB_VERSION_MISMATCH
	MDB_VERSION_PATCH MDB_VERSION_STRING MDB_VERSION_DATE MDB_WRITEMAP)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined LMDB macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $version = LMDB_File::version(my($major, $minor, $path));
ok($version,  "Version $version");
