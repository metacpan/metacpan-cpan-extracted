use Test::More;
use strict;
use warnings;
use File::Basename;
use Cwd;
require "./t/80-multi-tests.pl";

# 83-multihost.t: content for a directory with a process
#     on a remote host. To properly test this, you must
#
#     1. have unpacked this distribution in a directory
#        on a shared (networked) filesystem
#     2. have specified the environment variable  REMOTE_HOST.
#        REMOTE_HOST is the name of another host in this
#        cluster that also has access to the shared filesystem
#        that hosts the current directory
#     3. be able to ssh into REMOTE_HOST without a password
#
# i.e., the following code should be expected to "work"
#
#    $REMOTE = $ENV{REMOTE_HOST};
#    $CWD = Cwd::abs_path();
#    system("ssh $REMOTE 'cd $CWD ; perl -Iblib/lib t/80b-multi.tt'");
#

my $base = Cwd::abs_path();
my $REMOTE_HOST = $ENV{REMOTE_HOST};
if (!$REMOTE_HOST) {
    diag "REMOTE_HOST not specified. Skipping this test.";
    diag "See the source of  t/83-multihost.t  for the";
    diag "requirements to run this test.";
    ok(1, "# skip multihost test, REMOTE_HOST not specified");
    done_testing;
    exit;
}

my $fa = "$base/t/83a-$$.out";
my $fb = "$base/t/83b-$$.out";

unlink $fa,$fb;

my $mdfile = $ENV{MULTI_DIR_FILE} = "t/83-$$.dir";

if (fork() == 0) {
    $ENV{MULTI_DIR_OUTPUT} = $fa;
    exit system($^X, "-Iblib/lib", "-Ilib", "t/80a-multi.tt") >> 8;
}
if (fork() == 0) {
    exit system(
        "ssh $REMOTE_HOST 'cd $base ;
         MULTI_DIR_FILE=$mdfile MULTI_DIR_OUTPUT=$fb $^X -Iblib/lib -Ilib t/80b-multi.tt'") >> 8;
}
wait;
wait;
ok_multi( $fa, $fb );

done_testing;
unlink $fa,$fb;

