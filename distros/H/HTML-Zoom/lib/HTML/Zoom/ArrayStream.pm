package HTML::Zoom::ArrayStream;

use strictures 1;
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  bless(
    { _zconfig => $args->{zconfig}, _array => [ @{$args->{array}} ] },
    $class
  );
}

sub _next {
  my $ary = $_[0]->{_array};
  return unless @$ary;
  return shift @$ary;
}

1;
