package Imgur::API::Endpoint::Misc;

use strict;
use Mouse;
extends 'Imgur::API::Endpoint';

sub credits {
    my ($this,%p) = @_;

    my $ret = $this->dispatcher->request(
        $this->path("3/credits",[],[],\%p),
        'get',
        \%p
    );
	$this->dispatcher->stats->update($ret);
	return $ret;
}

1;
__PACKAGE__->meta->make_immutable;

