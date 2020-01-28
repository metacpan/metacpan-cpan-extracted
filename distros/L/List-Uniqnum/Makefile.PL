use ExtUtils::MakeMaker;
use Config;

my $defines = '';

# For uniqnum() we distinguish between those builds for which
# $Config{nvsize} == $Config{ivsize} and those builds for which
# $Config{nvsize} != $Config{ivsize}
# Hence:

$defines .= " -DNVSIZE_EQUAL_IVSIZE"
  if $Config{nvsize} == $Config{ivsize};

# For uniqnum(), set $nvsize to be the size of the NV in bytes,
# excluding allocated but unused bytes.
# This will be the same as $Config{nvsize}, except for the 10-byte
# extended precision long double (for which $Config{nvsize} will report
# either 12 or 16):

my $nvsize = $Config{nvsize};

# Keep in mind that 8-byte long doubles can exist - for which
# $nvsize should remain at 8:

if($nvsize > 8 && $Config{nvtype} eq 'long double') {
  # Examine the length of sqrt 2.0 to determine whether we
  # have the extended precision 10-byte long double.
  # If so, amend $nvsize to 10.
  $nvsize = 10 if length sqrt 2.0 < 30;
}

# Now define USED_NV_BYTES (which is used by uniqnum) to the
# value of $nvsize

$defines .= " -DUSED_NV_BYTES=$nvsize";

print "DEFINES: $defines\n";


my %options = %{
{
  NAME => 'List::Uniqnum',
  LICENSE  => 'perl',
  VERSION_FROM => 'Uniqnum.pm',
  DEFINE   => $defines,
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }