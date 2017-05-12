package HTML::Zoom::SubObject;

use strictures 1;
use Scalar::Util ();

sub new {
  my ($class, $args) = @_;
  ($args||={})->{zconfig} ||= do {
    require HTML::Zoom::ZConfig;
    HTML::Zoom::ZConfig->new
  };
  my $new = { _zconfig => $args->{zconfig} };
  Scalar::Util::weaken($new->{_zconfig});
  bless($new, $class)
}

sub _zconfig { shift->{_zconfig} }

sub with_zconfig {
  my ($self, $zconfig) = @_;
  my $new = bless({ %$self, _zconfig => $zconfig }, ref($self));
  Scalar::Util::weaken($new->{_zconfig});
  $new
}

1;
