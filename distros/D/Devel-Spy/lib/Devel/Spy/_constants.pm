package Devel::Spy;

# The calling convention for overload.pm
use constant SELF     => 0;
use constant OTHER    => 1;
use constant INVERTED => 2;

# The fields in Devel::Spy objects
use constant TIED_PAYLOAD   => 0;
use constant UNTIED_PAYLOAD => 1;
use constant CODE           => 2;

# The calling convention for Devel::Spy->new
use constant _class  => 0;
use constant _thing  => 1;
use constant _logger => 2;

1;
