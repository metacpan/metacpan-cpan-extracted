package Lemonldap::NG::Common::Conf::Backends::Timeout;

use Lemonldap::NG::Common::Conf::Backends::File;
our @ISA = ('Lemonldap::NG::Common::Conf::Backends::File');

sub load {
    my $self = shift;
    sleep 5;
    return $self->SUPER::load(@_);
}

sub AUTOLOAD {
    $AUTOLOAD =~ s/Lemonldap::NG::Common::Conf::Backends::Timeout:://;
    return &{"Lemonldap::NG::Common::Conf::Backends::File::$AUTOLOAD"}(@_);
}

1;
