package HTML::Zoom::TransformBuilder;

use strictures 1;
use base qw(HTML::Zoom::SubObject);
use HTML::Zoom::Transform;

sub new {
  my ($class, $args) = @_;
  my $new = $class->SUPER::new($args);
  $new->{transform} =
    $args->{transform}
    || HTML::Zoom::Transform->new({
         zconfig => $new->{_zconfig},
         selector => $args->{selector},
         filters => [],
       });
  $new->{proto} = $args->{proto};
  $new
}

sub DESTROY {}

sub AUTOLOAD {
  my $meth = our $AUTOLOAD;
  $meth =~ s/.*:://;
  my $self = shift;
  my $fb = $self->_zconfig->filter_builder;
  if (my $cr = $fb->can($meth)) {
    return $self->{proto}->with_transform(
      $self->{transform}->with_filter($fb->$cr(@_))
    );
  }
  die "Filter builder $fb does not provide action ${meth}";
}

1;
