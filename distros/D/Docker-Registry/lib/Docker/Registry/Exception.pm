package Docker::Registry::Exception;
  use Moose;
  extends 'Throwable::Error';

package Docker::Registry::Exception::HTTP;
  use Moose;
  extends 'Docker::Registry::Exception';
  has status => (is => 'ro', isa => 'Int', required => 1);

package Docker::Registry::Exception::Unauthorized;
  use Moose;
  extends 'Docker::Registry::Exception::HTTP';

package Docker::Registry::Exception::FromRemote;
  use Moose;
  extends 'Docker::Registry::Exception::HTTP';

  has code => (is => 'ro', isa => 'Str', required => 1);

1;
