package Lemonldap::NG::Common::PSGI::Constants;

use strict;
use Exporter 'import';

use base qw(Exporter);
our $VERSION = '1.9.1';

# CONSTANTS

use constant {
    DEBUG  => 4,
    INFO   => 3,
    WARN   => 2,
    NOTICE => 1,
    ERROR  => 0,
};
our $no = qr/^(?:off|no|0)?$/i;

our %EXPORT_TAGS = ( 'all' => [qw(DEBUG INFO WARN ERROR $no)] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = ( @{ $EXPORT_TAGS{'all'} } );

1;

