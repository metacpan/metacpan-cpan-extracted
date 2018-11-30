package Lemonldap::NG::Portal::Auth::Custom;

use strict;

# Fake 'new' method here. Return Lemonldap::NG::Portal::Auth::Custom::{CustomAuth}->new
sub new {
    my ( $class, $self ) = @_;
    unless ( $self->{conf}->{customAuth} ) {
        die 'Custom Auth module not defined';
    }

    my $res;
    eval { $res = $self->{p}->loadModule( $self->{conf}->{customAuth} ) };
    die 'Unable to load Auth module ' . $self->{conf}->{customAuth} if ($@);
    return $res;
}

sub getDisplayType {

    # Warning : $self passed here is the Portal itself
    my ($self) = @_;
    my $logo = ( $self->{conf}->{customAuth} =~ /::(\w+)$/ )[0];

    if (  -e $self->{conf}->{templateDir}
        . "/../htdocs/static/common/modules/"
        . $logo
        . ".png" )
    {
        $self->logger->debug("CustomAuth $logo.png found");
        return "logo";
    }
    return "standardform";
}

1;
