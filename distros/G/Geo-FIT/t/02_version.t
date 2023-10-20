# t/02_version.t - test the profile version functions/methods
use strict;
use warnings;

use Test::More tests => 26;
use Geo::FIT;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

#
# Class functions and methods

# A -- called with arguments

my @versions;
@versions = qw( 21.72 21.94 21.115 );
for my $version (@versions) {

    # expected values
    my @expected_maj_min = split /\./, $version;
    my $expected_integer = join('', split /\./, $version);
    my $expected_string  = sprintf '%u.%03u', @expected_maj_min;
    $expected_integer = 2207 if $version eq '21.107';
    $expected_integer = 2215 if $version eq '21.115';
    # ... gets tricky with 3-digit minor versions
    # ....we can generalize the above line but let's just do that for now:

    # function -- internal

    my $integer = Geo::FIT::_profile_version_from_string( $version );
    is(	$integer, $expected_integer,                "   test _profile_version_from_string()");
    # NB: purpose of this function is to return an integer exactly as it would appear in a FIT file

    # profile_version() -- undocumented -- meant to accept both integer and string

    # -- list context
    my @major_minor;
    @major_minor= Geo::FIT->profile_version( $integer );
    is_deeply( \@major_minor , \@expected_maj_min,  "   test profile_version()");
    @major_minor= Geo::FIT->profile_version( $version );
    is_deeply( \@major_minor , \@expected_maj_min,  "   test profile_version()");

    # -- scalar context
    my $returned_integer;
    $returned_integer = Geo::FIT->profile_version( $integer );
    is(	$returned_integer, $expected_integer,       "   test profile_version()");
    $returned_integer = Geo::FIT->profile_version( $version );
    is(	$returned_integer, $expected_integer,       "   test profile_version()");

    # profile_version_string()

    my $returned_string = Geo::FIT->profile_version_string( $integer );
    is(	$returned_string, $expected_string,         "   test profile_version_string()");

    # should also be able to pass back string to _profile_version_from_string()
    $integer = Geo::FIT::_profile_version_from_string( $returned_string );
    is(	$integer, $expected_integer,                "   test _profile_version_from_string()");
}

# B -- called w/o arguments

my $version = '21.115';
# ... update this one each time we update $profile_current in FIT.pm

# expected values
my @expected_maj_min = split /\./, $version;
my $expected_integer = join('', split /\./, $version);
my $expected_string  = sprintf '%u.%03u', @expected_maj_min;
$expected_integer = 2207 if $version eq '21.107';
$expected_integer = 2215 if $version eq '21.115';

# profile_version() -- undocumented -- meant to accept both integer and string

# -- list context
my @major_minor;
@major_minor= Geo::FIT->profile_version();
is_deeply( \@major_minor , \@expected_maj_min,  "   test profile_version() -- w/o arguments");

# -- scalar context
my $returned_integer;
$returned_integer = Geo::FIT->profile_version();
is(	$returned_integer, $expected_integer,       "   test profile_version() -- w/o arguments");

# profile_version_string()

my $returned_string = Geo::FIT->profile_version_string();
is(	$returned_string, $expected_string,         "   test profile_version_string() -- w/o arguments");

#
# Object methods

# TODO: call profile_version_string() as object method before fetch_header is called (should croak)
# TODO: call profile_version_string() with argument (should croak)
# TODO: loop over a few files, ones with 2-digit minor and at least one with 3-digit minor
$o->file( 't/10004793344_ACTIVITY.fit' );
$o->open();
$o->fetch_header;

my $str = $o->profile_version_string;
is(	$str, '21.072',         "   test profile_version_string object method()");

$o->close();

print "so debugger doesn't exit\n";

