#
# $Id: spec.t,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = $ARGV[0] || 0;
BEGIN { plan tests => 5 };

use MacOSX::File::Spec;
ok(1); # If we made it this far, we're ok.

ref MacOSX::File::Spec->new($0) eq "MacOSX::File::Spec" ? ok(1) : ok(0);
$MacOSX::File::OSErr ? ok(0) : ok(1);		
$Debug and warn $MacOSX::File::OSErr;
defined  MacOSX::File::Spec->new("nonexistent") ? ok(0) : ok(1);
$MacOSX::File::OSErr ? ok(1) : ok(0);
if ($Debug){
    use MacOSX::File;
    warn MacOSX::File::strerr;
}
