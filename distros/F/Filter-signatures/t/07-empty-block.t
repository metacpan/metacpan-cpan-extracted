#!perl -w
use strict;
use Test::More tests => 6;
use Data::Dumper;

require Filter::signatures;
# Mimic parts of the setup of Filter::Simple
my $extractor =
$Filter::Simple::placeholder = $Filter::Simple::placeholder
    = qr/\Q$;\E(.{4})\Q$;\E/s;

if( $^V >= 5.20 ) {
  require warnings; warnings->unimport('experimental::signatures');
  require feature; feature->import( 'signatures');
};

sub run_code_ok {
    my( $name, $expected,$decl, @args ) = @_;
    local $_ = $decl;
    my $org;
    if( $^V >= 5.20 ) {
        $org = eval $_
            or die $@;
    };
    Filter::signatures::transform_arguments();
    no warnings 'redefine';
    my $l = eval $_;
    die $@ if $@;
    my $got = $l->(@args);
    my $native = $org ? $org->(@args ): $expected;
    is $got, $expected, $name
        or do { diag $decl; diag $_ };
    is $expected, $native, "Sanity check vs native code";
}

run_code_ok( "No signature", undef, <<'SUB' );
#line 1
sub {}
SUB

run_code_ok( "Empty block", undef, <<'SUB' );
#line 1
sub () {}
SUB

run_code_ok( "Empty block with defaults", undef, <<'SUB' );
#line 1
sub ($name='batman') {}
SUB
