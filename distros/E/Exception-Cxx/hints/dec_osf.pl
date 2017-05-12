package MY;

$self->{OPTIMIZE} =~ /-g/ and $debug=1;

$self->{CC}= "cxx -v";
$self->{LD}= "cxx -v";   # add cxx release dependent objects

sub const_config {
	my $out=shift->SUPER::const_config;
	$out=~s/^(LDDLFLAGS)(.*)-s/$1$2/m if $debug;  # remove -s for debugging
	$out;
}

sub c_o {
	my $out=shift->SUPER::c_o;

	# wish, joshua didn't call his C++ files .c. So we need to modify
	# our .c.o rule to tell cxx, that our .c files really are C++ source

	$out=~s/\$\*\.c/-x cxx \$*.c/;
	$out;
}

sub cflags {

	my $out=shift->SUPER::cflags(@_);
	#
	# DEC cxx5.5 doesn't know the -std flags, which we possibly used
	# to compile perl with cc. cxx 5.6 does.
	#
	$out=~s/-std//;             # cxx5.5-004 doesnt want this.
	$out;
}



