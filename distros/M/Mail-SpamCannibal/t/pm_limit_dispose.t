# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::ParseMessage qw(
	limitread
	dispose_of
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

=pod

-rw-r--r--    1 root     root         1628 May 27 16:35 spam1
-rw-r--r--    1 root     root         1284 May 27 11:54 spam2
-rw-r--r--    1 root     root         1247 May 27 11:54 spam3
-rw-r--r--    1 root     root         1167 May 27 11:54 spam4
-rw-r--r--    1 root     root         1562 May 27 11:54 spam5
-rw-r--r--    1 root     root         1936 May 27 11:54 spam6
-rw-r--r--    1 root     root         8896 May 27 11:54 spam7
-rw-r--r--    1 root     root         4562 May 27 11:54 spam8

=cut

my $file = './spam.lib/spam8';

# parameters for spam8
my $chars	= 4562;	# total characters
my $lines	= 97;	# lines expected

my @lines;

local *T;

## test 2 -- try read on closed file handle
print "read non-existent file handle\nnot "
	unless limitread(*T,\@lines,1) == 0;
&ok;

open *T,$file or die "could not open test file $file\n";

## test 3 -- read all lines

$_ = limitread(*T,\@lines,5000);

close *T;

print "expected $chars characters, got $_ characters\nnot "
	unless $chars == $_;
&ok;

## test 4 -- number of lines
print "expected $lines liness, got ", (scalar @lines), " lines \nnot "
	unless $lines == @lines;
&ok;

## test 5 -- check expected text
# reopen file
open(T,$file) or die "could not open $file for testing\n";
foreach(@lines) {
  $line = <T>;
  chomp $line;
  unless ($_ eq $line) {
    print "mismatched text line\nexp: $line\ngot: $_\nnot ";
    last;
  }
}
close T;
&ok;

## test 6 -- read the lines again with fewer lines
$chars	= 500;
open *T,$file or die "could not open test file $file\n";
$_ = limitread(*T,\@lines,$chars);
print "expected $chars characters, got $_ characters\nnot "
        unless $chars == $_;
&ok;

## test 7 -- number of lines
$lines	= 8;
print "expected $lines lines, got ", (scalar @lines), " lines \nnot "
        unless $lines == @lines;
&ok;

## test 8 -- dispose of the rest of file
$chars = 62;		# remainder of 500 + (n)1000 character reads
$_ = dispose_of(*T);
print "expected count of $chars, got $_\nnot "
	unless $chars == $_;
&ok;

## test 9 -- should be EOF

print "stream not empty\nnot "
	if <T>;
close T;
&ok;
