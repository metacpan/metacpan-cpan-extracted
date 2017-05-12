# Something like this:

my $ccov=1;
push(@PREREQ, 'Devel::CCov' => 0.06) if $ccov;
my @CCOV = $ccov? 'ccov_registry.o':'';

sub MY::c_o {
    if ($ccov) {
	my @rules = split(m/( \. \w+ \$\(OBJ_EXT\) \: )/x,
			  shift->MY::SUPER::c_o(@_));
	shift @rules if $rules[0] !~ m/^\./;
	for (my $r=0; $r < @rules; $r += 2) {
	    if ($rules[$r] =~ m/^ \. (\w+) \$ /x) {
		my $prefix = $1;
		$rules[$r+1] =~ s{\$\*\.$prefix}{CCov/\$*.$prefix};
		my $CCOV = ('	@test -d CCov || mkdir CCov'."\n".
			    '	ccovinstrument -c $*.'.$prefix.' -o CCov/$*.'.$prefix.' -e CCov/$*.err'."\n");
		$rules[$r+1] =~ s/\n/\n$CCOV/;
	    }
	}
	push(@rules, '
ccov_registry$(OBJ_EXT): .ccov-timestamp
	ccovinstrument -r
	$(CCCMD) $(CCCDLFLAGS) $*.c
');
	join('', @rules);
    } else {
	shift->MY::SUPER::c_o(@_)
    }
}
