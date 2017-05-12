BEGIN {
   unless (exists $SIG{USR1}) {
      print <<EOF;
1..0 # SKIP Broken perl detected, skipping tests.
EOF
      exit 0;
   }
}

$| = 1; print "1..24\n";

use EV;

print "ok 1\n";

EV::signal USR1 => sub { print "not ok 2\n" };

print "ok 2\n";

my $usr2 = EV::signal USR2 => sub { print "ok 10\n" };

print "ok 3\n";

my $loop = new EV::Loop;

print "ok 4\n";

my $usr1_0 = $loop->signal (USR1 => sub { print "not ok 8\n" });
my $usr1_1 = $loop->signal (USR1 => sub { print "ok 8\n"; $_[0]->stop });
my $usr1_2 = $loop->signal (USR1 => sub { print "not ok 8\n" });

print "ok 5\n";

kill USR1 => $$;
kill USR2 => $$;

print "ok 6\n";

undef $usr1_0;
undef $usr1_2;

print "ok 7\n";

$loop->run;

print "ok 9\n";

EV::run (EV::RUN_ONCE);

print "ok 11\n";

$usr2 = EV::signal USR2 => sub { print "ok 13\n" };
$usr1_0 = EV::signal USR1 => sub { print "ok 15\n" };

print "ok 12\n";

kill USR2 => $$;

EV::run (EV::RUN_NOWAIT);

print "ok 14\n";

kill USR1 => $$;

EV::run (EV::RUN_NOWAIT);

print "ok 16\n";

my $sig = $loop->signal (INT => sub { });

print "ok 17\n";

print eval { $loop->signal (USR2 => sub { }); 1 } ? "not " : "", "ok 18 # $@\n";
print eval { $sig->set ("USR2"); 1 } ? "not " : "", "ok 19 # $@\n";
$sig = $loop->signal (INT => sub { });
print eval { $sig->signal ("USR2"); 1 } ? "not " : "", "ok 20 # $@\n";
print eval { $sig->signal ("USR2"); 1 } ? "" : "not ", "ok 21 # $@\n"; # now inactive
print eval { $sig->start; 1 } ? "not " : "", "ok 22 # $@\n";
print eval { $sig->signal ("USR2"); 1 } ? "" : "not ", "ok 23 # $@\n"; # now inactive
$sig->signal ("INT");
print eval { $sig->start; 1 } ? "" : "not ", "ok 24 # $@\n";

