#!perl -w
use strict;
use Test::More tests => 8;
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

sub identical_to_native {
    my( $name, $expected,$decl ) = @_;
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
    my $got = $l->('foo','bar');
    my $native = $org ? $org->('foo','bar') : $expected;
    is $got, $expected, $name
        or do { diag $decl; diag $_ };
    is $expected, $native, "Sanity check vs native code";
}

identical_to_native( "Anonymous subroutine", 5, <<'SUB' );
#line 1
sub (
$name
    , $value
    ) {
        return __LINE__
    };
SUB

identical_to_native( "Anonymous subroutine (traditional)", 2, <<'SUB' );
#line 1
sub ($name, $value) {
    return __LINE__
};
SUB

identical_to_native( "Named subroutine", 6, <<'SUB' );
#line 1
sub foo2
(
  $name
, $value
) {
        return __LINE__
};
\&foo2
SUB

identical_to_native( "Multiline default assignments", 6, <<'SUB' );
#line 1
sub (
$name
    , $value
='bar'
    ) {
        return __LINE__
    };
SUB
