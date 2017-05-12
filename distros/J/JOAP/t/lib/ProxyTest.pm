# ProxyTest - Utility library for proxy test scripts
#
# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

# tag: utility library for proxy test scripts

package ProxyTest;

use 5.008;
use strict;
use warnings;
use Net::Jabber qw(Client);

sub server {
    my $self = shift;
    return $ENV{PROXYTEST_MYSERVER};
}

sub connect {

    my $self = shift;
    my $user = $ENV{PROXYTEST_USER};
    my $server = $ENV{PROXYTEST_SERVER};
    my $password = $ENV{PROXYTEST_PASSWORD};
    my $port = $ENV{PROXYTEST_PORT} || 5222;
    my $resource = $ENV{PROXYTEST_RESOURCE} || 'ProxyTest';

    if (!$user || !$server || !$password) {
        return undef;
    }

    my $con = new Net::Jabber::Client;

    my $status = $con->Connect(hostname => $server,
                               port => $port);

    if (!(defined($status))) {
        return undef;
    }

    my @result = $con->AuthSend(username => $user,
                                password => $password,
                                resource => $resource);

    if ($result[0] ne "ok") {
        $con->Disconnect;
        return undef;
    }

    $con->RosterGet();
    $con->PresenceSend(priority => -1);

    return $con;
}

1;  # don't forget to return a true value from the file

__END__

=head1 NAME

ProxyTest - Utility library for proxy test scripts

=head1 SYNOPSIS

  use ProxyTest;

=head1 ABSTRACT

  This should be the abstract for ProxyTest.

=head1 DESCRIPTION

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Evan Prodromou, E<lt>evan@prodromou.san-francisco.ca.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
