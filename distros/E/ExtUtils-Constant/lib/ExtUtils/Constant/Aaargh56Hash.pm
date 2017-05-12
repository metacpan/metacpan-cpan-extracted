package ExtUtils::Constant::Aaargh56Hash;
# A support module (hack) to provide sane Unicode hash keys on 5.6.x perl
use strict;
require Tie::Hash;
use vars '@ISA';
@ISA = 'Tie::StdHash';

#my $a;
# Storing the values as concatenated BER encoded numbers is actually going to
# be terser than using UTF8 :-)
# And the tests are slightly faster. Ops are bad, m'kay
sub to_key {pack "w*", unpack "U*", ($_[0] . pack "U*")};
sub from_key {defined $_[0] ? pack "U*", unpack 'w*', $_[0] : undef};

sub STORE    { $_[0]->{to_key($_[1])} = $_[2] }
sub FETCH    { $_[0]->{to_key($_[1])} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; from_key (each %{$_[0]}) }
sub NEXTKEY  { from_key (each %{$_[0]}) }
sub EXISTS   { exists $_[0]->{to_key($_[1])} }
sub DELETE   { delete $_[0]->{to_key($_[1])} }

#END {warn "$a accesses";}
1;
