#!/usr/bin/perl -w

# tag: test for using JOAP Server classes

# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
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

use Test::More tests => 9;

BEGIN {
    use_ok('Net::Jabber', 'Client');
    use_ok('JOAP');
    # use base does this check, so we do it here, too.
    ok(%{JOAP::}, "There's something in the JOAP package.");
    use_ok('JOAP::Server');
    ok(%{JOAP::Server::}, "There's something in the JOAP::Server package.");
    use_ok('JOAP::Server::Object');
    ok(%{JOAP::Server::Object::}, "There's something in the JOAP::Server::Object package.");
    use_ok('JOAP::Server::Class');
    ok(%{JOAP::Server::Class::}, "There's something in the JOAP::Server::Class package.");
}
