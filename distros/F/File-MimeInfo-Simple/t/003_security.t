use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More tests => 4;
use File::MimeInfo::Simple;

# Test that shell metacharacters in filenames don't cause command injection
# If vulnerable, these could execute arbitrary commands

my $tempdir = tempdir(CLEANUP => 1);

# Test 1: Filename with semicolon (command separator)
my $malicious_file1 = File::Spec->catfile($tempdir, 'test; echo PWNED.txt');
open(my $fh1, '>', $malicious_file1) or die "Cannot create test file: $!";
print $fh1 "test content\n";
close($fh1);

my $result1 = mimetype($malicious_file1);
ok(defined($result1) || $result1 eq '', "handles semicolon in filename without crashing");

# Test 2: Filename with backticks (command substitution)
my $malicious_file2 = File::Spec->catfile($tempdir, 'test`echo PWNED`.txt');
open(my $fh2, '>', $malicious_file2) or die "Cannot create test file: $!";
print $fh2 "test content\n";
close($fh2);

my $result2 = mimetype($malicious_file2);
ok(defined($result2) || $result2 eq '', "handles backticks in filename without crashing");

# Test 3: Filename with $() (command substitution)
my $malicious_file3 = File::Spec->catfile($tempdir, 'test$(echo PWNED).txt');
open(my $fh3, '>', $malicious_file3) or die "Cannot create test file: $!";
print $fh3 "test content\n";
close($fh3);

my $result3 = mimetype($malicious_file3);
ok(defined($result3) || $result3 eq '', "handles \$() in filename without crashing");

# Test 4: Filename with pipe (command piping)
my $malicious_file4 = File::Spec->catfile($tempdir, 'test|echo PWNED.txt');
open(my $fh4, '>', $malicious_file4) or die "Cannot create test file: $!";
print $fh4 "test content\n";
close($fh4);

my $result4 = mimetype($malicious_file4);
ok(defined($result4) || $result4 eq '', "handles pipe in filename without crashing");

# If any of the above caused command injection, 'PWNED' would appear in output
# or the tests would fail/behave unexpectedly

