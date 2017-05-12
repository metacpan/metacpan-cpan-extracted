#!perl -w
use diagnostics;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { # turn off locales for test
    use POSIX 'locale_h';
    $ENV{LC_ALL} = $ENV{LANG} = '';
    setlocale(LC_CTYPE, "");
    setlocale(LC_COLLATE, "");
}
BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib 'lib', 'blib';
use File::Sort 0.90 qw(sort_file);
$loaded = 1;
print "ok 1\n";

my $D = 0;
my $i = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


if (1) {
	local(*F0, *F1, *F2, *F3);
	my $fail1 = 0;
	my $fail2 = 0;
	my @files = qw(
		Sort.pm_sorted
		Sort.pm_sorted.txt
		Sort.pm_rsorted
		Sort.pm_rsorted.txt
  	);
	sort_file({ I => 'Sort.pm', o => $files[0], D => $D });
	sort_file({ I => 'Sort.pm', o => $files[2], r => 1, D => $D });

	open F0, $files[0] or $fail1++;
	open F1, $files[1] or $fail1++;
	open F2, $files[2] or $fail2++;
	open F3, $files[3] or $fail2++;

	while (<F1>) {
		chomp;
		defined(my $l = <F0>) or ($fail1++, last);
		chomp $l;
		$fail1++ if $l ne $_;
	}

	while (<F3>) {
		chomp;
		defined(my $l = <F2>) or ($fail2++, last);
		chomp $l;
		$fail2++ if $l ne $_;
	}

	close F0;
	close F1;
	close F2;
	close F3;

	printf "%s %d\n", ($fail1 ? 'not ok' : 'ok'), ++$i;
	printf "%s %d\n", ($fail2 ? 'not ok' : 'ok'), ++$i;

	unlink $files[0] unless $fail1;
	unlink $files[2] unless $fail2;

	open F1, $files[1] or $fail1++;
	open F3, $files[3] or $fail1++;

	my $temp = join '', sort <F1>, <F3>;

	close F1;
	close F3;

	sort_file({ I => [@files[1, 3]], o => $files[0], D => $D });
	open F0, $files[0] or $fail1++;

	{
		local $/;
		$fail1 ||= <F0> ne $temp;
		printf "%s %d\n", ($fail1 ? 'not ok' : 'ok'), ++$i;
	}

	close F0;

	unlink $files[0] unless $fail1;
}

if (1) {
	local(*F0, *F1, *F2);
	my $fail1 = 0;
	my $fail2 = 0;
	my @lines;
	my @files = qw(
		test10
		test20
		test30
	);

	for (0 .. 99) {
		(rand() > .5) ? push(@lines, $_) : unshift(@lines, $_);
	}

	open F0, ">$files[0]" or $fail1++ && $fail2++;
	print F0 join "\n", @lines;
	close F0;

	sort_file({ I => $files[0], o => $files[1], n => 1, 'y' => 2, D => $D });
	sort_file({ I => $files[0], o => $files[2], n => 1, r => 1, 'y' => 2, D => $D });

	open F1, $files[1] or $fail1++;
	open F2, $files[2] or $fail2++;

	for (0 .. 99) {
		defined(my $l = <F1>) or ($fail1++, last);
		chomp $l;
		$fail1++ if $l != $_;
	}

	for (reverse (0 .. 99)) {
		defined(my $l = <F2>) or ($fail2++, last);
		chomp $l;
		$fail2++ if $l != $_;
	}

	close F1;
	close F2;

	printf "%s %d\n", ($fail1 ? 'not ok' : 'ok'), ++$i;
	printf "%s %d\n", ($fail2 ? 'not ok' : 'ok'), ++$i;
	unlink @files unless $fail1 || $fail2;
}

if (1) {
	my $fail1 = 0;
	my $fail2 = 0;
	my @lines;
	my @files = qw(
		test11
		test21
		test31
	);

	for (0 .. 99) {
		(rand() > .5) ? push(@lines, sprintf "%s|$_", $_ % 2)
		    : unshift(@lines, sprintf "%s|$_", $_ % 2);
	}

	open F0, ">$files[0]" or $fail1++ && $fail2++;
	print F0 join "\n", @lines;
	close F0;
	sort_file({ I => $files[0], o => $files[1], n => 1,
	    t => '|', k => 2, Y => 3, D => $D });
	sort_file({ I => $files[0], o => $files[2], n => 1,
	    r => 1, t => '|', k => 2, Y =>3 , D => $D });
	
	open F1, $files[1] or $fail1++;
	open F2, $files[2] or $fail2++;

	for (0 .. 99) {
		defined(my $l = <F1>) or	($fail1++ or last);
		chomp $l;
		$_ = sprintf "%s|$_", $_ % 2;
		$fail1++ if $l ne $_;
	}

	for (reverse (0 .. 99)) {
		defined(my $l = <F2>) or ($fail2++, last);
		chomp $l;
		$_ = sprintf "%s|$_", $_ % 2;
		$fail2++ if $l ne $_;
	}

	close F1;
	close F2;

	printf "%s %d\n", ($fail1 ? 'not ok' : 'ok'), ++$i;
	printf "%s %d\n", ($fail2 ? 'not ok' : 'ok'), ++$i;
	unlink @files unless $fail1 || $fail2;
}

