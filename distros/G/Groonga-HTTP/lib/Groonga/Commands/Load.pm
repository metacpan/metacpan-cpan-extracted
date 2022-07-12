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

package Groonga::Commands::Load;

use JSON;
use Carp 'croak';

use strict;
use warnings;
use Data::Dumper;

my $groonga_http_client = undef;
my $command_args = "";
my $n_loaded_records = undef;
my @records;
my $use_drilldown = 0;
my @load_arguments = (
    'table',
    'values'
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
        if (!(grep {$_ eq $key} @load_arguments)) {
            croak "Invalid arguments: ${key}";
        }
    }

    return 1;
}

sub _parse_arguments {
    my $args = shift;
    my %parsed_arguments = ();

    _is_valid_arguments($args);

    if (exists($args->{'table'})) {
        $parsed_arguments{'table'} = $args->{'table'};
    }
    $parsed_arguments{'values'} = encode_json($args->{'values'});

    return \%parsed_arguments;
}

sub _parse_result {
    my $result = shift;
    my %result_set = ();

    $result_set{'n_loaded_records'} = $result;

    return \%result_set;
}

sub execute {
    if (defined $groonga_http_client) {
        return _parse_result($groonga_http_client->send_post(
                                 'load',
                                 "?table=$command_args->{'table'}",
                                 $command_args->{'values'}
                            )
               );
    }
    return;
}

1;
