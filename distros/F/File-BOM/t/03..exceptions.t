#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use Test::Framework;

use File::BOM qw(
	open_bom
	decode_from_bom
	get_encoding_from_filehandle
    );

use File::Temp qw( tmpnam );

use Test::Exception ( tests => 10 );
use Test::More;

my $absent = tmpnam();
throws_ok { open_bom(my $fh, $absent) }
	  qr/^Couldn't read/,
	  "open_bom on non-existant file fails";

throws_ok { open_bom(my $fh, ">new_file.txt") }
	  qr(^Couldn't read),
	  "Attempt to open_bom for writing fails";

throws_ok { open_bom(my $fh, "| cat") }
	  qr(^Couldn't read),
	  "Attempt to open_bom as pipe fails";

throws_ok { decode_from_bom(undef) }
	  qr/^No string/,
	  "decode_from_bom with no string fails";

{
    # The following tests are known to produce warnings
    local $SIG{__WARN__} = sub {};

    my $tmpfile = tmpnam();
    open WRITER, '>', $tmpfile or die "Couldn't write to '$tmpfile': $!";

    # _get_encoding_* functions don't qualify refs as they are not public
    # Therefore _get_encoding_seekable(WRITER) will not work
    throws_ok { File::BOM::_get_encoding_seekable(\*WRITER) }
	    qr/^Couldn't read from handle/,
	    "_get_encoding_seekable on unreadable handle fails";

    throws_ok { File::BOM::_get_encoding_unseekable(\*WRITER) }
            qr/^Couldn't read byte/,
            "_get_encoding_unseekable() on unreadable handle fails";

    close WRITER;
    unlink $tmpfile;

    SKIP:
    {
	skip "mkfifo not supported on this platform", 3
	    unless $fifo_supported;

        skip "mkfifo tests skipped on cygwin, set TEST_FIFO to enable them", 3
            if $^O eq 'cygwin' && !$ENV{'TEST_FIFO'};

	my($pid, $fifo);

	($pid, $fifo) = write_fifo('');
	open(STREAM, '<:bytes', $fifo) or die "Couldn't read fifo '$fifo': $!";

	throws_ok { File::BOM::_get_encoding_seekable(\*STREAM) }
		qr/^Couldn't reset read position/,
		"_get_encoding_seekable on unseekable handle fails";

	throws_ok { get_encoding_from_filehandle(STREAM) }
		qr/^Unseekable handle/,
		"get_encoding_from_filehandle on unseekable handle fails";

	close STREAM; waitpid($pid, 0); unlink $fifo;

	($pid, $fifo) = write_fifo('');
	lives_ok { my($enc) = open_bom(my $fh, $fifo) }
		"(\$enc) = open_bom(FH, \$fifo) lives";
	
	waitpid($pid, 0); unlink $fifo;
    }

    throws_ok { open_bom(my $fh, 't/data/no_bom.txt', 'invalid') }
		qr/^Couldn't set binmode of handle opened on/,
		"open_bom with invalid default encoding fails";

}

__END__

vim:ft=perl
