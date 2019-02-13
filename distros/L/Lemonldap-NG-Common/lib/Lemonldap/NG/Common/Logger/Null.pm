package Lemonldap::NG::Common::Logger::Null;

our $VERSION = '2.0.0';

sub new {
    return bless {}, shift;
}

sub AUTOLOAD {
    return 1;
}

1;
