##@file
# Add LWP::UserAgent object

##@class
# Add LWP::UserAgent object
package Lemonldap::NG::Portal::_Browser;

use strict;

our $VERSION = '1.3.0';
our $_ua;

## @method LWP::UserAgent ua()
# @return LWP::UserAgent object
sub ua {
    my $self = shift;

    return $_ua if ($_ua);
    eval { require LWP::UserAgent; };
    $self->abort( 'LWP::UserAgent isn\'t installed', $@ ) if ($@);

    # TODO : LWP options to use a proxy for example
    $_ua = LWP::UserAgent->new() or $self->abort($@);
    push @{ $_ua->requests_redirectable }, 'POST';
    $_ua->env_proxy();
    return $_ua;
}

1;

