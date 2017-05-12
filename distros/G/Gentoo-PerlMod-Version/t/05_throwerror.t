use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Gentoo::PerlMod::Version qw( gentooize_version );
use Gentoo::PerlMod::Version::Error;

use Scalar::Util qw( refaddr );

my $config = { foo => 1 };

subtest perlver_undefined => sub {
  my $result = exception { gentooize_version( undef, $config ) };
  isnt( $result, undef, 'Exception Get' );
  is( $result->{code}, 'perlver_undefined', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  is( refaddr $config , refaddr $result->{config}, 'config passthrough' );
  note("$result");
};

subtest bad_char => sub {
  my $result = exception { Gentoo::PerlMod::Version::_code_for( chr(128) ) };
  isnt( $result, undef, 'Exception Get' );
  is( $result->{code}, 'bad_char', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  note("$result");
};

done_testing;
