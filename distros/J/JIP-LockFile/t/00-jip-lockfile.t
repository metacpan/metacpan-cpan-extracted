#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Temp;
use English qw(-no_match_vars);

BEGIN {
    plan tests => 12;

    use_ok 'JIP::LockFile', '0.062';
};

my $NEED_TMP_FILE = 1;

subtest 'Require some module' => sub {
    plan tests => 1;

    require_ok 'JIP::LockFile';

    diag(
        sprintf(
            'Testing JIP::LockFile %s, Perl %s, %s',
            $JIP::LockFile::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new()' => sub {
    plan tests => 7;

    eval { JIP::LockFile->new };
    if ($EVAL_ERROR) {
        like $EVAL_ERROR, qr{Mandatory \s argument \s "lock_file" \s is \s missing}x;
    }

    eval { JIP::LockFile->new(lock_file => undef) };
    if ($EVAL_ERROR) {
        like $EVAL_ERROR, qr{Bad \s argument \s "lock_file"}x;
    }

    eval { JIP::LockFile->new(lock_file => q{}) };
    if ($EVAL_ERROR) {
        like $EVAL_ERROR, qr{Bad \s argument \s "lock_file"}x;
    }

    my $obj = init_obj();
    ok $obj, 'got instance of JIP::LockFile';

    isa_ok $obj, 'JIP::LockFile';

    can_ok $obj, qw(new lock_file lock try_lock unlock is_locked error);

    is $obj->lock_file, $EXECUTABLE_NAME;
};

subtest 'not is_locked() at startup' => sub {
    plan tests => 1;

    cmp_ok init_obj()->is_locked, q{==}, 0;
};

subtest 'unlock on non-is_locked() changes nothing' => sub {
    plan tests => 2;

    is ref(init_obj()->unlock), 'JIP::LockFile';
    cmp_ok init_obj()->is_locked, q{==}, 0;
};

subtest 'lock()' => sub {
    plan tests => 5;

    my $obj = init_obj($NEED_TMP_FILE);

    is ref($obj->lock), 'JIP::LockFile';
    cmp_ok $obj->is_locked, q{==}, 1;

    # Re-locking changes nothing
    is ref($obj->lock), 'JIP::LockFile';
    cmp_ok $obj->is_locked, q{==}, 1;

    is_deeply $obj->get_lock_data, {
        pid             => $PROCESS_ID,
        executable_name => $EXECUTABLE_NAME,
    };
};

subtest 'unlock()' => sub {
    plan tests => 3;

    my $obj = init_obj($NEED_TMP_FILE)->lock;

    ok -f $obj->lock_file;

    $obj->unlock;

    cmp_ok $obj->is_locked, q{==}, 0;
    ok not -f $obj->lock_file;
};

subtest 'unlocking on scope exit' => sub {
    plan tests => 1;

    my $lock_file;

    {
        my $obj = init_obj($NEED_TMP_FILE);
        $lock_file = $obj->lock_file;
        $obj->lock;
    }

    ok not -f $lock_file;
};

subtest 'Lock or raise an exception' => sub {
    plan tests => 4;

    my $obj = init_obj($NEED_TMP_FILE)->lock;

    my $lock_file        = quotemeta $obj->lock_file;
    my $lock_file_quoted = $lock_file;

    my $concurrent_obj = JIP::LockFile->new(lock_file => $obj->lock_file);

    is $concurrent_obj->error, undef;

    eval {
        $concurrent_obj->lock;
    };
    if ($EVAL_ERROR) {
        my $last_error = quotemeta $OS_ERROR;

        like $EVAL_ERROR, qr{
            ^Can't \s lock \s "$lock_file_quoted":
            \s
            $last_error
            \s
        }x;
    }

    is $concurrent_obj->error, $OS_ERROR;

    is_deeply $obj->get_lock_data, $concurrent_obj->get_lock_data;
};

subtest 'try_lock()' => sub {
    plan tests => 7;

    my $obj       = init_obj($NEED_TMP_FILE)->try_lock;
    my $lock_file = $obj->lock_file;

    # Re-locking changes nothing
    cmp_ok $obj->try_lock->is_locked, q{==}, 1;

    my $concurrent_obj = JIP::LockFile->new(lock_file => $obj->lock_file);

    is $concurrent_obj->error, undef;

    # Or just return undef
    is($concurrent_obj->try_lock, undef);

    is $concurrent_obj->error, $OS_ERROR;

    is_deeply $obj->get_lock_data, {
        pid             => $PROCESS_ID,
        executable_name => $EXECUTABLE_NAME,
    };

    is_deeply $obj->get_lock_data, {
        pid             => $PROCESS_ID,
        executable_name => $EXECUTABLE_NAME,
    };

    is_deeply $obj->get_lock_data, $concurrent_obj->get_lock_data;
};

subtest 'get_lock_data() before lock' => sub {
    plan tests => 1;

    my $obj = init_obj($NEED_TMP_FILE);

    is $obj->get_lock_data, undef;
};

subtest 'get_lock_data() after lock' => sub {
    plan tests => 1;

    my $obj = init_obj($NEED_TMP_FILE)->try_lock;

    is_deeply $obj->get_lock_data, {
        pid             => $PROCESS_ID,
        executable_name => $EXECUTABLE_NAME,
    };
};

sub init_obj {
    my ($need_tmp_file) = @ARG;

    my $lock_file
        = $need_tmp_file
        ? File::Temp->new->filename
        : $EXECUTABLE_NAME;

    return JIP::LockFile->new(lock_file => $lock_file);
}

