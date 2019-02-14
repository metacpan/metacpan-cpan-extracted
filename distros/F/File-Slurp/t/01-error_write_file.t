use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTestOverride qw(trap_function_override_core);
use FileSlurpTest qw(temp_file_path trap_function);

# all of these names are synonyms
use File::Slurp qw(wf write_file overwrite_file append_file);
use Test::More;

plan tests => 108;

# possible failure points:
# 1. Can't open file due to bad path/permissions/whatever
# 2. Can't write to file due to bad permissions/whatever
# also, if in atomic write mode
# 1. Can't create new file "filename.$$" due to permissions/etc.
#   - We can't simulate this, unfortunately
# 2. Can't rename "filename.$$" to "filename" for whatever reason.

# each of the above cases should be tested in all three failure modes:
# 1. quiet (no warnings, exceptions, or content)
# 2. carp (warnings, no exceptions, no content)
# 3. croak (an exception, no warnings, no content)


# Simulate a bad open
{
    my $file = temp_file_path('gimme a nonexistent path');

    # first, write_file
    my ($res, $warn, $err) = trap_function(\&write_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'write_file: open error, quiet - no warn!');
    ok(!$err, 'write_file: open error, quiet - no exception!');
    ok(!$res, 'write_file: open error, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&write_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'write_file: open error, carp - got warn!');
    ok(!$err, 'write_file: open error, carp - no exception!');
    ok(!$res, 'write_file: open error, carp - no content!');
    ($res, $warn, $err) = trap_function(\&write_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'write_file: open error, croak - no warn!');
    ok($err, 'write_file: open error, croak - got exception!');
    ok(!$res, 'write_file: open error, croak - no content!');

    # the wf synonym
    ($res, $warn, $err) = trap_function(\&wf, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'wf: open error, quiet - no warn!');
    ok(!$err, 'wf: open error, quiet - no exception!');
    ok(!$res, 'wf: open error, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&wf, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'wf: open error, carp - got warn!');
    ok(!$err, 'wf: open error, carp - no exception!');
    ok(!$res, 'wf: open error, carp - no content!');
    ($res, $warn, $err) = trap_function(\&wf, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'wf: open error, croak - no warn!');
    ok($err, 'wf: open error, croak - got exception!');
    ok(!$res, 'wf: open error, croak - no content!');

    # the overwrite_file synonym
    ($res, $warn, $err) = trap_function(\&overwrite_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'overwrite_file: open error, quiet - no warn!');
    ok(!$err, 'overwrite_file: open error, quiet - no exception!');
    ok(!$res, 'overwrite_file: open error, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&overwrite_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'overwrite_file: open error, carp - got warn!');
    ok(!$err, 'overwrite_file: open error, carp - no exception!');
    ok(!$res, 'overwrite_file: open error, carp - no content!');
    ($res, $warn, $err) = trap_function(\&overwrite_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'overwrite_file: open error, croak - no warn!');
    ok($err, 'overwrite_file: open error, croak - got exception!');
    ok(!$res, 'overwrite_file: open error, croak - no content!');

    # the append_file pseudo-synonym (adds the atomic => 1 option)
    ($res, $warn, $err) = trap_function(\&append_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'append_file: open error, quiet - no warn!');
    ok(!$err, 'append_file: open error, quiet - no exception!');
    ok(!$res, 'append_file: open error, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&append_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'append_file: open error, carp - got warn!');
    ok(!$err, 'append_file: open error, carp - no exception!');
    ok(!$res, 'append_file: open error, carp - no content!');
    ($res, $warn, $err) = trap_function(\&append_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'append_file: open error, croak - no warn!');
    ok($err, 'append_file: open error, croak - got exception!');
    ok(!$res, 'append_file: open error, croak - no content!');
}

# Simulate a bad write
#  we do this by causing CORE::syswrite to fail by overriding it
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 36;

    my $file = temp_file_path(); # good filename, can open

    # write_file first
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&write_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'write_file: write error, quiet - no warn!');
    ok(!$err, 'write_file: write error, quiet - no exception!');
    ok(!$res, 'write_file: write error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&write_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'write_file: write error, carp - got warn!');
    ok(!$err, 'write_file: write error, carp - no exception!');
    ok(!$res, 'write_file: write error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&write_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'write_file: write error, croak - no warn!');
    ok($err, 'write_file: write error, croak - got exception!');
    ok(!$res, 'write_file: write error, croak - no content!');

    # now the wf synonym
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&wf, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'wf: write error, quiet - no warn!');
    ok(!$err, 'wf: write error, quiet - no exception!');
    ok(!$res, 'wf: write error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&wf, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'wf: write error, carp - got warn!');
    ok(!$err, 'wf: write error, carp - no exception!');
    ok(!$res, 'wf: write error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&wf, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'wf: write error, croak - no warn!');
    ok($err, 'wf: write error, croak - got exception!');
    ok(!$res, 'wf: write error, croak - no content!');

    # now the overwrite_file synonym
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&overwrite_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'overwrite_file: write error, quiet - no warn!');
    ok(!$err, 'overwrite_file: write error, quiet - no exception!');
    ok(!$res, 'overwrite_file: write error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&overwrite_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'overwrite_file: write error, carp - got warn!');
    ok(!$err, 'overwrite_file: write error, carp - no exception!');
    ok(!$res, 'overwrite_file: write error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&overwrite_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'overwrite_file: write error, croak - no warn!');
    ok($err, 'overwrite_file: write error, croak - got exception!');
    ok(!$res, 'overwrite_file: write error, croak - no content!');

    # the append_file pseudo-synonym (adds the atomic => 1 option)
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&append_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'append_file: write error, quiet - no warn!');
    ok(!$err, 'append_file: write error, quiet - no exception!');
    ok(!$res, 'append_file: write error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&append_file, $file, {err_mode => 'carp'}, 'junk');
    ok($warn, 'append_file: write error, carp - got warn!');
    ok(!$err, 'append_file: write error, carp - no exception!');
    ok(!$res, 'append_file: write error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&append_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'append_file: write error, croak - no warn!');
    ok($err, 'append_file: write error, croak - got exception!');
    ok(!$res, 'append_file: write error, croak - no content!');
    unlink $file, "$file.$$";
};

# Simulate a bad rename when in atomic mode.
#  we do this by causing CORE::rename to fail by overriding it
{
    my $file = temp_file_path(); # good filename, can open

    # write_file first
    my ($res, $warn, $err) = trap_function_override_core('rename', \&write_file, $file, {atomic => 1, err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'write_file: rename error, quiet - no warn!');
    ok(!$err, 'write_file: rename error, quiet - no exception!');
    ok(!$res, 'write_file: rename error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&write_file, $file, {atomic => 1, err_mode => 'carp'}, 'junk');
    ok($warn, 'write_file: rename error, carp - got warn!');
    ok(!$err, 'write_file: rename error, carp - no exception!');
    ok(!$res, 'write_file: rename error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&write_file, $file, {atomic => 1, err_mode => 'croak'}, 'junk');
    ok(!$warn, 'write_file: rename error, croak - no warn!');
    ok($err, 'write_file: rename error, croak - got exception!');
    ok(!$res, 'write_file: rename error, croak - no content!');
    unlink "$file.$$";

    # now the wf synonym
    ($res, $warn, $err) = trap_function_override_core('rename', \&wf, $file, {atomic => 1, err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'wf: rename error, quiet - no warn!');
    ok(!$err, 'wf: rename error, quiet - no exception!');
    ok(!$res, 'wf: rename error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&wf, $file, {atomic => 1, err_mode => 'carp'}, 'junk');
    ok($warn, 'wf: rename error, carp - got warn!');
    ok(!$err, 'wf: rename error, carp - no exception!');
    ok(!$res, 'wf: rename error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&wf, $file, {atomic => 1, err_mode => 'croak'}, 'junk');
    ok(!$warn, 'wf: rename error, croak - no warn!');
    ok($err, 'wf: rename error, croak - got exception!');
    ok(!$res, 'wf: rename error, croak - no content!');
    unlink "$file.$$";

    # now the overwrite_file synonym
    ($res, $warn, $err) = trap_function_override_core('rename', \&overwrite_file, $file, {atomic => 1, err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'overwrite_file: rename error, quiet - no warn!');
    ok(!$err, 'overwrite_file: rename error, quiet - no exception!');
    ok(!$res, 'overwrite_file: rename error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&overwrite_file, $file, {atomic => 1, err_mode => 'carp'}, 'junk');
    ok($warn, 'overwrite_file: rename error, carp - got warn!');
    ok(!$err, 'overwrite_file: rename error, carp - no exception!');
    ok(!$res, 'overwrite_file: rename error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&overwrite_file, $file, {atomic => 1, err_mode => 'croak'}, 'junk');
    ok(!$warn, 'overwrite_file: rename error, croak - no warn!');
    ok($err, 'overwrite_file: rename error, croak - got exception!');
    ok(!$res, 'overwrite_file: rename error, croak - no content!');
    unlink "$file.$$";

    # the append_file pseudo-synonym (adds the append => 1 option)
    ($res, $warn, $err) = trap_function_override_core('rename', \&append_file, $file, {atomic => 1, err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'append_file: rename error, quiet - no warn!');
    ok(!$err, 'append_file: rename error, quiet - no exception!');
    ok(!$res, 'append_file: rename error, quiet - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&append_file, $file, {atomic => 1, err_mode => 'carp'}, 'junk');
    ok($warn, 'append_file: rename error, carp - got warn!');
    ok(!$err, 'append_file: rename error, carp - no exception!');
    ok(!$res, 'append_file: rename error, carp - no content!');
    ($res, $warn, $err) = trap_function_override_core('rename', \&append_file, $file, {atomic => 1, err_mode => 'croak'}, 'junk');
    ok(!$warn, 'append_file: rename error, croak - no warn!');
    ok($err, 'append_file: rename error, croak - got exception!');
    ok(!$res, 'append_file: rename error, croak - no content!');
    unlink $file, "$file.$$";
}
