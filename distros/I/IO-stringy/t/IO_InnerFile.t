#!/usr/bin/perl -w         #-*-Perl-*-

use lib "./t", "./lib"; 
use IO::InnerFile;
use IO::File;

use ExtUtils::TBone;
use Common;


#--------------------
#
# TEST...
#
#--------------------

# Make a tester:
my $T = typical ExtUtils::TBone;
Common->test_init(TBone=>$T);

$T->begin(7);

# Create a test file
open(OUT, '>t/dummy-test-file') || die("Cannot write t/dummy-test-file: $!");
print OUT <<'EOF';
Here is some dummy content.
Here is some more dummy content
Here is yet more dummy content.
And finally another line.
EOF
close(OUT);

# Open it as a regular file handle
my $fh = IO::File->new('<t/dummy-test-file');

my $inner = IO::InnerFile->new($fh, 28, 64); # Second and third lines

my $line;
$line = <$inner>;
$T->ok_eq($line, "Here is some more dummy content\n");
$line = <$inner>;
$T->ok_eq($line, "Here is yet more dummy content.\n");
$line = <$inner>;
$T->ok(!defined($line));

$inner->close();

$inner = IO::InnerFile->new($fh, 28, 64); # Second and third lines

# Test list context (CPAN ticket #66186)
my @arr;
@arr = <$inner>;
$T->ok(scalar(@arr) == 2);
$T->ok_eq($arr[0], "Here is some more dummy content\n");
$T->ok_eq($arr[1], "Here is yet more dummy content.\n");

# Make sure slurp mode works as expected
$inner->seek(0, 0);
{
	local $/;
	my $contents = <$inner>;
	$T->ok_eq($contents, "Here is some more dummy content\nHere is yet more dummy content.\n");
}

# So we know everything went well...
$T->end;
unlink('t/dummy-test-file');








