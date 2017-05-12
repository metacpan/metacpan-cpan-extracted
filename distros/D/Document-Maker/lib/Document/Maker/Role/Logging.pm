package Document::Maker::Role::Logging;

use Moose::Role;

use Document::Maker::Logger qw/get_logger/;

sub logger {
    return get_logger;
}
*log = \&logger;
