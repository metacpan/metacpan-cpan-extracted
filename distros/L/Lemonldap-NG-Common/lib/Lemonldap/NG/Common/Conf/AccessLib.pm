package Lemonldap::NG::Common::Conf::AccessLib;

use strict;
use utf8;
use Mouse;

use Lemonldap::NG::Common::Conf;

has '_confAcc'      => ( is => 'rw', isa => 'Lemonldap::NG::Common::Conf' );
has 'configStorage' => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
has 'currentConf'   => ( is => 'rw', required => 1,     default => sub { {} } );
has 'protection'    => ( is => 'rw', isa      => 'Str', default => 'manager' );

our $VERSION = '2.0.11';

## @method Lemonldap::NG::Common::Conf confAcc()
# Configuration access object
#
# Return _confAcc property if exists or create it.
#
#@return Lemonldap::NG::Common::Conf object
sub confAcc {
    my $self = shift;
    return $self->_confAcc if ( $self->_confAcc );

    # TODO: pass args and remove this
    my $d = `pwd`;
    chomp $d;
    my $tmp;
    unless ( $tmp = Lemonldap::NG::Common::Conf->new( $self->configStorage ) ) {
        die "Unable to build Lemonldap::NG::Common::Conf "
          . $Lemonldap::NG::Common::Conf::msg;
    }
    return $self->_confAcc($tmp);
}

1;
