#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 44;
use Test::Differences;
use File::Spec;
use File::Temp 'tempdir';
use File::Slurp 'read_file';
use Test::Exception;
use IO::File;
use Fcntl qw(:flock);
use Scalar::Util 'blessed';

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'IO::Any' ) or exit;
}

exit main();

sub main {
	my $tmpdir = tempdir( CLEANUP => 1 );

    throws_ok { IO::Any->new('', '<', { unknown => 1 }) } qr/unknown option/, 'option checking';

    my $io_file = IO::File->new();
    $io_file->open('< '.__FILE__);
	my @riddles = (
		'filename'                => [ 'file' => 'filename' ],
		'folder/filename'         => [ 'file' => 'folder/filename' ],
		'file:///folder/filename' => [ 'file' => '/folder/filename' ],
		[ 'folder', 'filename' ]  => [ 'file' => File::Spec->catfile('folder', 'filename') ],
		'http://a/b/c'            => [ 'http' => 'http://a/b/c' ],
		'https://a/b/c'           => [ 'http' => 'https://a/b/c' ],
		'{"123":[1,2,3]}'         => [ 'string' => '{"123":[1,2,3]}' ],
		'[1,2,3]'                 => [ 'string' => '[1,2,3]' ],
		'<xml></xml>'             => [ 'string' => '<xml></xml>' ],
		"a\nb\nc\n"               => [ 'string' => "a\nb\nc\n" ],
		''                        => [ 'string' => '' ],
		$io_file                  => [ 'iofile' => 'IO::File' ],
	);
	
	while (my ($question, $answer_expected) = splice(@riddles,0,2)) {
		my ($type, $answer) = IO::Any->_guess_what($question);
		eq_or_diff([$type, blessed($answer) ? blessed($answer) : $answer], $answer_expected, 'guess what is "'.$question.'"')
	}
	
	isa_ok(IO::Any->read([$Bin, 'stock', '01.txt']), 'IO::File', 'IO::Any->read([])');
	isa_ok(IO::Any->read('{}'), 'IO::String', 'IO::Any->read("{}")');

	throws_ok {
		IO::Any->write([$tmpdir, 'trash'], {'abc' => 1})
	} qr{option abc}, 'options check';
	
	eq_or_diff(
		[ IO::Any->slurp([$Bin, 'stock', '01.txt']) ],
		[ qq{1\n22\n333\n} ],
		'[ IO::Any->slurp() ]'
	);
	eq_or_diff(
		scalar IO::Any->slurp([$Bin, 'stock', '01.txt']),
		qq{1\n22\n333\n},
		'scalar IO::Any->slurp()'
	);
	
	IO::Any->spew([$tmpdir, '01-test.txt'], qq{4\n55\n666\n});
	eq_or_diff(
		scalar read_file(File::Spec->catfile($tmpdir, '01-test.txt')),
		qq{4\n55\n666\n},
		'IO::Any->spew()'
	);
	my $write_fh = IO::Any->write([$tmpdir, '02-test.txt'], {'atomic' => 1});
	isa_ok($write_fh, 'IO::AtomicFile', 'check atomic handle');
	
	IO::Any->spew([$tmpdir, '03-test.txt'], qq{atom\n}, {'atomic' => 1});
	eq_or_diff(
		scalar read_file(File::Spec->catfile($tmpdir, '03-test.txt')),
		qq{atom\n},
		'atomic IO::Any->spew()'
	);

	LAYERS: {
		my $file = [$tmpdir, '05-bytes.txt'];
		my $path = File::Spec->catfile(@$file);
		IO::Any->spew($file, "\xc3\xa4");
		eq_or_diff(scalar read_file($path, binmode => ':raw'), "\xc3\xa4", 'spew() without BINMODE writes bytes unchanged');
		eq_or_diff(scalar IO::Any->slurp($file), "\xc3\xa4", 'slurp() without BINMODE returns bytes');

		IO::Any->spew($file, "\x{e4}", { BINMODE => ':utf8' });
		eq_or_diff(scalar read_file($path, binmode => ':raw'), "\xc3\xa4", 'spew() with BINMODE => ":utf8" encodes');
		eq_or_diff(scalar IO::Any->slurp($file, { BINMODE => ':utf8' }), "\x{e4}", 'slurp() with BINMODE => ":utf8" decodes');
	}

	ATOMIC_FAILURE: {
		my $file = [$tmpdir, '06-atomic.txt'];
		my $path = File::Spec->catfile(@$file);
		IO::Any->spew($file, 'old');
		{
			local $SIG{__WARN__} = sub {};    # expected 'Unknown PerlIO layer "bogus"'
			dies_ok { IO::Any->spew($file, 'new', { atomic => 1, BINMODE => ':bogus' }) } 'atomic spew() dies when binmode fails';
		}
		eq_or_diff(scalar read_file($path), 'old', 'failed atomic spew() keeps the old content');

		# another writer holds the lock on the shared temp file
		open(my $other, '+>>', $path.'..TMP') or die $!;
		print $other 'partial';
		$other->flush;
		flock($other, LOCK_EX) or die $!;
		dies_ok { IO::Any->spew($file, 'new', { atomic => 1, LOCK_EX => 1, LOCK_NB => 1 }) } 'atomic spew() dies when flock fails';
		eq_or_diff(scalar read_file($path), 'old', 'failed atomic flock keeps the old content');
		close($other);

		# rename() of the temp file fails when the target is a directory
		my $dir = File::Spec->catdir($tmpdir, '07-dir');
		mkdir $dir or die $!;
		throws_ok { IO::Any->spew($dir, 'new', { atomic => 1 }) } qr/failed to close/, 'atomic spew() dies when the rename fails';
		ok(!-e $dir.'..TMP', 'failed atomic spew() leaves no temp file');
	}

	my $str;
	IO::Any->spew(\$str, qq{1\n22\n333\n});
	eq_or_diff(
		$str,
		qq{1\n22\n333\n},
		'IO::Any->spew(\$str)'
	);
	
	LOCKING: {
		my $locking_filename = [$tmpdir, '04-test.txt'];
		IO::Any->spew($locking_filename, qq{locking\n}, {'LOCK_EX' => 1});
		eq_or_diff(
			scalar read_file(File::Spec->catfile(@{$locking_filename})),
			qq{locking\n},
			'LOCK_EX IO::Any->spew()'
		);
		
	    my $locked_fh = IO::Any->new($locking_filename, '+>>', {'LOCK_EX' => 1});
		dies_ok { IO::Any->new($locking_filename, '+>>', {'LOCK_EX' => 1, 'LOCK_NB' => 1}) } 'another non-blocking ex loc should fail';
		dies_ok { IO::Any->new($locking_filename, '<', {'LOCK_SH' => 1, 'LOCK_NB' => 1}) } 'another non-blocking sh loc should fail';
		dies_ok { IO::Any->spew($locking_filename, 'grrrr', {'LOCK_EX' => 1, 'LOCK_NB' => 1}) } 'spew() when non-blocking ex loc should fail';
		$locked_fh->close();

		eq_or_diff(
			IO::Any->slurp($locking_filename),
			qq{locking\n},
			'file should be left intact'
		);
		
	    my $r_locked_fh = IO::Any->read($locking_filename, {'LOCK_SH' => 1});
	    ok($r_locked_fh, 'this time LOCK_SH');
		lives_ok { IO::Any->new($locking_filename, '<', {'LOCK_SH' => 1, 'LOCK_NB' => 1}) } 'another non-blocking sh loc should pass';
		dies_ok { IO::Any->new($locking_filename, '+>>', {'LOCK_EX' => 1, 'LOCK_NB' => 1}) } 'non-blocking ex loc should fail';
	}
	
	STRANGE_ARGUMENTS: {
		throws_ok {
			IO::Any->read()
		} qr{is missing}, 'there has to be some $what';

		throws_ok {
			IO::Any->read(undef)
		} qr{is missing}, 'undef throws an exception';

		lives_ok { IO::Any->read('') } 'empty string is fine to read';
	}
	
	return 0;
}

