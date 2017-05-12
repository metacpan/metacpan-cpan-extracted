#!perl -d:SmallProf
# Yeah, it seems like a strange name, but : and - were causing problems for
# sub sub.

print "1..1\nok 1\n";  # Actual test done in part4

$DB::profile = 1;

sub check_for_invocation {
  my $a = 2;
}

check_for_invocation();
