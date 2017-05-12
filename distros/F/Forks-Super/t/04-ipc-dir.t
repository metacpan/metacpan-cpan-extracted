use Test::More tests => 16;
use Forks::Super ':test';
use strict;
use warnings;

mkdir "t/out/ipc.$$";

ok(tied $Forks::Super::IPC_DIR, "\$IPC_DIR is tied");
ok(!defined($Forks::Super::IPC_DIR) || ${^TAINT},
   "\$IPC_DIR is not defined")
  or diag("IPC_DIR is $Forks::Super::IPC_DIR, should be undef");

if ($ENV{IPC_DIR} && $ENV{IPC_DIR} eq 'undef') {
   SKIP: {
       skip "file IPC disabled by environment var", 14;
   };
   exit;
}

$Forks::Super::IPC_DIR = path("t/out/ipc.$$");

ok($Forks::Super::IPC_DIR =~ m:t/out/ipc.$$/.fhfork\S+:,
   "IPC directory set to .../.fhfork<nnn>");

ok(-d $Forks::Super::IPC_DIR, "temporary IPC dir created");

ok(-f "$Forks::Super::IPC_DIR/README.txt",
   "IPC_DIR initialized for use as IPC dir");

# see if we can clean up manually and cleanly

ok(unlink("$Forks::Super::IPC_DIR/README.txt"),
   "can delete file in temporary IPC directory");

ok(rmdir($Forks::Super::IPC_DIR),
   "can delete temporary IPC directory $!");

ok(rmdir("t/out/ipc.$$"),
   "can delete base directory after delete temporary directory $!");


# test a non-existent but createable directory

my $old = $Forks::Super::IPC_DIR;
$Forks::Super::IPC_DIR = path("t/out/new-ipc.$$");

ok($old ne $Forks::Super::IPC_DIR, "\$Forks::Super::IPC_DIR changed");
ok($Forks::Super::IPC_DIR =~ m!t/out/new-ipc.$$/.fhfork\S+!,
   "non-existent but createable IPC directory specified");
ok(-d $Forks::Super::IPC_DIR, "new IPC directory created");
ok(-f "$Forks::Super::IPC_DIR/README.txt",
   "new IPC directory initialized");
ok(unlink("$Forks::Super::IPC_DIR/README.txt"), "can delete file in IPC dir");
ok(rmdir($Forks::Super::IPC_DIR), "can delete IPC dir");
ok(rmdir("t/out/new-ipc.$$"), "can delete base dir after create temp IPC dir");

# test a non-existent and non-createable directory

$old = $Forks::Super::IPC_DIR;
$Forks::Super::IPC_DIR = path("t/out/ipc.1$$/ipc.2$$/ipc.3/ipc.4/ipc5");
ok($old eq $Forks::Super::IPC_DIR,
   "set \$IPC_DIR failed with invalid directory");

sub path {
    my $path = shift;
    if (${^TAINT}) {
	$path = Forks::Super::Util::abs_path($path);
	($path) = $path =~ /(.*)/;
    }
    return $path;
}

