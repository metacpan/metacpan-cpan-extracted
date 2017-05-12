#!./perl -w

use Test;
plan test => 4;
require Devel::Carp;
ok 1;

package Blur;
use overload ('""' => \&stringify);
sub stringify { Carp::confess "I have a headache" }

package Opaque;
use overload ('""' => \&stringify);
sub stringify { die "Don't bother me" }

package main;

my $warn;
$SIG{__WARN__} = sub { $warn = $_[0] };

{
    my $u = [];

    bless $u, Opaque;
    Carp::carp $u;
    ok $warn, '/bother/';

    $u = bless $u, Blur;
    Carp::carp "This is it:",$u;
    ok $warn, '/DIED/';

    check_long($u);
}

sub check_long {
    my ($o) = @_;
    Carp::cluck "okay?";
    ok $warn, '/DIED/';
}
