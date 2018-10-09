use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw(read_dir);
use Test::More;

plan tests => 18;

# possible failure points:
# 1. Can't open dir due to bad path/permissions/whatever
#    - easily simulated by asking the read_dir function to open a dir that
#      doesn't exist, and is nested far enough in a path that it can't be
#      created. /tmp exists, but opening /tmp/fake/path/whatever/dir will fail
# 2. Can't open dir because it's a file
#    - create a file, try to read_dir on it.
# each of the above cases should be tested in all three failure modes:
# 1. quiet (no warnings, exceptions, or content)
# 2. carp (warnings, no exceptions, no content)
# 3. croak (an exception, no warnings, no content)


# read_dir on bad path
{
    my $file = temp_file_path('gimme a nonexistent path');
    my ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'quiet');
    ok(!$warn, 'read_dir: bad path, quiet - no warn!');
    ok(!$err, 'read_dir: bad path, quiet - no exception!');
    ok(!$res, 'read_dir: bad path, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'carp');
    ok($warn, 'read_dir: bad path, carp - got warn!');
    ok(!$err, 'read_dir: bad path, carp - no exception!');
    ok(!$res, 'read_dir: bad path, carp - no content!');
    ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'croak');
    ok(!$warn, 'read_dir: bad path, croak - no warn!');
    ok($err, 'read_dir: bad path, croak - got exception!');
    ok(!$res, 'read_dir: bad path, croak - no content!');
}

# read_dir on file
{
    my $file = temp_file_path();
    File::Slurp::write_file($file, 'junk');
    my ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'quiet');
    ok(!$warn, 'read_dir: not dir, quiet - no warn!');
    ok(!$err, 'read_dir: not dir, quiet - no exception!');
    ok(!$res, 'read_dir: not dir, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'carp');
    ok($warn, 'read_dir: not dir, carp - got warn!');
    ok(!$err, 'read_dir: not dir, carp - no exception!');
    ok(!$res, 'read_dir: not dir, carp - no content!');
    ($res, $warn, $err) = trap_function(\&read_dir, $file, err_mode => 'croak');
    ok(!$warn, 'read_dir: not dir, croak - no warn!');
    ok($err, 'read_dir: not dir, croak - got exception!');
    ok(!$res, 'read_dir: not dir, croak - no content!');
    unlink $file;
}
