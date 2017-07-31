package File::Feed::Context;

use strict;
use warnings;

use String::Expando;

sub new {
    my $cls = shift;
    bless {
        'stash' => { @_ },
        'expando' => String::Expando->new,
    }, $cls;
}

sub expand {
    my ($self, $str) = @_;
    return $self->{'expando'}->expand($str, $self->{'stash'});
}

1;
