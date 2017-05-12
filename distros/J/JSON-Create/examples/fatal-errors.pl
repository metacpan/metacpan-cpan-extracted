#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
$jc->fatal_errors (1);
my $invalid_utf8 = "\x{99}\x{ff}\x{88}";
eval {
    $jc->run ($invalid_utf8);
};
if ($@) {
    print "Fatal error: $@\n";
}
