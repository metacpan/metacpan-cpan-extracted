######################### We start with some black magic to print on failure.


# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN {$| = 1; print "1..4\n"; }

sub Not {
  print "not ";
}

sub Ok {
  my($i) = @_;
  print "ok $i\n";
}
  
$i = 1;

################################################################

open EXEC, "./place-bac-ends -genomic t/X.4 -bac1 t/BACR06G02-TET3 -bac2 t/BACR06G02-T7 |" || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

print $output;
Not() if ($output ne $expected); Ok($i++);

################################################################

open EXEC, "./place-bac-ends -genomic t/X.2 -bac1 t/BACR22I24-TET3 -bac2 t/BACR22I24-T7 |" || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

print $output;
Not() if ($output ne $expected); Ok($i++);

################################################################

open EXEC, "./place-bac-ends -genomic t/X.7 -bac1 t/BACR02B03-TET3 -bac2 t/BACR02B03-T7 |" || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

print $output;
Not() if ($output ne $expected); Ok($i++);

################################################################

open EXEC, "./place-bac-ends -genomic t/3R.4 -bac1 t/BACR02B19-TET3 -bac2 t/BACR02B19-T7 |" || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

print $output;
Not() if ($output ne $expected); Ok($i++);


