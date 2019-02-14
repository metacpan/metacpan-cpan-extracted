use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTestOverride qw(trap_function_override_core);
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw(prepend_file);
use Test::More;

plan tests => 27;

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

# prepend_file reads in a file, edits the contents, writes the new file
# atomically to "foo.$$" then renames "foo.$$" to the original "foo"
# this leaves many failure steps to tend to

# step 1: read in the file. error simulated by asking it to read-in a
# nonexistent file
{
    # this one intentionally doesn't exist on a couple of paths. can't be created.
    my $file = temp_file_path('gimme a nonexistent path');
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, {err_mode => 'quiet'}, 'junk');
    ok(!$warn, 'prepend_file: read: err_mode opt quiet - no warn!');
    ok(!$err, 'prepend_file: read: err_mode opt quiet - no exception!');
    ok(!$res, 'prepend_file: read: err_mode opt quiet - no content!');
    ($res, $warn, $err) = trap_function(\&prepend_file, $file, {err_mode => 'carp'}, 'junk');
    like($warn, qr/read_file/, 'prepend_file: read: err_mode opt carp - got warn!');
    ok(!$err, 'prepend_file: read: err_mode opt carp - no exception!');
    ok(!$res, 'prepend_file: read: err_mode opt carp - no content!');
    ($res, $warn, $err) = trap_function(\&prepend_file, $file, {err_mode => 'croak'}, 'junk');
    ok(!$warn, 'prepend_file: read: err_mode opt croak - no warn!');
    like($err, qr/read_file/, 'prepend_file: read: err_mode opt croak - got exception!');
    ok(!$res, 'prepend_file: read: err_mode opt croak - no content!');
}

# step 2: Allow step 1 to pass, then write out the newly altered contents to a
# a file called "foo.$$". This write will fail by simulating a problem with
# CORE::GLOBAL::syswrite
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 9;
    # go ahead and setup an initial file so that it can be read during the test
    my $file = temp_file_path();
    File::Slurp::write_file($file, '');

    # step 1 will pass here, but step 2 will fail due to our simulation
    # overriding CORE::syswrite simulates a failure in writing to a file
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&prepend_file, $file, {err_mode => 'quiet'}, '');
    ok(!$warn, 'prepend_file: write: err_mode opt quiet - no warning!');
    ok(!$err, 'prepend_file: write: err_mode opt quiet - no exception!');
    ok(!$res, 'prepend_file: write: err_mode opt quiet - no content!');
    unlink "$file.$$";
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&prepend_file, $file, {err_mode => 'carp'}, '');
    like($warn, qr/write_file/, 'prepend_file: write: err_mode opt carp - got warning!');
    ok(!$err, 'prepend_file: write: err_mode opt carp - no exception!');
    ok(!$res, 'prepend_file: write: err_mode opt carp - no content!');
    unlink "$file.$$";
    ($res, $warn, $err) = trap_function_override_core('syswrite', \&prepend_file, $file, {err_mode => 'croak'}, '');
    ok(!$warn, 'prepend_file: write: err_mode opt croak - no warning!');
    like($err, qr/write_file/, 'prepend_file: write: err_mode opt croak - got exception!');
    ok(!$res, 'prepend_file: write: err_mode opt croak - no content!');
    unlink "$file.$$";
    # cleanup
    unlink $file;
};

# step 3: Allow steps 1 and 2 to pass, then rename the new file called "foo.$$"
# to the original "foo". This rename will fail by simulating a problem with
# CORE::GLOBAL::rename
{
    # go ahead and setup an initial file so that it can be read during the test
    my $file = temp_file_path();
    File::Slurp::write_file($file, '');

    # step 1 will pass here, but step 2 will fail due to our simulation
    # overriding CORE::syswrite simulates a failure in writing to a file
    my ($res, $warn, $err) = trap_function_override_core('rename', \&prepend_file, $file, {err_mode => 'quiet'}, '');
    ok(!$warn, 'prepend_file: rename: err_mode opt quiet - no warning!');
    ok(!$err, 'prepend_file: rename: err_mode opt quiet - no exception!');
    ok(!$res, 'prepend_file: rename: err_mode opt quiet - no content!');
    unlink "$file.$$";
    ($res, $warn, $err) = trap_function_override_core('rename', \&prepend_file, $file, {err_mode => 'carp'}, '');
    like($warn, qr/write_file/, 'prepend_file: rename: err_mode opt carp - got warning!');
    ok(!$err, 'prepend_file: rename: err_mode opt carp - no exception!');
    ok(!$res, 'prepend_file: rename: err_mode opt carp - no content!');
    unlink "$file.$$";
    ($res, $warn, $err) = trap_function_override_core('rename', \&prepend_file, $file, {err_mode => 'croak'}, '');
    ok(!$warn, 'prepend_file: rename: err_mode opt croak - no warning!');
    like($err, qr/write_file/, 'prepend_file: rename: err_mode opt croak - got exception!');
    ok(!$res, 'prepend_file: rename: err_mode opt croak - no content!');
    unlink "$file.$$";
    # cleanup
    unlink $file;
}
