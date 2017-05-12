#!/usr/local/bin/perl -w

use Test;
use Devel::TraceCalls;
use strict;

BEGIN { eval "use Time::HiRes qw( time )" }

##
## Create some other things in the FOO GLOB
##
## Using "FOO" instead of "foo" because the use of filehandle foo
## causes a "Unquoted string may clash with future reserved word"
## warning.
##
use vars qw( $FOO @FOO %FOO );
$FOO = "FOO scalar";
@FOO = ( "FOO array" );
%FOO = ( FOO => "FOO hash" );
open FOO, "<$0" or die "$!: $0";

## Now some test subs
sub FOO(;$$$) { "FOO" };
sub bar($) { "bar" };

my $FOO_proto = prototype "FOO";
my $FOO_ref = \&FOO;

{
    package Foo;

    sub FOO { "Foo::FOO" };
    sub bar { "Foo::bar" };

    package Bar;
    use vars qw( @ISA );
    @ISA = qw( Foo );

    sub baz { "Bar::baz/" . Foo::FOO };
    sub bat { "Bar::bat/" . Foo::bar };
}

my $t1;
my $t2;
my $start_time;
my $end_time;
my @calls1;
my @calls2;

my @tests = (
sub {
    eval { Devel::TraceCalls->new( "Blarney" ) };
    ## Old Test.pm versions do not grok qr//
    $@ =~ /not defined/
        ? ok 1
        : ok $@, "qr/not defined/", "Blarney (a non existant sub)" ;
},

sub {
    eval { Devel::TraceCalls->new( { Package => undef } ) };
    $@ =~ /Package/i
        ? ok 1
        : ok $@, "qr/Package/", "Devel::TraceCalls->new( { Package => undef }" ;
},

sub {
    eval { Devel::TraceCalls->new( { Package => "Blarney", Subs => [ "FOO" ] } ) };
    ## Old Test.pm versions do not grok qr//
    $@ =~ /not defined/
        ? ok 1
        : ok $@, "qr/not defined/", "Blarney, FOO (an empty package)" ;
},

sub {
    eval { Devel::TraceCalls->new( \"" ) };
    ## Old Test.pm versions do not grok qr//
    $@ =~ /Invalid/i
        ? ok 1
        : ok $@, "qr/Invalid/", "A bad parameter";
},

sub {
    ok FOO, "FOO"
},

sub {
    $t1 = Devel::TraceCalls->new( "FOO" );
    ok scalar $t1->_trace_points, 1;
},

sub {
    @calls1 = ();
    $t1 = Devel::TraceCalls->new( {
        Subs       => [ "FOO" ],
        LogTo      => \@calls1,
        CaptureAll => 1,
    } );
    ok scalar $t1->_trace_points, 1;
},

## Not sure why I am adding the the -1 and +1 here, but I do not ever
## want to fail these tests, and if the system clock is tweaked or there
## is some off-by-one problem...
sub {
    $start_time = time - 1;
    ok FOO( "bif", "pow" ), "FOO";
    $end_time   = time + 1;
},

sub {
    ok scalar @calls1, 1, "calls";
},

sub {
    ## Just making sure nothing got too corrupted to allow us to call
    ## it again.
    ok FOO, "FOO"
},

sub {
    undef $t1;
    ok FOO, "FOO"
},

sub { ok $start_time <= $calls1[0]->{CallTime},   1, "start <= Call"   },
sub { ok $end_time   >= $calls1[0]->{CallTime},   1, "end >= Call"     },
sub { ok $start_time <= $calls1[0]->{ReturnTime}, 1, "start <= Return" },
sub { ok $end_time   >= $calls1[0]->{ReturnTime}, 1, "end >= Return"   },
sub { ok join( ",", @{$calls1[0]->{Result}} ), "FOO", "Result" },
sub { ok join( ",", @{$calls1[0]->{Args}} ), "'bif','pow'", "Args" },
sub { ok scalar @{$calls1[0]->{Stack}}, 1, "Stack size" },
sub { ok $calls1[0]->{Stack}->[0]->[0], "main", "Stack" },
sub { ok $calls1[0]->{Stack}->[0]->[3], "main::__ANON__", "Stack" },

sub {
    $t1 = Devel::TraceCalls->new( "FOO", "bar" );
    ok scalar $t1->_trace_points, 2;
},

sub {
    @calls1 = ();
    $t1 = Devel::TraceCalls->new( {
        Package => "Foo",
        Subs    => [qw( FOO bar )],
        LogTo   => \@calls1,
    } );
    ok scalar $t1->_trace_points, 2;
},

sub {
    @calls1 = ();
    $t1 = Devel::TraceCalls->new( {
        Package => "Foo",
        LogTo   => \@calls1,
    } );
    ok scalar $t1->_trace_points, 2;
},

sub {
    @calls2 = ();
    $t2 = Devel::TraceCalls->new( {
        Package => "Bar",
        LogTo   => \@calls2,
    } );
    ok scalar $t1->_trace_points, 2;
},

sub {
    ok Bar::bat(), "Bar::bat/Foo::bar" ;
},

sub {
    ok scalar @calls1, 1;
},

## Make sure none of the optional crap is in there
(
    map {
        sub { ok ! exists $calls1[0]->{$_}, 1, "! exists $_" },
    } qw( CallTime ReturnTime Stack )
),

sub {
    ok scalar @calls2, 1;
},

##
## See if we messed up the glob.
##
sub { ok $FOO, "FOO scalar" },
sub { ok $FOO[0], "FOO array" },
sub { ok $FOO{FOO}, "FOO hash"},
sub { ok grep /FOO/, <FOO>; close \*FOO },
sub { ok FOO, "FOO" },
sub { ok prototype "FOO", $FOO_proto },
sub { ok \&FOO, $FOO_ref },
);

plan tests => scalar @tests;

$_->() for @tests;
