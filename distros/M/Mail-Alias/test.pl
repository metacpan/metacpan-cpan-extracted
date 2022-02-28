# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::Alias;
$loaded = 1;
print "ok 1\n";

$exit_status = 0;
sub good {
  print("ok $_[0]\n");
}

sub bad {
  print("not ok $_[0]\n");
  $exit_status++;
}

sub check {
  if ($_[1]) {
    &good($_[0]);
  }
  else {
    &bad($_[0]);
  }
}

# Insert your test code below 

my ($alias_obj);

print "Testing some of the Mail::Alias methods.........\n";

&check(2, $alias_obj = Mail::Alias->new(test_alias_file));

print "Setting the current alias file name\n";
($alias_obj->alias_file eq "test_alias_file") or die "Couldn't set the filename using MAIL::ALIAS";

print "Appending some aliases to the file\n";
&check(3, $alias_obj->append("test_alias3",
                             'person1@place1.com, person2@place2.net'));

print "Verifying the aliases were added\n";
&check(4, $alias_obj->exists("test_alias3"));

&check(5, $alias_obj->delete("test_alias3"));

print "Verifying alias with continuation line at end of file\n";
&check(6, $alias_obj = Mail::Alias::Sendmail->new(test_alias_file));

&check(7, $alias_obj->exists("test_alias4"));

print("Verifying that space after :include: works\n");
&check(8, ($alias_obj->expand("test_alias5"))[0] eq 'included@example.com');

exit $exit_status;
