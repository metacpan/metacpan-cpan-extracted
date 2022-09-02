#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use File::Temp qw(tempdir);
use Test::More;

BEGIN {
    plan skip_all => 'No Capture::Tiny available' if !eval { require Capture::Tiny; Capture::Tiny->import('capture'); 1 };
    plan skip_all => 'No Term::ANSIColor available' if !eval { require Term::ANSIColor; Term::ANSIColor->import('colorstrip'); 1 };
}
plan 'no_plan';

use Doit;

sub slurp ($) { open my $fh, shift or die $!; local $/; <$fh> }
sub _diff_available () { no warnings 'once'; defined $Doit::diff_cmd[0] }

my $d = Doit->init;

my $dir = tempdir(CLEANUP => 1);

{
    eval {
	$d->write_binary;
    };
    like colorstrip($@), qr{^ERROR: Expecting two arguments: filename and contents}, 'not enough arguments';
}

{
    eval {
	$d->write_binary({unhandled_option=>1}, "unused", "unused");
    };
    like colorstrip($@), qr{^ERROR: Unhandled options: unhandled_option}, 'unhandled option';
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary("$dir/test", "testcontent\n"), 1, 'a change, file creation';
    };
    is $stdout, '';
    like colorstrip($stderr), qr{^INFO: Create new file .*test with content:\ntestcontent\n$}, 'create file info';
    is slurp("$dir/test"), "testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary("$dir/test", "testcontent\n"), 0, 'no change';
    };
    is $stdout, '';
    is colorstrip($stderr), '', 'nothing happens';
    is slurp("$dir/test"), "testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary("$dir/test", "new testcontent\n"), 1, 'a change, changed content';
    };
    is $stdout, '';
    if (_diff_available) {
	like colorstrip($stderr), qr{^INFO: Replace existing file .*test with diff}, 'replace + diff';
    } else {
	# On Windows, something like
	#    'diff' is not recognized as an internal or external command, ...
	# appears also in STDERR
	like colorstrip($stderr), qr{INFO:.*diff not available};
    }
    is slurp("$dir/test"), "new testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary("$dir/test", "testcontent new\n"), 1, 'different content, same file size';
    };
    is $stdout, '';
    if (_diff_available) {
	like colorstrip($stderr), qr{^INFO: Replace existing file .*test with diff}, 'replace + diff';
    } else {
	like colorstrip($stderr), qr{INFO:.*diff not available};
    }
    is slurp("$dir/test"), "testcontent new\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary({quiet=>1}, "$dir/test2", "testcontent\n"), 1, 'quiet change, new file';
    };
    is $stdout, '';
    like colorstrip($stderr), qr{^INFO: Create new file .*test2$}, 'create new file in quiet=1 mode';
    is slurp("$dir/test2"), "testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary({quiet=>1}, "$dir/test", "new2 testcontent\n"), 1, 'quiet change, new content';
    };
    is $stdout, '';
    like colorstrip($stderr), qr{^INFO: Replace existing file .*test$}, 'replace file in quiet=1 mode';
    is slurp("$dir/test"), "new2 testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary({quiet=>2}, "$dir/test2", "testcontent\n"), 0, 'no change, very quiet';
    };
    is $stdout, '';
    is $stderr, '', 'insert completely quiet';
    is slurp("$dir/test2"), "testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	$d->write_binary({quiet=>2}, "$dir/test2", "new testcontent\n"), 1, 'very quiet change';
    };
    is $stdout, '';
    is $stderr, '', 'replace completely quiet';
    is slurp("$dir/test2"), "new testcontent\n";
}

{
    my($stdout, $stderr) = capture {
	is $d->write_binary({atomic=>0}, "$dir/test2", "non-atomic write\n"), 1;
    };
    is $stdout, '';
    isnt $stderr, '';
    is slurp("$dir/test2"), "non-atomic write\n", 'content after non-atomic write';
}

{
    require Encode;
    my($stdout, $stderr) = capture {
	is $d->write_binary("$dir/test-utf8", Encode::encode_utf8("\x{20ac}uro\n")), 1;
    };
    is $stdout, '';
    isnt $stderr, '';
    is slurp("$dir/test-utf8"), "\342\202\254uro\n", 'testing the encode_utf8 example';
}

{
    $d->write_binary("$dir/test3", "ancient file\n");
    $d->utime(1234, 1234, "$dir/test3");
    my $now = time;
    $d->write_binary("$dir/test3", "overwrite file\n");
    my @s = stat "$dir/test3";
    cmp_ok $s[8], ">=", $now, 'atime was modified';
    cmp_ok $s[9], ">=", $now, 'mtime was modified';
}

__END__
