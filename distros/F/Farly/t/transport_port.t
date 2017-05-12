use strict;
use warnings;

use Test::Simple tests => 38;

use Farly::Transport::Port;
use Farly::Transport::PortGT;
use Farly::Transport::PortLT;
use Farly::Transport::PortRange;

my $p1 = Farly::Transport::Port->new("80");
my $p2 = Farly::Transport::Port->new("80");
my $p3 = Farly::Transport::Port->new("443");
my $p4 = Farly::Transport::Port->new("5060");

ok ( $p1->compare( $p1 ) == 0, "port compare equal");

ok ( $p1->compare( $p3 ) == -1, "port compare less than");

ok ( $p4->compare( $p3 ) == 1, "port compare greater than");

eval { my $p5 = Farly::Transport::Port->new("www"); };

ok ( $@ =~ /invalid port/, "invalid port www");

eval { my $p5 = Farly::Transport::Port->new(100000); };

ok ( $@ =~ /invalid port/, "invalid port 100000");

my $portRange0 = Farly::Transport::PortRange->new("1 65535");
my $portRange1 = Farly::Transport::PortRange->new("1-1024");
my $portRange2 = Farly::Transport::PortRange->new("1-1024");
my $portRange3 = Farly::Transport::PortRange->new("1024 65535");
my $portRange4 = Farly::Transport::PortRange->new("16384 32768");
my $portRange5 = Farly::Transport::PortRange->new("10000 20000");

ok( $portRange1->compare($portRange2) == 0, "range compare equal");
ok( $portRange2->compare($portRange3) == -1, "range compare lt");
ok( $portRange3->compare($portRange2) == 1, "range compare gt");
ok( $portRange1->compare($portRange0) == 1, "range compare larger first 1");
ok( $portRange3->compare($portRange4) == -1, "range compare larger first -1");

ok ( $portRange4->intersects($portRange3), "intersects 1");
ok ( $portRange4->intersects($portRange3), "intersects 2");
ok ( $portRange2->intersects($portRange3), "intersects 3");

#Ports
ok( $p1->equals($p2), "equals port port" );

ok( !$p1->equals($p3), "!equals port port" );

ok( $p2->contains($p1), "contains port port" );

ok ( $p1->as_string() eq "80", "as_string");

ok ( $portRange1->contains($p1), "range contains port");

ok ( !$portRange3->contains($p1), "! range contains port");

ok ( $portRange1->equals($portRange2), "range equals range");

ok ( $portRange3->contains($portRange4), "range contains range");

ok ( !$portRange4->contains($portRange3), "range not contains range");

ok( $p2->intersects($p1), "intersects" );

ok( ! $p1->intersects($p3), "!intersects" );

my $gt1 = Farly::Transport::PortGT->new(1024);

ok ( $gt1->equals($portRange3), "gt - high ports");

ok ( ! $gt1->contains($p3), "gt 1024 - contains 443");

ok ( $gt1->contains($p4), "gt 1024 - contains 5060");

ok ( $gt1->contains($portRange4), "gt 1024 - contains range");

ok ( $gt1->intersects($portRange4), "gt 1024 - intersects range");

ok ( $portRange0->contains($gt1), "port range contains gt");

my $lt1 = Farly::Transport::PortLT->new(1024);

ok ( $lt1->equals($portRange1), "lt equals low ports");

ok ( $lt1->contains($p3), "lt 1024 contains 443");

ok ( ! $lt1->contains($p4), "lt 1024 !contains 5060");

ok ( ! $lt1->contains($portRange4), "lt 1024 - contains range");

ok ( $lt1->intersects($portRange0), "lt 1024 - intersects range");

ok ( $portRange0->contains($lt1), "port range contains lt");

ok( $portRange4->compare($lt1) == 1, "compare range lt");

ok( $gt1->compare($portRange4) == -1, "compare gt range");
