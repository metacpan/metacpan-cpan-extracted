package Docker::Registry::Auth::None;
  use Moose;
  with 'Docker::Registry::Auth';

  sub authorize {
    my ($self, $request) = @_;
    return $request;
  }

1;
