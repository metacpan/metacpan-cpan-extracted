#!perl

use strict;
use warnings;

use Test::More;
use Test::Directory;
use Module::Runtime qw/use_module/;
use lib "t/inc";

use ExtUtils::BundleMaker;

my $dir = Test::Directory->new("t/inc");
my $bm  = ExtUtils::BundleMaker->new(
    modules => ["Test::WriteVariants"],
    target  => "t/inc/MyTWVBundle.pm",
    name    => "MyTWVBundle",
    recurse => "v5.14"
);
$bm->make_bundle();

$dir->has("MyTWVBundle.pm");
use_module("MyTWVBundle");

my %remaining_deps = (
    "File::Basename" => 0,
    "File::Spec"     => "3.00",
    "if"             => 0
);

my @provided_bundle = (
    "Data::Tumbler",       "Devel::InnerPackage", "Module::Pluggable", "Module::Pluggable::Object",
    "Test::WriteVariants", "Test::WriteVariants::Context"
);

my @required_order = (
    "Devel::InnerPackage",          "Module::Pluggable::Object", "Module::Pluggable", "Data::Tumbler",
    "Test::WriteVariants::Context", "Test::WriteVariants"
);

SKIP:
{
    ok( MyTWVBundle->can("remaining_deps"), "MyTWVBundle can remaining_deps" ) or skip( "Bogus conditions", 1 );
    my $have_remaining = MyTWVBundle->remaining_deps;
    my %check_remaining = map { $_ => $have_remaining->{$_} } grep { exists $remaining_deps{$_} } keys %$have_remaining;
    is_deeply( [ sort keys %check_remaining ], [ sort keys %remaining_deps ], "remaining deps heuristically ok" );
    ok( MyTWVBundle->can("provided_bundle"), "MyTWVBundle can provided_bundle" );
    is_deeply( [ sort keys %{ MyTWVBundle->provided_bundle } ], \@provided_bundle, "provided bundle ok" );
    ok( MyTWVBundle->can("required_order"), "MyTWVBundle can required_order" );
    # @required_order is finally tsorted - which doesn't provide a guaranteed order ...
    my $idx = 0;
    my %required_order = map { $_ => $idx++ } @{ MyTWVBundle->required_order };
    cmp_ok( $required_order{"Test::WriteVariants"}, ">", $required_order{"Test::WriteVariants::Context"}, "required order ok (Context)" );
    cmp_ok( $required_order{"Test::WriteVariants"}, ">", $required_order{"Data::Tumbler"}, "required order ok (Tumbler)" );
    cmp_ok( $required_order{"Test::WriteVariants"}, ">", $required_order{"Module::Pluggable"}, "required order ok (Module::Pluggable)" );
    cmp_ok( scalar keys %required_order, "==", scalar @required_order, "amount od entries in required order" );
}

done_testing();
