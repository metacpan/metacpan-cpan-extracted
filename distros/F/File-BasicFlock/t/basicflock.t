#!/usr/local/bin/perl -w -I.

$counter = "/tmp/flt1.$$";
$lock    = "/tmp/flt2.$$";

use File::BasicFlock;
use Carp;

$| = 1;

$children = 8;
$count = 50;
print "1..".($count+$children*2+2)."\n";

my $i;
for $i (1..$children) {
	$p = fork();
	croak unless defined $p;
	$parent = $p;
	last unless $parent;
}

$| = 1;

if ($parent) {
	print "ok 1\n";
	&write_file($counter, "2");
	&write_file($lock, "");
} else {
	while (! -e $lock) {
		# spin
	}
}

my $c;
while (($c = &read_file($counter)) < $count) {
	if ($c < $count*.25 || $c > $count*.75) {
		lock($lock);
	} else {
		lock($lock, 0, 1) || next;
	}
	$c = &read_file($counter);
	if ($c < $count) {
		print "ok $c\n";
		$c++;
		&overwrite_file($counter, "$c");
	}
	if ($c == int($count*.9)) {
		&overwrite_file($lock, "keepme");
	}
	unlock($lock);
}

lock($lock);
$c = &read_file($counter);
print "ok $c\n";
$c++;
&overwrite_file($counter, "$c");
unlock($lock);

if ($c == $count+$children+1) {
	print "ok $c\n";
	$c++;
	unlink($counter);
	if (&read_file($lock) eq 'keepme') 
		{print "ok $c\n";} else {print "not ok $c\n"};
	unlink($lock);
	$c++;
}

if ($parent) {
	$x = '';
	$c = $count+$children+3;
	for (1..$children) {
		wait();
		$status = $? >> 8;
		if ($status) { $x .= "not ok $c\n";} else {$x .= "ok $c\n"}
		$c++;
	}
	print $x;
}
exit(0);

sub read_file
{
	my ($file) = @_;

	local(*F);
	my $r;
	my (@r);

	open(F, "<$file") || croak "open $file: $!";
	@r = <F>;
	close(F);

	return @r if wantarray;
	return join("",@r);
}

sub write_file
{
	my ($f, @data) = @_;

	local(*F);

	open(F, ">$f") || croak "open >$f: $!";
	(print F @data) || croak "write $f: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub overwrite_file
{
	my ($f, @data) = @_;

	local(*F);

	if (-e $f) {
		open(F, "+<$f") || croak "open +<$f: $!";
	} else {
		open(F, "+>$f") || croak "open >$f: $!";
	}
	(print F @data) || croak "write $f: $!";
	my $where = tell(F);
	croak "could not tell($f): $!"
		unless defined $where;
	truncate(F, $where)
		|| croak "trucate $f at $where: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub append_file
{
	my ($f, @data) = @_;

	local(*F);

	open(F, ">>$f") || croak "open >>$f: $!";
	(print F @data) || croak "write $f: $!";
	close(F) || croak "close $f: $!";
	return 1;
}

sub read_dir
{
	my ($d) = @_;

	my (@r);
	local(*D);

	opendir(D,$d) || croak "opendir $d: $!";
	@r = grep($_ ne "." && $_ ne "..", readdir(D));
	closedir(D);
	return @r;
}

1;
