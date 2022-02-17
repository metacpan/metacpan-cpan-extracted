# Copyright (C) 2021-2022  Horimoto Yasuhiro <horimoto@clear-code.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Groonga::Commands::Status;

use Groonga::HTTP::Client;

use strict;
use warnings;

my $groonga_http_client = undef;

sub new {
    my ($class, %arg) = @_;
    my $self = {%arg};

    $groonga_http_client = $self->{client};

    return bless $self, $class;
}

sub _make_command {
    return "status";
}

sub execute {
    if (defined $groonga_http_client) {
        my $command = _make_command;
        return $groonga_http_client->send($command);
    }
    return;
}

1;
