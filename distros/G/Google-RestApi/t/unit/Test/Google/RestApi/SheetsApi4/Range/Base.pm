package Test::Google::RestApi::SheetsApi4::Range::Base;

use Test::Unit::Setup;

use aliased 'Google::RestApi::SheetsApi4::Worksheet';

use parent 'Test::Unit::TestBase';

use Scalar::Util qw(looks_like_number);

sub _to_str {
  my $self = shift;
  my $x = shift;
  return 'undef' if !defined $x;
  return $x if looks_like_number($x);
  return "'$x'";
}

1;
