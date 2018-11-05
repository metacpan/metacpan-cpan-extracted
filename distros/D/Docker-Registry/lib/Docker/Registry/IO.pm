package Docker::Registry::IO;
  use Moo::Role;

  use Docker::Registry::Request;
  use Docker::Registry::Response;

  # load this "almost empty" class because
  # IO modules use $Docker::Registry::VERSION
  # in the User Agent
  use Docker::Registry;

  requires 'send_request';

1;
