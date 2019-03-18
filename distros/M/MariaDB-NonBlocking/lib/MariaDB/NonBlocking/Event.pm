package MariaDB::NonBlocking::Event;
use v5.18.2; # needed for __SUB__, implies strict
use warnings;

use AnyEvent ();

my $ran_detect;
AnyEvent::post_detect {
    $ran_detect = 1;
    my $IS_EV = ($AnyEvent::MODEL//'') eq 'AnyEvent::Impl::EV' ? 1 : 0;
    if ( $IS_EV ) {
        require MariaDB::NonBlocking::EV;
        our @ISA = 'MariaDB::NonBlocking::EV';
    }
    else {
        require MariaDB::NonBlocking::AE;
        our @ISA = 'MariaDB::NonBlocking::AE';
    }
};

sub new {
    AnyEvent::detect() unless $ran_detect;
    delete $MariaDB::NonBlocking::Event::{new};
    return shift->SUPER::new(@_);
}

1;
