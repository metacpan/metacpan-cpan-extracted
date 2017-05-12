#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Scalar::Util qw( blessed );
use Devel::StackTrace::Extract qw( extract_stack_trace );

test_dse( 'Moose::Exception', <<'PERL');
    die Moose::Exception->new( message => 'boom' );
PERL

test_dse( 'Exception::Class', <<'PERL');
    use Exception::Class('MyException');
    MyException->throw('boom');
PERL

test_dse( 'StackTrace::Auto', <<'PERL');
    package MyApp::Error;
    use Moo;
    with 'StackTrace::Auto';

    package main;
    die MyApp::Error->new;
PERL

test_dse( 'Throwable::Error', <<'PERL');
    package MyApp::Error2;
    use Moo;
    extends 'Throwable::Error';

    package main;
    MyApp::Error2->throw('boom');
PERL

test_dse( 'Mojo::Exception', <<'PERL');
    Mojo::Exception->throw('boom');
PERL

exit;

## no critic (ControlStructures::ProhibitUnreachableCode,BuiltinFunctions::ProhibitStringyEval)

########################################################################

# ideally this would have been written using 'state', but make this work
# on older perls
my $count;

sub test_dse {
    ## no critic (Modules::RequireExplicitInclusion)
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ## use critic

    my $required_class = shift;
    my $exception_src  = shift;
    my $name           = shift || "Testing $required_class exception";

    unless ( eval "use $required_class; 1" ) {
    SKIP: {
            skip "$required_class is not installed", 1;
        }
        return;
    }

    # create new package_name.
    $count ||= 0;
    $count++;
    my $package_name = 'DSETest::Support::Class' . $count;

    my $src = <<"PERL";
package $package_name;

sub foo {
    bar();
}

sub bar {
    baz();
}

sub baz () {
$exception_src
}

1;
PERL
    eval $src or die "Can't compile source: $@ \n\n$src";

    my $lineno;
    eval {
        $lineno = __LINE__ + 1;
        $package_name->foo;
        1;
    } && die 'Failed to get exception!';

    # note passing $@ into a function is a bad idea normally, but
    # I'm explicitly testing that this works here
    my $trace = extract_stack_trace($@);

    unless ( blessed($trace) && $trace->isa('Devel::StackTrace') ) {
        return isa_ok( $trace, 'Devel::StackTrace' );
    }

    my $frame = $trace->frame(-3);
    unless ( $frame->subroutine eq "${package_name}::foo" ) {
        return is( $frame->subroutine, "${package_name}::foo", $name );
    }
    unless ( $frame->package eq 'main' ) {
        return is( $frame->package, 'main', $name );
    }
    unless ( $frame->line == $lineno ) {
        return is( $frame->line, $lineno, $name );
    }

    $frame = $trace->frame(-4);
    unless ( $frame->subroutine eq "${package_name}::bar" ) {
        return is( $frame->subroutine, "${package_name}::bar", $name );
    }
    unless ( $frame->package eq $package_name ) {
        return is( $frame->package, $package_name, $name );
    }
    unless ( $frame->line == 4 ) {
        return is( $frame->line, 4, $name );
    }

    $frame = $trace->frame(-5);
    unless ( $frame->subroutine eq "${package_name}::baz" ) {
        return is( $frame->subroutine, "${package_name}::baz", $name );
    }
    unless ( $frame->package eq $package_name ) {
        return is( $frame->package, $package_name, $name );
    }
    unless ( $frame->line == 8 ) {
        return is( $frame->line, 8, $name );
    }

    ok( 1, $name );
}

