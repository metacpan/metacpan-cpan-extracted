#!/usr/bin/perl

use strict;
use warnings;

use lib qw( t/lib );

use Test::More;
use Test::Framework;

use Encode qw( encode decode :fallback_all );
use Fcntl qw( :seek );

our @encodings;
BEGIN {
    # encodings to use in unseekable test
    @encodings = qw( UTF-8 UTF-16LE UTF-16BE UTF-32LE UTF-32BE );

    plan tests => 11 + (@test_files * 14) + (@encodings * 4);

    use_ok("File::BOM", ':all');
}

# Ignore known harmless warning
local $SIG{__WARN__} = sub {
    my $warning = "@_";
    if ($warning !~ /^UTF-(?:16|32)LE:Partial character/) {
	warn $warning;
    }
};

for my $file (@test_files) {
    my $file_enc = $file2enc{$file};
    is(open_bom(FH, $file2path{$file}), $file2enc{$file}, "$file: open_bom returned encoding");
    my $expect = $filecontent{$file};

    my $line = <FH>;
    chomp $line;

    is($line, $expect, "$file: test content returned OK");

    close FH;

    {
	# test defuse
	open BOMB, '<', $file2path{$file}
	    or die "Couldn't read '$file2path{$file}': $!";

	my $enc = defuse BOMB;
	is($enc, $file_enc, "$file: defuse returns correct encoding ($enc)");
	$line = <BOMB>;
	chomp $line;
	is($line, $expect, "$file: defused version content OK");

	close BOMB;
    }

    open FH, '<', $file2path{$file};
    my $first_line = <FH>;
    chomp $first_line;

    seek(FH, 0, SEEK_SET);

    is(get_encoding_from_filehandle(FH), $file_enc, "$file: get_encoding_from_filehandle returned correct encoding");

    my($enc, $offset) = get_encoding_from_bom($first_line);
    is($enc, $file_enc, "$file: get_encoding_from_bom also worked");

    {
	my $decoded = $enc ? decode($enc, substr($first_line, $offset))
			   : $first_line;

	is($decoded, $expect, "$file: .. and offset worked with substr()");
    }

    #
    # decode_from_bom()
    #
    my $result = decode_from_bom($first_line, 'UTF-8', FB_CROAK);
    is($result, $expect, "$file: decode_from_bom() scalar context");
    {
	# with default
	my $default = 'UTF-8';
	my $expect_enc = $file_enc || $default;

	my($decoded, $got_enc) = decode_from_bom($first_line, $default, FB_CROAK);

	is($decoded, $expect,      "$file: decode_from_bom() list context");
	is($got_enc, $expect_enc,  "$file: decode_from_bom() list context encoding");
    }
    {
	# without default
	my $expect_enc = $file_enc;
	my($decoded, $got_enc) = decode_from_bom($first_line, undef, FB_CROAK);

	is($decoded, $expect,      "$file: decode_from_bom() list context, no default");
	is($got_enc, $expect_enc,  "$file: decode_from_bom() list context encoding, no default");
    }

    seek(FH, 0, SEEK_SET);

    ($enc, my $spill) = get_encoding_from_stream(FH);

    $line = <FH>; chomp $line;

    is($enc, $file_enc, "$file: get_encoding_from_stream()");

    $line = $spill . $line;
    $line = decode($enc, $line) if $enc;

    is($line, $expect, "$file: read OK after get_encoding_from_stream");

    close FH;
}

# Test unseekable
SKIP: {
    my $tests = 4 * @encodings;
    skip "mkfifo not supported on this platform", $tests
	unless $fifo_supported;

    skip "mkfifo tests skipped on cygwin, set TEST_FIFO to enable them", $tests
        if $^O eq 'cygwin' && !$ENV{'TEST_FIFO'};

    for my $encoding (@encodings) {
	my($pid, $fifo, $enc, $spill, $result);

        # We need two copies of this as the encode below is destructive!
        my $expected = my $test = "Testing \x{2170}, \x{2171}, \x{2172}\n";

	my $bytes = $enc2bom{$encoding}
                  . encode($encoding, $test, FB_CROAK);

	($pid, $fifo) = write_fifo($bytes);
	($enc, $spill) = open_bom(my $fh, $fifo);
	$result = $spill . <$fh>;

	close $fh;
	waitpid($pid, 0);
	unlink $fifo;

	is($enc, $encoding,    "Read BOM correctly in unseekable $encoding file");
	is($result, $expected, "Read $encoding data from unseekable source");

	# Now test defuse too
	($pid, $fifo) = write_fifo($bytes);
	open($fh, '<:utf8', $fifo) or die "Couldn't read '$fifo': $!";
	($enc, $spill) = defuse $fh;
	$result = $spill . <$fh>;

	close $fh;
	waitpid($pid, 0);
	unlink $fifo;

	is($enc, $encoding, "defused fifo OK ($encoding)");
	is($result, $expected, "read defused fifo OK ($encoding)")
        or diag(
            "Hex dump:\n".
            "Got:      ". hexdump($result) ."\n".
            "Expected: ". hexdump($expected) ."\n".
            "Spillage: ". hexdump($spill)
        );
    }
}

# Test broken BOM
{
    my $broken_content = "\xff\xffThis file has a broken BOM";
    my $broken_file = 't/data/broken_bom.txt';
    my($enc, $spill) = open_bom(my $fh, $broken_file);
    is($enc, '', "open_bom on file with broken BOM has no encoding");
    {
	my $line = <$fh>;
	chomp $line;
	is($line, $broken_content, "handle with broken BOM returns as expected");
    }

    SKIP: {
	skip "mkfifo not supported on this platform", 3
	    unless $fifo_supported;

        skip "mkfifo tests skipped on cygwin, set TEST_FIFO to enable them", 3
            if $^O eq 'cygwin' && !$ENV{'TEST_FIFO'};

	my($pid, $fifo) = write_fifo($broken_content);
	open my $fh, '<', $fifo or die "Cannot read fifo '$fifo': $!";
	my($enc, $spill) = get_encoding_from_filehandle($fh);
	is($enc, '', "get_encoding_from_filehandle() on unseekable file broken bom");
	ok($spill, ".. spillage was produced");
	is($spill . <$fh>, $broken_content, "spillage + content as expected");

	close $fh;
	waitpid($pid, 0);
	unlink $fifo;
    }
}

# Test internals

is(File::BOM::_get_char_length('UTF-8', 0xe5), 3, '_get_char_length() on UTF-8 start byte (3)');
is(File::BOM::_get_char_length('UTF-8', 0xd5), 2, '_get_char_length() on UTF-8 start byte (2)');
is(File::BOM::_get_char_length('UTF-8', 0x7f), 1, '_get_char_langth() on UTF-8 single byte char');
is(File::BOM::_get_char_length('', ''), undef,    '_get_char_length() on undef');
is(File::BOM::_get_char_length('UTF-32BE', ''), 4,  '_get_char_length() on UTF-32');

__END__

vim: ft=perl
