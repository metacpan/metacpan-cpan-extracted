package Docker::Registry::Auth::Exception;
  use Moose;
  extends 'Docker::Registry::Exception';

package Docker::Registry::Auth::Exception::HTTP;
  use Moose;
  extends 'Docker::Registry::Exception::HTTP';

package Docker::Registry::Auth::Exception::FromRemote;
  use Moose;
  extends 'Docker::Registry::Exception::FromRemote';

package Docker::Registry::Auth;
  use Moose::Role;

  requires 'authorize';

1;
