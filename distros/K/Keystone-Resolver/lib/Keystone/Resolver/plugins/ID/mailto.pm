# $Id: mailto.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::ID::mailto;

use strict;
use warnings;


sub data {
    my $class = shift();
    my($openurl, $address) = @_;

    # We can't "resolve" a mailto: address -- in fact, it's not clear
    # what it's useful for, apart from, I suppose, giving you a way of
    # emailing material to the user.  But our inability to resolve
    # these IDs is not an error: it's fundamental to what kind of
    # thing they are.  So we provide no error message.

    return (undef, undef, undef, undef);
}


1;
