use Config;

my ($dir) = @ARGV;
my $tmp = "tmp-$$";

foreach (glob("$dir/*.pl")) {
	print "Updating shebang for $_\n";
	open(I, "+<$_") || die $!;
	open(O, "+>$tmp") || die $!;
	my $line = <I>;
	chop $line;
	$line =~ s/^#!.*/$Config{'startperl'}/;
	print O "$line\n";
	print O join("", <I>);
	seek(I, 0, 0) || die $!;
	seek(O, 0, 0) || die $!;
	print I join("", <O>) || die $!;
	truncate(I, tell(I)) || die $!;
	close(O);
	close(I);
	chmod 0755, $_;
}

unlink $tmp;
