use Forks::Super ':test', 'pmap', 'pgrep';
use Test::More tests => 8;
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

# exercise pmap, pgrep functions

my @a1 = map { $_ } 1..10;
my @a2 = pmap { $_ } 1..10;
ok(Dumper(\@a1) eq Dumper(\@a2), 'pmap simple');

my @b1 = map { $_ ** 3 } 1..10;
my @b2 = pmap { srand($$); select undef,undef,undef,0.25*rand; $_ ** 3 } 1..10;
ok(Dumper(\@b1) eq Dumper(\@b2), 'pmap out of order');

my $sub_c = sub {
    my $self = { id => $_[0] };
    bless $self, "XXXX"
};
my @c1 = map { $sub_c->($_) } 1..15;
my @c2 = pmap { $sub_c->($_) } 1..15;
ok(Dumper(\@c1) eq Dumper(\@c2), 'pmap blessed references');

my @d1 = grep { /4/ } 1..60;
my @d2 = pgrep { /4/ } 1..60;
ok(Dumper(\@d1) eq Dumper(\@d2), 'pgrep simple')
    or diag "[@d1] [@d2]";

my @e1 = grep { /6/ } 1..100;
my @e2 = pgrep { srand($$); select undef,undef,undef,0.25*rand; /6/ } 1..100;
ok(Dumper(\@e1) eq Dumper(\@e2), 'pgrep out of order')
    or diag "[@e1] [@e2]";

my @o1 = map { bless { foo => $_, bar => $_*$_ }, "YYZZ$_" } 1..50;
my @o2 = pmap { bless { foo => $_, bar => $_*$_ }, "YYZZ$_" } 1..50;
ok( Dumper(\@o1) eq Dumper(\@o2), 'create objects with pmap' );

my @p1 = grep { $_->{foo} =~ /[47]/ } @o1;
my @p2 = pgrep { $_->{foo} =~ /[47]/ } @o2;
ok(Dumper(\@p1) eq Dumper(\@p2), 'filter objects with pmap');

my $q1 = grep { /5/ } 1..105;
my $q2 = pgrep { /5/ } 1..105;
ok($q1 == $q2, 'pgrep scalar context');

