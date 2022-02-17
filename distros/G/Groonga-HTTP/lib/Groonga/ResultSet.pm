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

package Groonga::ResultSet;

use JSON::PP;

use strict;
use warnings;

my $command_response_code = undef;
my @command_response_raw = ();
my $command_response = {};

sub new {
    my ($class, %args) = @_;
    my $self = {%args};

    if ($self->{decoded_content}) {
        @command_response_raw = decode_json($self->{decoded_content});
        $command_response_code = $command_response_raw[0][0][0];
        $command_response = $command_response_raw[0][1];
    }

    return bless $self, $class;
}

sub is_success {
    return $command_response_code == 0;
}

sub content {
    return $command_response;
}

1;
