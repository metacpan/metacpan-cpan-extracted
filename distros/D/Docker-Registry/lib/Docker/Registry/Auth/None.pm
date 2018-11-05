package Docker::Registry::Auth::None;
  use Moo;
  with 'Docker::Registry::Auth';

  sub authorize {
    my ($self, $request) = @_;
    return $request;
  }

1;
