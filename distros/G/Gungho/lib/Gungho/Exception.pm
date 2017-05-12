# $Id: /mirror/gungho/lib/Gungho/Exception.pm 1733 2007-05-15T02:45:51.609363Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Exception;
use strict;
use warnings;
use Exception::Class
    'Gungho::Exception',
    map {
        ($_ => { isa => 'Gungho::Exception' })
    } qw(
        Gungho::Exception::RequestThrottled
        Gungho::Exception::SendRequest::Handled
        Gungho::Exception::HandleResponse::Handled
    )
;

1;

__END__

=head1 NAME

Gungho::Exception - Gungho Exceptions

=cut
