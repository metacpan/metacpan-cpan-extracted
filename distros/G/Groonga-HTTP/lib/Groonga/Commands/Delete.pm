# Copyright (C) 2022  Horimoto Yasuhiro <horimoto@clear-code.com>
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

package Groonga::Commands::Delete;

use Carp 'croak';

use strict;
use warnings;
use Data::Dumper;
use JSON;
my $groonga_http_client = undef;
my $command_args = "";
my @delete_arguments = (
    'table',
    'key'
);

sub new {
    my ($class, %args) = @_;
    my $self = {%args};

    $groonga_http_client = $self->{client};
    $command_args = _parse_arguments($self);

    return bless $self, $class;
}

sub _is_valid_arguments {
    my $args = shift;

    while (my ($key, $value) = each %{$args}) {
        if ($key eq 'client') {
            next;
        }
        if (!(grep {$_ eq $key} @delete_arguments)) {
            croak "Invalid arguments: ${key}";
        }
    }

    return 1; #true
}

sub _parse_arguments {
    my $args = shift;

    my %parsed_arguments = ();

    _is_valid_arguments($args);

    if (exists($args->{'table'})) {
        $parsed_arguments{'table'} = $args->{'table'};
    } else {
        croak 'Missing a require argument "table"';
    }
    if (exists($args->{'key'})) {
        $parsed_arguments{'key'} = $args->{'key'};
    } else {
        croak 'Missing a require argument "key"';
    }

    return \%parsed_arguments;
}

sub _parse_result {
    my $result = shift;
    my %result_set = ();

    if ($result == JSON::PP::true) {
        $result = 1;
    } else {
        $result = 0;
    }
    $result_set{'is_success'} = $result;

    return \%result_set;
}

sub execute {
    if (defined $groonga_http_client) {
        return _parse_result($groonga_http_client->send('delete', $command_args));
    }
    return;
}

1;
