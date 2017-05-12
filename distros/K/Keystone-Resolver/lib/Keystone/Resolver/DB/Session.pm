# $Id: Session.pm,v 1.4 2007-05-29 17:16:31 mike Exp $

package Keystone::Resolver::DB::Session;

use strict;
use warnings;
use Keystone::Resolver::DB::Object;

use vars qw(@ISA);
@ISA = qw(Keystone::Resolver::DB::Object);


sub table { "session" }
sub fields { (id => undef,
	      site_id => undef,
	      cookie => undef,
	      user_id => undef,
	      dest => undef,
	      query => undef,
	      ) }

# Generate a suitable opaque session key to use included as the
# session-cookie's value.  We could include information in this key,
# such as an encrypted version of the IP address that the session was
# created for -- then we'd be able to reject cookies submitted from
# the wrong machine.  But for now, we just generate randomly.
#
sub create {
    my $class = shift();

    my $chars = join("", "A".."Z", "a".."z", "0".."9", "+", "/");
    my $cookie = "";
    foreach my $i (1..12) {
	$cookie .= substr($chars, int(rand()*64), 1);
    }

    return $class->SUPER::create(@_, cookie => $cookie);
}


1;
