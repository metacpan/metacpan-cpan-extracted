use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Gentoo::PerlMod::Version::Error;

use Scalar::Util qw( refaddr );

{
  no warnings 'redefine';
  my $code = sub {
    return $_[0];
  };
  no strict 'refs';
  *{'Gentoo::PerlMod::Version::Error::_fatal'} = $code;
}

my $result;
my $config = { foo => 1 };

subtest perlver_undefined => sub {
  $result = Gentoo::PerlMod::Version::Error::perlver_undefined($config);
  is( $result->{code}, 'perlver_undefined', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  is( refaddr $config , refaddr $result->{config}, 'config passthrough' );
};

subtest matches_trial_regex_nonlax => sub {
  $result = Gentoo::PerlMod::Version::Error::matches_trial_regex_nonlax( '0.1', $config );
  is( $result->{code}, 'matches_trial_regex_nonlax', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  is( refaddr $config , refaddr $result->{config}, 'config passthrough' );
  is( $result->{version}, '0.1', 'Version passthrough' );
};

subtest not_decimal_or_trial => sub {
  $result = Gentoo::PerlMod::Version::Error::not_decimal_or_trial( '0.1', $config );
  is( $result->{code}, 'not_decimal_or_trial', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  is( refaddr $config , refaddr $result->{config}, 'config passthrough' );
  is( $result->{version}, '0.1', 'Version passthrough' );

};

subtest bad_char => sub {
  $result = Gentoo::PerlMod::Version::Error::bad_char( 'a', ord('a') );
  is( $result->{code}, 'bad_char', 'right code' );
  ok( defined $result->{message}, 'has a message' );

};

subtest lax_multi_underscore => sub {

  $result = Gentoo::PerlMod::Version::Error::lax_multi_underscore('0.1');
  is( $result->{code}, 'lax_multi_underscore', 'right code' );
  ok( defined $result->{message}, 'has a message' );
  is( $result->{version}, '0.1', 'Version passthrough' );

};

done_testing;
