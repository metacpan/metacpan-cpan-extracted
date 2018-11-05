package Docker::Registry::Exception;
  use Moo;
  extends 'Throwable::Error';

package Docker::Registry::Exception::HTTP;
  use Moo;
  use Types::Standard qw/Int/;
  extends 'Docker::Registry::Exception';
  has status => (is => 'ro', isa => Int, required => 1);

package Docker::Registry::Exception::Unauthorized;
  use Moo;
  extends 'Docker::Registry::Exception::HTTP';

package Docker::Registry::Exception::FromRemote;
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Docker::Registry::Exception::HTTP';

  has code => (is => 'ro', isa => Str, required => 1);

1;
