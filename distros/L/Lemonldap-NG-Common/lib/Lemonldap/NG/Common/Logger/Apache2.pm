package Lemonldap::NG::Common::Logger::Apache2;

use Apache2::ServerRec;

our $VERSION = '2.0.0';

sub new {
    return bless {}, shift;
}

sub AUTOLOAD {
    shift;
    $AUTOLOAD =~ s/.*:://;
    return Apache2::ServerRec->log->$AUTOLOAD(@_);
}

1;
