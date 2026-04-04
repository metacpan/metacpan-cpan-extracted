#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempfile);

# Create a test file with multiple lines
my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh "line one\n";
print $fh "line two\n";
print $fh "line three\n";
print $fh "line four\n";
close $fh;

# Test File::Raw::lines (returns array, lines are chomped)
my $lines = File::Raw::lines($filename);
isa_ok($lines, 'ARRAY', 'File::Raw::lines returns array');
is(scalar @$lines, 4, 'File::Raw::lines: 4 lines');
is($lines->[0], "line one", 'File::Raw::lines: first line (chomped)');
is($lines->[3], "line four", 'File::Raw::lines: last line (chomped)');

# Test File::Raw::lines_iter (returns iterator object)
my $iter = File::Raw::lines_iter($filename);
isa_ok($iter, 'File::Raw::lines', 'File::Raw::lines_iter returns lines object');

# Test lines::next (lines are chomped)
my $line1 = $iter->next();
is($line1, "line one", 'lines::next returns first line');

my $line2 = $iter->next();
is($line2, "line two", 'lines::next returns second line');

# Test lines::eof (should be false, still have lines)
ok(!$iter->eof(), 'lines::eof is false when more lines exist');

# Read remaining lines
my $line3 = $iter->next();
is($line3, "line three", 'lines::next returns third line');

my $line4 = $iter->next();
is($line4, "line four", 'lines::next returns fourth line');

# Now should be at EOF
my $line5 = $iter->next();
ok(!defined($line5) || $line5 eq '', 'lines::next returns undef/empty at EOF');

ok($iter->eof(), 'lines::eof is true at end of file');

# Test lines::close
eval { $iter->close(); };
ok(!$@, 'lines::close completes without error');

# Test DESTROY (implicit, just ensure no crash)
undef $iter;
ok(1, 'lines::DESTROY completed without crash');

done_testing();
