package Helios::LogEntry::Levels;

use strict;
use warnings;
use constant {
    LOG_EMERG   => 0,
    LOG_ALERT   => 1,
    LOG_CRIT    => 2,
    LOG_ERR     => 3,
    LOG_WARNING => 4,
    LOG_NOTICE  => 5,
    LOG_INFO    => 6,
    LOG_DEBUG   => 7,
};
require Exporter;

our $VERSION = '2.20';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

1;
__END__
