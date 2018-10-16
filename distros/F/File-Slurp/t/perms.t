use strict;
use warnings;

use IO::Handle ();
use Fcntl qw(:DEFAULT);
use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use FileSlurpTest qw(temp_file_path trap_function);
use File::Slurp;
use Test::More;

plan tests => 12;

{
    umask 0;
    my $file = temp_file_path();
    # the above file name isn't yet created

    # create with sysopen
    sysopen my $fh, $file, O_WRONLY | O_TRUNC | O_CREAT, 0666 or die $!;
    $fh->print("whatever");
    $fh->close();
    my $mode = _mode($file);
    unlink $file;

    # create it again with write_file
    my ($res, $warn, $err) = trap_function(\&write_file, $file, "whatever");
    ok($res, 'write_file: plain write - got a response');
    ok(!$warn, 'write_file: plain write - no warnings!');
    ok(!$err, 'write_file: plain write - no exceptions!');

    # check that the permissions match both ways
    is(_mode($file), $mode, 'write_file: plain write - default perms');
    unlink $file;
}

{
    umask 027; # test this with another umask
    my $file = temp_file_path();
    # the above file name isn't yet created

    # create with sysopen
    sysopen my $fh, $file, O_WRONLY | O_TRUNC | O_CREAT, 0666 or die $!;
    $fh->print("whatever");
    $fh->close();
    my $mode = _mode($file);
    unlink $file;

    # create it again with write_file
    my ($res, $warn, $err) = trap_function(\&write_file, $file, "whatever");
    ok($res, 'write_file: plain write - got a response');
    ok(!$warn, 'write_file: plain write - no warnings!');
    ok(!$err, 'write_file: plain write - no exceptions!');

    # check that the permissions match both ways
    is(_mode( $file ), $mode, 'write_file: plain write - default perms');
    unlink $file;
}

{
    umask 027;
    my $file = temp_file_path();
    # the above file name isn't yet created

    # create with sysopen
    sysopen my $fh, $file, O_WRONLY | O_TRUNC | O_CREAT, 0777 or die $!;
    $fh->print("whatever");
    $fh->close();
    my $mode = _mode($file);
    unlink $file;

    # create it again with write_file with permissions passed
    my ($res, $warn, $err) = trap_function(\&write_file, $file, {perms => 0777}, "whatever");
    ok($res, 'write_file: perms opt - got a response');
    ok(!$warn, 'write_file: perms opt - no warnings!');
    ok(!$err, 'write_file: perms opt - no exceptions!');

    # check that the permissions match both ways
    is(_mode($file), $mode, 'write_file: perms opt - got perms');
    unlink $file;
}

exit;

sub _mode {
    return 07777 & (stat $_[0])[2];
}
