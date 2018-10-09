use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function trap_function_list_context);

# all three of these names are synonyms
use File::Slurp qw(rf slurp read_file);
use Test::More;

plan tests => 54;

# possible failure points:
# 1. Can't open file due to bad path/permissions/whatever
#    - easily simulated by asking the read_file function to open a file that
#      doesn't exist, and is nested far enough in a path that it can't be
#      created. /tmp exists, but opening /tmp/fake/path/whatever/file will fail

# each of the above cases should be tested in all three failure modes:
# 1. quiet (no warnings, exceptions, or content)
# 2. carp (warnings, no exceptions, no content) - has a problem in list context
# 3. croak (an exception, no warnings, no content)

# each of those scenarios should also be tested in list context (ugh, wantarray)

my $file = temp_file_path('gimme a nonexistent path');

# read_file errors
{
    my ($res, $warn, $err) = trap_function(\&read_file, $file, err_mode => 'quiet');
    ok(!$warn, 'read_file: bad path, quiet - no warn!');
    ok(!$err, 'read_file: bad path, quiet - no exception!');
    ok(!$res, 'read_file: bad path, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&read_file, $file, err_mode => 'carp');
    ok($warn, 'read_file: bad path, carp - got warn!');
    ok(!$err, 'read_file: bad path, carp - no exception!');
    ok(!$res, 'read_file: bad path, carp - no content!');
    ($res, $warn, $err) = trap_function(\&read_file, $file, err_mode => 'croak');
    ok(!$warn, 'read_file: bad path, croak - no warn!');
    ok($err, 'read_file: bad path, croak - got exception!');
    ok(!$res, 'read_file: bad path, croak - no content!');

    # same thing in list context
    ($res, $warn, $err) = trap_function_list_context(\&read_file, $file, err_mode => 'quiet');
    ok(!$warn, 'read_file: bad path, list context, quiet - no warn!');
    ok(!$err, 'read_file: bad path, list context, quiet - no exception!');
    ok(!@{$res}, 'read_file: bad path, list context, quiet - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&read_file, $file, err_mode => 'carp');
    ok($warn, 'read_file: bad path, list context, carp - got warn!');
    ok(!$err, 'read_file: bad path, list context, carp - no exception!');
    # I hate this decision to dump undef on the list. WHY OH WHY?!?!?!?!?!?!
    ok(@{$res}==1 && !defined($res->[0]), 'read_file: bad path, list context, carp - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&read_file, $file, err_mode => 'croak');
    ok(!$warn, 'read_file: bad path, list context, croak - no warn!');
    ok($err, 'read_file: bad path, list context, croak - got exception!');
    ok(!@{$res}, 'read_file: bad path, list context, croak - no content!');
}

# rf errors
{
    my ($res, $warn, $err) = trap_function(\&rf, $file, err_mode => 'quiet');
    ok(!$warn, 'rf: bad path, quiet - no warn!');
    ok(!$err, 'rf: bad path, quiet - no exception!');
    ok(!$res, 'rf: bad path, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&rf, $file, err_mode => 'carp');
    ok($warn, 'rf: bad path, carp - got warn!');
    ok(!$err, 'rf: bad path, carp - no exception!');
    ok(!$res, 'rf: bad path, carp - no content!');
    ($res, $warn, $err) = trap_function(\&rf, $file, err_mode => 'croak');
    ok(!$warn, 'rf: bad path, croak - no warn!');
    ok($err, 'rf: bad path, croak - got exception!');
    ok(!$res, 'rf: bad path, croak - no content!');

    # same thing in list context
    ($res, $warn, $err) = trap_function_list_context(\&rf, $file, err_mode => 'quiet');
    ok(!$warn, 'rf: bad path, list context, quiet - no warn!');
    ok(!$err, 'rf: bad path, list context, quiet - no exception!');
    ok(!@{$res}, 'rf: bad path, list context, quiet - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&rf, $file, err_mode => 'carp');
    ok($warn, 'rf: bad path, list context, carp - got warn!');
    ok(!$err, 'rf: bad path, list context, carp - no exception!');
    # I hate this decision to dump undef on the list. WHY OH WHY?!?!?!?!?!?!
    ok(@{$res}==1 && !defined($res->[0]), 'rf: bad path, list context, carp - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&rf, $file, err_mode => 'croak');
    ok(!$warn, 'rf: bad path, list context, croak - no warn!');
    ok($err, 'rf: bad path, list context, croak - got exception!');
    ok(!@{$res}, 'rf: bad path, list context, croak - no content!');
}

# slurp errors
{
    my ($res, $warn, $err) = trap_function(\&slurp, $file, err_mode => 'quiet');
    ok(!$warn, 'slurp: bad path, quiet - no warn!');
    ok(!$err, 'slurp: bad path, quiet - no exception!');
    ok(!$res, 'slurp: bad path, quiet - no content!');
    ($res, $warn, $err) = trap_function(\&slurp, $file, err_mode => 'carp');
    ok($warn, 'slurp: bad path, carp - got warn!');
    ok(!$err, 'slurp: bad path, carp - no exception!');
    ok(!$res, 'slurp: bad path, carp - no content!');
    ($res, $warn, $err) = trap_function(\&slurp, $file, err_mode => 'croak');
    ok(!$warn, 'slurp: bad path, croak - no warn!');
    ok($err, 'slurp: bad path, croak - got exception!');
    ok(!$res, 'slurp: bad path, croak - no content!');

    # same thing in list context
    ($res, $warn, $err) = trap_function_list_context(\&slurp, $file, err_mode => 'quiet');
    ok(!$warn, 'slurp: bad path, list context, quiet - no warn!');
    ok(!$err, 'slurp: bad path, list context, quiet - no exception!');
    ok(!@{$res}, 'slurp: bad path, list context, quiet - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&slurp, $file, err_mode => 'carp');
    ok($warn, 'slurp: bad path, list context, carp - got warn!');
    ok(!$err, 'slurp: bad path, list context, carp - no exception!');
    # I hate this decision to dump undef on the list. WHY OH WHY?!?!?!?!?!?!
    ok(@{$res}==1 && !defined($res->[0]), 'slurp: bad path, list context, carp - no content!');
    ($res, $warn, $err) = trap_function_list_context(\&slurp, $file, err_mode => 'croak');
    ok(!$warn, 'slurp: bad path, list context, croak - no warn!');
    ok($err, 'slurp: bad path, list context, croak - got exception!');
    ok(!@{$res}, 'slurp: bad path, list context, croak - no content!');
}
