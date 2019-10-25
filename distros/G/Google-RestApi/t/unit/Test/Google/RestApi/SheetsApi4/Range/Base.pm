package Test::Google::RestApi::SheetsApi4::Range::Base;

use Scalar::Util qw(looks_like_number);

use parent 'Test::Google::RestApi::SheetsApi4::Base';

sub startup {
  my $self = shift;
  $self->SUPER::startup(@_);
  $self->{err} = qr/Unable to translate/;
  return;
}

sub _to_str {
  my $self = shift;
  my $x = shift;
  return 'undef' if !defined $x;
  return $x if looks_like_number($x);
  return "'$x'";
}

sub new_range {
  my $self = shift;
  return $self->class()->new(worksheet => $self->worksheet(), range => shift);
}

1;
