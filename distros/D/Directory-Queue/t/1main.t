#!perl

use strict;
use warnings;
use Directory::Queue::Normal qw();
use Directory::Queue::Null qw();
use Directory::Queue::Simple qw();
use Encode;
use File::Temp qw(tempdir);
use Test::More tests => 15;

our($tmpdir);

sub test_new ($%) {
    my($type, %option) = @_;
    my($optstr, $dq);

    $option{type} = $type;
    $optstr = join(", ", map("$_ => $option{$_}", sort(keys(%option))));
    $option{path} = "$tmpdir/$type";
    $dq = Directory::Queue->new(%option);
    isa_ok($dq, "Directory::Queue", "Directory::Queue->new($optstr)");
}

$tmpdir = tempdir(CLEANUP => 1);

foreach my $type (qw(Normal Null Simple)) {
    test_new($type);
    test_new($type, rndhex => 13);
    test_new($type, umask => 077);
    test_new($type, maxtemp => 1234567);
    test_new($type, maxlock => 0);
}
