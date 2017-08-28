package MYDan::Collector::Sock::Data;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Queue;
use Socket;
use IO::Select;

use MYDan::Util::Sysrw;
use YAML::XS;

use threads::shared;

our $DATA:shared;
use base 'MYDan::Collector::Sock';


sub _server
{
    my ( $this, $socket ) = @_;
    MYDan::Util::Sysrw->write( $socket, $DATA || '---' );
}

1;
