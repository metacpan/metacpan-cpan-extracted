
package Devel::FileProfile;

use Time::HiRes qw(alarm time);

my $looplen = 5000;
my $freq = 0.01;
my $context = 7;
my $started = 0;
my %files;
my %hits;
my $hits = 0;
my $done = 0;

our $VERSION = 0.22;

sub start
{
	return if $started++;
	$main::SIG{ALRM} = \&ticktock;
	my $t1 = time;
	for my $i (0..$looplen) {
		sprintf("%-10d", $i);
	}
	my $t2 = time;
	$freq = $t2 - $t1;
	alarm($freq);
}

sub import
{
	my ($pkg, $file, $line) = caller();
	$files{$file} = $line;
	start();
}

sub ticktock
{
	my $i = 0;
	my %done;
	while(my ($pkg, $file, $line) = caller($i++)) {
		next unless $files{$file};
		next if $done{$file}{$line}++; # don't overcount recursion
		$hits{$file}{$line}++;
	}
	$hits++;
	alarm($freq) unless $done;
}

sub END
{
	print STDERR "# BEGIN PROFILE DATA\n";
	printf STDERR "# SAMPLE RATE = %.4f seconds\n", $freq;

	$done = 1;

	for my $file (sort keys %hits) {
		my @lines = sort { $a <=> $b } keys %{$hits{$file}};
		print STDERR "########### $file\n";
		local(*FILE);
		open(FILE, "<$file") || die "open $file: $!";
		my $line = 0;
		my $last = 0;
		while(<FILE>) {
			$line++;
			next if $line < $lines[0] - $context;
			shift(@lines) while @lines and $line > $lines[0]+$context;
			last unless @lines;
			next if $line > $lines[0] + $context;
			print "\n" if $last and ! ($last + 1 == $line);
			if ($hits{$file}{$line}) {
				printf STDERR "%-4s %-10d %s", scalenum($hits{$file}{$line}/$hits*100), $line, $_;
			} else {
				printf STDERR "     %-10d %s", $line, $_;
			}
			$last = $line;
		}
	}
	print STDERR "# END PROFILE DATA\n";
}

# 0.04
# 0.37
# 3.73
# 37.3
# 3731
# 3.7K
# 37K
# 370K

sub scalenum
{
	my ($num) = @_;
	die if $num < 0;
	if ($num < 100) {
		return int($num) if $num - int($num) < 0.00001;
		return int($num+1) if $num + 0.00001 > int($num+1);
		return sprintf("%.2f", $num) if $num < 10;
		return sprintf("%.1f", $num);
	}
	return int($num+0.000001) if $num < 9999.9999;
	my (@syms) = qw(K M G T P E Z Y); 
	while(1) {
		$num /= 1000;
		if ($num < 10) {
			return sprintf("%.1f%s", $num, $syms[0]);
		} elsif ($num < 1000) {
			return sprintf("%d%s", $num, $sym[0]);
		} else {
			shift(@syms);
		}
	}
}

1;

__END__

=head1 NAME

 Devel::FileProfiler - quick & easy per-file statistical profiler

=head1 SYNOPSIS

 use Devel::FileProfile;

=head1 DESCRIPTION

Devel::FileProfile is a very simple statistical profiler.  Unlike
L<Devel::Profile>, it will not slow down the execution of your program
and it will not take forever to generate the profile results. 

On the other hand, the profile results are not nearly as detailed.

To use it, just C<use Devel::FileProfile> in any file you want
profiled.  When your program is done executing, it will dump a 
partial code-listing to STDERR with the percentage of time 
spent on each line annotated.  It does statistical sampling so
most lines won't be listed.  

The output format is:

 %%% line# code

For each line listed, several lines of the surrounding code are shown
to provide context.

There are many improvements that could be made to this module.  Feel
free to make them and send a patch to the author.  The module meets
the author's needs as is.  The code is very very simple.

=head1 BUGS

Devel::FileProfile uses C<$SIG{ALRM}>.  It is not currently 
compatabile with any other uses of C<$SIG{ALRM}>.  It potentially
could know about things like L<Event> and use them but it does
not currently do that.

=head1 AUTHOR

Copyright (C) 2007, David Muir Sharnoff <muir@idiom.com>
This module may be used and copied on the same terms as Perl
itself.

