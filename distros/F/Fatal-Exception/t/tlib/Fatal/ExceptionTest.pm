package Fatal::ExceptionTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';
use Test::Assert ':all';

use Fatal::Exception;

# non-CORE functions from own package
sub sub_test1 {
    return shift();
};

# non-CORE functions outer own package
{
    package Fatal::ExceptionTest::Package1;
    sub sub_test2 {
        return shift();
    };
};

# Should be before import test. Test::Unit can't sort subs' names.
sub test____sane {
    local *FOO;

    my $file = __FILE__;

    eval 'open FOO, "<", "$file"';
    die if $@;
    assert_matches(qr/^package/, scalar(<FOO>));

    eval 'close FOO';
    die if $@;

    eval 'opendir FOO, "."';
    die if $@;

    eval 'close FOO';
    die if $@;

    eval 'sub_test1 undef';
    die if $@;

    eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
    die if $@;
};

sub test_import {
    my $self = shift;

    local *FOO;

    # empty args
    Fatal::Exception->import();
    Fatal::Exception->unimport();

    # not enough args
    assert_raises( ['Exception::Argument'], sub {
        Fatal::Exception->import("open");
    } );

    # not such exception
    assert_raises( ['Exception::Fatal'], sub {
        Fatal::Exception->import("Exception::Fatal::import::NotFound", "open");
    } );

    # not such function
    assert_raises( ['Exception::Argument'], sub {
        Fatal::Exception->import("Exception::Fatal", "notsuchfunction$^T$$");
    } );

    # first wrapping
    Exception::Base->import("Exception::Fatal::import::Test1");
    Fatal::Exception->import(
        "Exception::Fatal::import::Test1", "open", "sub_test1",
        "Fatal::ExceptionTest::Package1::sub_test2", ":void", "opendir"
    );

    my $file = __FILE__;
    eval 'open FOO, "<", "$file"';
    die if $@;
    assert_matches(qr/^package/, scalar(<FOO>));

    close FOO;

    # : too many args
    assert_raises( ['Exception::Argument'], sub {
        eval 'open 1, 2, 3, 4, 5';
        die if $@;
    } );

    # : wrapped void=0
    assert_raises( ['Exception::Fatal::import::Test1'], sub {
        eval 'open FOO, "<", "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=0 with fatal error
    assert_raises( ['Exception::Fatal'], sub {
        eval 'open FOO, "badmode", "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in array context
    assert_raises( ['Exception::Fatal::import::Test1'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in array context with fatal error
    assert_raises( ['Exception::Fatal'], sub {
        eval 'opendir \1, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in scalar context
    eval 'my $ret1 = opendir FOO, "/doesnotexists$^T$$"';
    die if $@;

    # : wrapped void=1 in scalar context with fatal error
    assert_raises( qr/^Not a GLOB/, sub {
        eval 'my $ret1 = opendir \1, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped non-core, our package
    assert_raises( ['Exception::Fatal::import::Test1'], sub {
        eval 'sub_test1 undef';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test1'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );

    # re-wrapping, another exception
    Exception::Base->import("Exception::Fatal::import::Test2");
    Fatal::Exception->import(
        "Exception::Fatal::import::Test2", "open", "sub_test1",
        "Fatal::ExceptionTest::Package1::sub_test2", ":void", "opendir"
    );

    # : wrapped void=0
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'open FOO, "<", "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in array context
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in scalar context
    eval 'my $ret1 = opendir FOO, "/doesnotexists$^T$$"';
    die if $@;

    # : wrapped non-core, our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'sub_test1 undef';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );

    # re-wrapping, the same exception
    Fatal::Exception->import(
        "Exception::Fatal::import::Test2", "open", "sub_test1",
        "Fatal::ExceptionTest::Package1::sub_test2", ":void", "opendir"
    );

    # : wrapped void=0
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'open FOO, "<", "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in array context
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in scalar context
    eval 'my $ret1 = opendir FOO, "/doesnotexists$^T$$"';
    die if $@;

    # : wrapped non-core, our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'sub_test1 undef';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );

    # un-wrap some functions
    Fatal::Exception->unimport("open", "sub_test1", ":void", "notexists$^T$$");

    # : un-wrapped
    eval 'open FOO, "<", "/doesnotexists$^T$$"';
    die if $@;

    # : un-wrapped
    eval 'sub_test1 undef';
    die if $@;

    # : wrapped
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );

    # un-wrap un-wrapped
    eval 'Fatal::Exception->unimport("open", "sub_test1", ":void", "notexists$^T$$")';

    # : un-wrapped
    eval 'open FOO, "<", "/doesnotexists$^T$$"';
    die if $@;

    # : un-wrapped
    eval 'sub_test1 undef';
    die if $@;

    # : wrapped
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );

    # re-wrapping un-wrapped
    Fatal::Exception->import(
        "Exception::Fatal::import::Test2", "open", "sub_test1",
        "Fatal::ExceptionTest::Package1::sub_test2", ":void", "opendir"
    );

    # : wrapped void=0
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'open FOO, "<", "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in array context
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'opendir FOO, "/doesnotexists$^T$$"';
        die if $@;
    } );

    # : wrapped void=1 in scalar context
    eval 'my $ret1 = opendir FOO, "/doesnotexists$^T$$"';
    die if $@;

    # : wrapped non-core, our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'sub_test1 undef';
        die if $@;
    } );

    # : wrapped non-core, not our package
    assert_raises( ['Exception::Fatal::import::Test2'], sub {
        eval 'Fatal::ExceptionTest::Package1::sub_test2 undef';
        die if $@;
    } );
};

1;
