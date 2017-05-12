package BadServer::Hello::Chan;

use lib 't';

use Moo;
use Server;

extends 'Server';

sub say_hello {

    $_[0]->write_chunk( 'I', '' );

}

package BadServer::Hello::Len;

use lib 't';

use Moo;
use Server;

extends 'Server';

sub say_hello {

    $_[0]->write_chunk( 'o', '' );

}

package BadServer::NoCapabilities;

use lib 't';

use Moo;
use Server;

extends 'Server::Base';

package BadServer::NoRunCommand;

use lib 't';

use Moo;
use Server;

extends 'Server::Base';
with 'Server::Capability::GetEncoding';

package BadServer::NoEncoding;

use lib 't';

use Moo;
use Server;

extends 'Server::Base';
with 'Server::Capability::RunCommand';

sub BUILD {

    $_[0]->clear_encoding;

}

1;

