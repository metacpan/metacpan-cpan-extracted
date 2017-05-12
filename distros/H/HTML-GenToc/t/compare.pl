# compare two files
sub compare {
    my $file1 = shift;
    my $file2 = shift;

    return 0 unless (-f $file1);
    return 0 unless (-f $file2);

    my $fh1 = undef;
    my $fh2 = undef;
    open($fh1, $file1) || return 0;
    open($fh2, $file2) || return 0;

    my $res = 1;
    my $count = 0;
    while (<$fh1>)
    {
	$count++;
	my $comp1 = $_;
	# remove newline/carriage return (in case these aren't both Unix)
	$comp1 =~ s/\n//;
	$comp1 =~ s/\r//;

	my $comp2 = <$fh2>;

	# check if $fh2 has less lines than $fh1
	if (!defined $comp2)
	{
	    print "error - line $count does not exist in $file2\n  $file1 : $comp1\n";
	    close($fh1);
	    close($fh2);
	    return 0;
	}

	# remove newline/carriage return
	$comp2 =~ s/\n//;
	$comp2 =~ s/\r//;
	if ($comp1 ne $comp2)
	{
	    print "error - line $count not equal\n  $file1 : $comp1\n  $file2 : $comp2\n";
	    close($fh1);
	    close($fh2);
	    return 0;
	}
    }
    close($fh1);

    # check if $fh2 has more lines than $fh1
    if (defined($comp2 = <$fh2>))
    {
	$comp2 =~ s/\n//;
	$comp2 =~ s/\r//;
	print "error - extra line in $file2 : '$comp2'\n";
	$res = 0;
    }

    close($fh2);

    return $res;
}

1;
