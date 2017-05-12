#!/usr/bin/perl -w

use strict;

my @files;
opendir DIR, 't';
while (defined(my $file = readdir DIR)) {
	next unless $file =~ /\.t$/;
	push @files, "t/$file";
}
closedir DIR;

system(qq!$^X -Ilib -e "use Test::Harness qw(&runtests \$verbose); runtests \@ARGV" @files!);

__END__

# If the Harness didn't work, we could just run our own cycle:

for my $file (@files) {
	system(qq!$^X -Ilib $file!);
}

