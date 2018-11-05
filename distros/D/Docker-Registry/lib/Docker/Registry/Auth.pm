package Docker::Registry::Auth::Exception;
  use Moo;
  extends 'Docker::Registry::Exception';

package Docker::Registry::Auth::Exception::HTTP;
  use Moo;
  extends 'Docker::Registry::Exception::HTTP';

package Docker::Registry::Auth::Exception::FromRemote;
  use Moo;
  extends 'Docker::Registry::Exception::FromRemote';

package Docker::Registry::Auth;
  use Moo::Role;

  requires 'authorize';

1;
