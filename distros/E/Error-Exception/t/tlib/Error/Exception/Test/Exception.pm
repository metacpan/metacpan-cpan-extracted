# Copyright (C) 2008 Stephen Vance
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
# 
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
# 
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package Error::Exception::Test::Exception;

use strict;
use warnings;

use Cwd qw( getcwd abs_path );
use Error::Exception::Test::Helper::TestExceptions;
use File::Basename;
use File::Spec::Functions;
use Module::Locate;

use base qw( Test::Unit::TestCase );

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {

    return;
}

sub tear_down {

    return;
}

sub test_stringify_no_fields {
    my $self = shift;

    my $exname = 'Error::Exception::Test::NoFields';

    # The following statements MUST be on the same line
    my $ex = $exname->new(); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n",
        $string
    );

    return;
}

sub test_stringify_empty_message {
    my $self = shift;

    my $exname = 'Error::Exception::Test::NoFields';

    # The following statements MUST be on the same line
    my $ex = $exname->new( -text => "" ); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n",
        $string
    );

    return;
}

sub test_stringify_real_message {
    my $self = shift;

    my $exname = 'Error::Exception::Test::NoFields';
    my $msg = 'This is a test message';

    # The following statements MUST be on the same line
    my $ex = $exname->new( -text => $msg ); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n"
            . "with message <<$msg>>\n",
        $string
    );

    return;
}

sub test_stringify_string_field {
    my $self = shift;

    my $exname = 'Error::Exception::Test::OneField';
    my $field = 'firstfield';
    my $value = 'SomePackage';

    # The following statements MUST be on the same line
    my $ex = $exname->new( $field => $value ); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n"
            . "with fields:\n"
            . "\t$field = '$value'\n",
        $string
    );

    return;
}

sub test_stringify_undef_field {
    my $self = shift;

    my $exname = 'Error::Exception::Test::OneField';
    my $field = 'firstfield';
    my $value = undef;

    # The following statements MUST be on the same line
    my $ex = $exname->new( $field => $value ); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n"
            . "with fields:\n"
            . "\t$field = 'undef'\n",
        $string
    );

    return;
}

sub test_stringify_arrayref_field {
    my $self = shift;

    my $exname = 'Error::Exception::Test::OneField';
    my $field = 'firstfield';
    my $value = [ 'First line', 'Second line', 'Third line' ];

    # The following statements MUST be on the same line
    my $ex = $exname->new( $field => $value ); my $line = __LINE__;

    $self->assert( $ex->isa( 'Error::Exception' ) );

    my $string = scalar $ex;

    $self->assert_equals(
        "$exname thrown in "
            . __FILE__
            . " at line "
            . $line
            . "\n"
            . "with fields:\n"
            . "\t$field = '[ "
            . join( "\n", @{$value} )
            . " ]'\n",
        $string
    );

    return;
}

sub test_uncaught_exception {
    my $self = shift;

    my $script = $self->_get_test_data_file_name(
        __PACKAGE__,
        'uncaught_test.pl'
    );

    # Set up the include path to include Error::Exception
    my $incdir = dirname( dirname( dirname( dirname(
        $self->_get_package_dir( 'Error::Exception::Test::Helper::TestExceptions' )
    ) ) ) );
    my @output = `$^X -I "$incdir" "$script" 2>&1`;
    my $retval = $?;
    $self->assert_not_equals( 0, $retval,
        "$script invocation succeeded unexpectedly ($retval)"
    );

    $self->assert_equals( 0, scalar grep( /Died/, @output ) );

    $self->assert_matches(
        qr/\AError::Exception::Test::NoFields thrown in /,
        $output[0],
    );

    return;
}

sub test_uncaught_exception_testunit {
    my $self = shift;

    my $testrunner = catfile(
        dirname( Module::Locate::locate( 'Test::Unit' ) ),
        'TestRunner.pl'
    );

    $self->assert( -f $testrunner, 'Could not find TestRunner.pl' );

    my $testclass = 'Error::Exception::Test::Helper::UncaughtTest';

    # Set up the include path to include Error::Exception
    my $incdir = dirname( dirname( dirname( dirname(
        $self->_get_package_dir( 'Error::Exception::Test::Helper::TestExceptions' )
    ) ) ) );
    my @output = `$^X -I $incdir $testrunner $testclass`;

    $self->assert_equals( 0, scalar grep( /Died/, @output ) );

    $self->assert_equals( 1, scalar grep( /\AThere was 1 error:/, @output ) );

    $self->assert_matches(
        qr/\AError::Exception::Test::NoFields thrown in /,
        $output[9],
        "Got $output[9]"
    );

    return;
}

# PRIVATE METHODS

sub _get_package_dir {
    my ($self, $package) = @_;

    my $loc = Module::Locate::locate( $package );
    $self->assert_not_equals( '', $loc, "Failed to get test package" );

    my $path = abs_path( $loc );
    my $parentdir = dirname( $path );

    $self->assert( -d $parentdir,
                    "Package directory $parentdir does not exist" );

    return $parentdir;
}

sub _get_test_data_dir {
    my ($self, $package) = @_;

    my $parentdir = $self->_get_package_dir( $package );
    my $datadir = catfile( $parentdir, 'data' );
    $self->assert( -d $datadir, "Test data dir $datadir does not exist" );

    return $datadir;
}

sub _get_test_data_file_name {
    my ($self, $package, $filename) = @_;

    my $dir = $self->_get_test_data_dir( $package );

    my $path = catfile( $dir, $filename );
    $self->assert( -f $path, "Test data file $path does not exist" );

    return $path;
}

1;
