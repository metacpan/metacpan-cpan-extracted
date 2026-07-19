package GraphQL::Houtou::Promise::PromiseXS;

use 5.014;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  is_promise_xs_value
  maybe_get_promise_xs
);

sub _load_promise_xs {
  require Promise::XS;
  return 1;
}

sub is_promise_xs_value {
  my ($value) = @_;
  return !!($value && ref($value) && eval { $value->isa('Promise::XS::Promise') });
}

sub maybe_get_promise_xs {
  my ($value) = @_;
  _load_promise_xs();
  return $value if !is_promise_xs_value($value);

  my $done = 0;
  my @fulfilled;
  my @rejected;

  $value->then(
    sub {
      $done = 1;
      @fulfilled = @_;
      return;
    },
    sub {
      $done = 1;
      @rejected = @_;
      return;
    },
  );

  die "Promise::XS promise did not resolve synchronously\n" if !$done;
  die @rejected if @rejected;
  return wantarray ? @fulfilled : $fulfilled[0];
}

sub resolve_deferred_xs {
  my ($deferred, $value) = @_;
  _load_promise_xs();
  $deferred->resolve($value);
  return;
}

1;
