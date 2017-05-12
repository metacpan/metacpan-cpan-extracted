#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use File::Find;
use blib;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for testing" if $@;
plan tests => 37;

use_ok('DBI');
use_ok('Fuse::DBI');

my $test_db = 'fusedbi.db';
my $dsn = "DBI:SQLite:dbname=$test_db";
my $mount = '/tmp/fuse_dbi_mnt';

ok((! -e $test_db || unlink $test_db), "test db: $test_db");

ok((! -e $mount || rmdir $mount), "mount point $mount");

mkdir $mount || die "mkdir $mount: $!";
ok(-d $mount, "mkdir $mount");

ok(my $dbh = DBI->connect($dsn, , '', '', { RaiseError => 1 }),
	"connect fusedbi test database");

ok($dbh->do(qq{
	create table files (
		name text primary key,
		data text
	)
}), "create table files");

ok(my $sth = $dbh->prepare(qq{
	insert into files (name,data) values (?,?)
}), "prepare");

my @files = qw(file dir/file dir/subdir/file);
my %file_data;

foreach my $file (@files) {
	$file_data{$file} = ("this is test data on ".localtime()."\n") x length($file);
	ok($sth->execute($file,$file_data{$file}), "insert $file");
}

ok($dbh->disconnect, "disconnect after insert");

my $sql_filenames = qq{
	select
		name as id,
		name as filename,
		length(data) as size,
		1 as writable
	from files
};

my $sql_read = qq{
	select data
		from files
		where name = ?;
};

my $sql_update = qq{
	update files
		set data = ?	
		where name = ?;
};

system "fusermount -q -u $mount" || diag "nothing mounted at $mount, ok";

my $mnt = Fuse::DBI->mount({
	filenames => $sql_filenames,
	read => $sql_read,
	update => $sql_update,
	dsn => $dsn,
	mount => $mount,
	fork => 1,
});

ok($mnt, "mount");

sub test_file {
	my $f = $File::Find::name;

	ok($f, "file $f");

	return unless (-f $f);

	ok(open(F, $f), "open");
	my $tmp = '';
	while(<F>) {
		$tmp .= $_;
	}
	ok(close(F), "close");

	# strip mountpoint
	$f =~ s#^\Q$mount\E/##;

	ok($file_data{$f}, "$f exists");

	cmp_ok(length($file_data{$f}), '==', length($tmp), "size");
	cmp_ok($file_data{$f}, 'eq', $tmp, "content");
}

# small delay so that filesystem could mount
sleep(1);

find({ wanted => \&test_file, no_chdir => 1 }, $mount);

ok($mnt->umount,"umount");

ok(unlink $test_db,"rm $test_db");

ok(!-e $test_db,"cleanup");
