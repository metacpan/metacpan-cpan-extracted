use Test::More tests => 236;

use utf8;

use Logfile::Tail ();
use Digest::SHA ();
use Cwd ();

my $CWD = Cwd::getcwd();

require 't/lib.pl';

my $DATE = '20100101';
sub rotate_file {
	my $file = shift;
	my $type = shift;
	if ($type eq 'date') {
		ok((rename $file, "$file-$DATE"), "renamed [$file] to [$file-$DATE]");
		$DATE++;
	} elsif ($type eq 'num') {
		for (
			sort { $b <=> $a }
			map { /^(.+\.(.+))$/ ? ( $2 ) : () }
			glob "$file.*") {
			my $next = $_ + 1;
			ok((rename "$file.$_", "$file.$next"), "renamed [$file.$_] to [$file.$next]");
		}
		ok((rename $file, "$file.1"), "renamed [$file] to [$file.1]");
	} else {
		die "Unknown rotate_file type [$type]\n";
	}
	truncate_file($file, "  trucate [$file] by writing nothing");
}

is(system('rm', '-rf', glob('t/rotate*'), '.logfile-tail-status'), 0, 'remove old files');

my $i = 0;
for my $type (qw( num date )) {
	$i++;

	my $file = "t/rotate$i";
	my $status_filename = '.logfile-tail-status/'
		. Digest::SHA::sha256_hex("$CWD/$file");

	unlink $status_filename;

	is((-f $file), undef, 'sanity check, the log file should not exist');
	is((-f $status_filename), undef, '  and neither should the status file');

	my $line;

	truncate_file($file);
	append_to_file($file, 'create file we would be reading',
		"line 1.1", "line 1.2");

	my $logfile;
	ok(($logfile = new Logfile::Tail($file)), 'open the file as logfile');
	check_status_file($status_filename,
		"File [$file] offset [0] checksum [e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]\n",
		'check that opening the logfile for the first time initiates the status file'
	);

	ok(($line = $logfile->getline()), 'read the first line');
	is($line, "line 1.1\n", '  check the line');
	check_status_file($status_filename,
		"File [$file] offset [0] checksum [e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855]\n",
		'check that offset stayed the same'
	);

	rotate_file($file, $type);
	append_to_file($file, 'put content to log file (which was rotated by now, so it is a new file)',
		map "line 2.$_", 1 .. 1000);

	ok(($line = <$logfile>), 'read the second line');
	is($line, "line 1.2\n", '  check the line');

	ok(($line = <$logfile>), 'read the third line, actually first line of the now current file');
	is($line, "line 2.1\n", '  check the line');

	ok($logfile->close, 'close the log file');
	is((undef $logfile), undef, 'undef the object as well');

	check_status_file($status_filename,
		"File [$file] offset [9] checksum [02f64b3c17ca51e9943b3263bf6fb07783922055de233ab22649cc446c33046d]\n",
		'check that offset now points to the end of the first line'
	);

	ok(($logfile = new Logfile::Tail($file)), 'open the logfile again');
	ok(($line = <$logfile>), 'read one line (second from the now-rotated file)');
	is($line, "line 2.2\n", '  check the line');

	ok(($line = <$logfile>), 'read next line');
	is($line, "line 2.3\n", '  check the line');
	is($logfile->commit(), 1, 'commit to status file');

	check_status_file($status_filename,
		"File [$file] offset [27] checksum [a9b882704260e93c4d50f7a7ce76f26c1ffcc061d3fd65aeda20865079cac4e4]\n",
		'check that offset now points to the end of the third line; the object does not know that we are now on the rotated file'
	);

	rotate_file($file, $type);
	append_to_file($file, 'put content to log file',
		"line 4.1");

	ok(($line = <$logfile>), 'read one line (fourth from the yet-another-time-rotated file)');
	is($line, "line 2.4\n", '  check the line');
	is($logfile->commit(), 1, 'commit to status file');

	check_status_file($status_filename,
		"File [$file] offset [36] checksum [cd289aa857f06a7d8c005923298818545885e32d550b57639ca8a5afabf3dd6b]\n",
		'check that offset now points to the end of the second line; we still do not know it has been rotated'
	);

	rotate_file($file, $type);

	ok(($line = <$logfile>), 'read one more line');
	is($line, "line 2.5\n", '  check the line');

	ok($logfile->close, 'close the log file');
	is((undef $logfile), undef, 'undef the object as well');

	check_status_file($status_filename,
		"File [$file] offset [45] checksum [e4b45b02c352a11022d26aa3d37e42c5c43e0ca85cecefb23d61c0becae07a52]\n",
		'check that offset points to the fifth line'
	);

	ok(($logfile = new Logfile::Tail($file)), 'open the logfile yet again');
	ok(($line = <$logfile>), 'read one line');
	is($line, "line 2.6\n", '  check the line');

	is($logfile->close(), 1, 'close the file');
	check_status_file($status_filename,
		"File [$file] archive [@{[ $type eq 'num' ? '.2' : '-20100102' ]}] offset [54] checksum [3fc745f588af1955a409bc1f1cf5aa666c08a19e3c6985eeb345c3921d256820]\n",
		'check that status file now has archive info'
	);

	ok(($logfile = new Logfile::Tail($file)), 'and open again, to see processing of status file with archive info');
	ok(($line = <$logfile>), 'read one line');
	is($line, "line 2.7\n", '  check the line');
	is($logfile->close(), 1, 'close the file');

	check_status_file($status_filename,
		"File [$file] archive [@{[ $type eq 'num' ? '.2' : '-20100102' ]}] offset [63] checksum [a4cc5dafbe0afbfd90d19ee4bdfaca08edaa84765532e59edb6380e5cd0ebea3]\n",
		'check the archive info'
	);

	rotate_file($file, $type);
	append_to_file($file, 'put content to log file',
		map "line 5.$_", 1 .. 5);

	ok(($logfile = new Logfile::Tail($file)), 'open again, now the archive info points to file which was rotated again');
	my @lines = $logfile->getlines();
	is(scalar(@lines), 999, 'check number of lines we got');
	is($lines[$#lines], "line 5.5\n", 'check the last line');

	ok($logfile->close, 'close the log file');
	is((undef $logfile), undef, 'undef the object');

	check_status_file($status_filename,
		"File [$file] offset [45] checksum [471663ec09c5520e716a649757dae978a54850d824a15bd63d88d841e0bfc0f5]\n",
		'check that offset points to the end of the log file'
	);
}

my $status_filename = '.logfile-tail-status/'
	. Digest::SHA::sha256_hex("$CWD/t/rotfail");
is(system('rm', '-rf', glob('t/rotfail*'), $status_filename), 0, 'remove old rotfiles');

append_to_file('t/rotfail', 'create new rotfail',
        "Line 5");
append_to_file('t/rotfail.1', 'create rotfail.1',
        "Line 4");
is(mkdir('t/rotfail.2'), 1, 'create rotfail.2 as directory');
append_to_file('t/rotfail.3', 'create rotfail.3',
        "Line 3");
is(symlink('nonexistent', 't/rotfail.4'), 1, 'rotfail.4 is a symlink which points nowhere');
append_to_file('t/rotfail.5', 'create rotfail.5',
        "Line 1", "Line 2");

append_to_file($status_filename, 'set status file for t/rotfile',
	"File [$CWD/t/rotfail] archive [.5] offset [7] checksum [3de22f9f20b5ff997cf08b76e7692d26e49ce7a649ea5a11ba9f835c8b7179a5]\n");

ok(($logfile = new Logfile::Tail('t/rotfail')),
        'open the rotfail');

my @lines = <$logfile>;
is_deeply(\@lines, [
        "Line 2\n", "Line 3\n", "Line 4\n", "Line 5\n",
        ], 'check that we have read all lines, even if archives are bad (directory, symlink)');

truncate_file($status_filename, 'reset status file for t/rotfile');
append_to_file($status_filename, 'set status file for t/rotfile, will need to find older archive',
	"File [$CWD/t/rotfail] archive [.3] offset [7] checksum [3de22f9f20b5ff997cf08b76e7692d26e49ce7a649ea5a11ba9f835c8b7179a5]\n");

ok(($logfile = new Logfile::Tail('t/rotfail')),
        'open the rotfail');

@lines = <$logfile>;
is_deeply(\@lines, [
        "Line 2\n", "Line 3\n", "Line 4\n", "Line 5\n",
        ], 'check that we have read all lines, even if archives are bad (directory, symlink)');

truncate_file($status_filename, 'reset status file for t/rotfile');
append_to_file($status_filename, 'set status file for t/rotfile, will need to walk archives',
	"File [$CWD/t/rotfail] archive [.4] offset [7] checksum [3de22f9f20b5ff997cf08b76e7692d26e49ce7a649ea5a11ba9f835c8b7179a5]\n");

ok(($logfile = new Logfile::Tail('t/rotfail')),
        'open the rotfail');

is(unlink('t/rotfail'), 1, 'remove the "core" t/rotfail file, let us just work with archives');

@lines = <$logfile>;
is_deeply(\@lines, [
        "Line 2\n", "Line 3\n", "Line 4\n",
        ], 'check that we have read all lines, even if archives are bad (directory, symlink)');

truncate_file($status_filename, 'reset status file for t/rotfile');
append_to_file($status_filename, 'set status file for t/rotfile, archive pointing to bad file (symlink to nonexistent file)',
	"File [$CWD/t/rotfail] offset [7] checksum [3de22f9f20b5ff997cf08b76e7692d26e49ce7a649ea5a11ba9f835c8b7179a5]\n");

append_to_file('t/rotfail', 'put the rotfail file back',
        "Line 5");

ok(($logfile = new Logfile::Tail('t/rotfail')),
        'open the rotfail');

my $line = <$logfile>;
is($line, "Line 2\n", 'check the second line in the oldest archive');

is(rename('t/rotfail.5', 't/rotfail.6'), 1, 'rotate the oldest archive but not the newer');
$line = <$logfile>;
is($line, "Line 3\n", 'check that the switch to the newer archive worked well');

is(unlink('t/rotfail.6', 't/rotfail.4', 't/rotfail.3'), 3, 'remove all old archives');
$line = <$logfile>;
is($line, undef, 'check that in this case we have lost the sync');

