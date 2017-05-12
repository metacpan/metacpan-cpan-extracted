#!perl -T

use Test::More tests => 3;
use FrameNet::QueryData;

my $fnhome = (defined $ENV{'FNHOME'} ? $ENV{'FNHOME'} : "$ENV{'PWD'}/t/FrameNet-test");

note("Using $fnhome as \$FNHOME");

my $qd = FrameNet::QueryData->new('-cache' => 0,
				  '-fnhome' => $fnhome);

SKIP: {
    skip "\$FNHOME is not set", 3 if (! defined $ENV{'FNHOME'});

    ok($qd->path_related("Communication", "Topic", "Using"), 
       "Communication -> Using -> Topic");
    ok(! $qd->path_related("Communication", "Topic", "Inheritance"),
       "! Communication -> Inheritance -> Topic");
    ok($qd->path_related("Communication", "Intentionally_create", "Using", "Inheritance"),
       "Communication -> Using -> Inheritance -> Intentionally_create");


}
