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

package Groonga::Commands::Select;

use Carp 'croak';

use strict;
use warnings;

my $groonga_http_client = undef;
my $command_args = "";
my $n_hits = undef;
my @records;
my $use_drilldown = 0;
my @select_arguments = (
    'table',
    'output_columns',
    'query',
    'filter',
    'columns',
    'sort_keys',
    'limit',
    'synonym',
    'drilldown',
    'drilldown_filter',
    'drilldown_output_columns',
    'dynamic_columns',
    'match_columns'
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
        if (!(grep {$_ eq $key} @select_arguments)) {
            croak "Invalid arguments: ${key}";
        }
    }

    return 1;
}

sub _parse_arguments {
    my $args = shift;

    my $parsed_arguments = "";

    _is_valid_arguments($args);

    if (exists($args->{'table'})) {
        $parsed_arguments .= "table=" . $args->{'table'};
    }
    if (exists($args->{'output_columns'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "output_columns=" . $args->{'output_columns'};
    }
    if (exists($args->{'query'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "query=" . $args->{'query'};
    }
    if (exists($args->{'filter'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "filter=" . $args->{'filter'};
    }
    if (exists($args->{'columns'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "match_columns=" . $args->{'columns'};
    }
    if (exists($args->{'sort_keys'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "sort_keys=" . $args->{'sort_keys'};
    }
    if (exists($args->{'limit'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "limit=" . $args->{'limit'};
    }
    if (exists($args->{'synonym'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "query_expander=" . $args->{'synonym'};
    }
    if (exists($args->{'drilldown'})) {
        $use_drilldown = 1;
        $parsed_arguments .= '&';
        $parsed_arguments .= "drilldown=" . $args->{'drilldown'};
    }
    if (exists($args->{'drilldown_filter'})) {
        $use_drilldown = 1;
        $parsed_arguments .= '&';
        $parsed_arguments .= "drilldown_filter=" . $args->{'drilldown_filter'};
    }
    if (exists($args->{'drilldown_output_columns'})) {
        $use_drilldown = 1;
        $parsed_arguments .= '&';
        $parsed_arguments .= "drilldown_output_columns=" . $args->{'drilldown_output_columns'};
    }
    if (exists($args->{'dynamic_columns'})) {
        if (exists($args->{'dynamic_columns'}->{'name'})
            && exists($args->{'dynamic_columns'}->{'stage'})
            && exists($args->{'dynamic_columns'}->{'type'})
            && exists($args->{'dynamic_columns'}->{'value'})
           ) {
            ;
        } else {
            croak "Missing required argument";
        }
        my $name = $args->{'dynamic_columns'}->{'name'};

        $parsed_arguments .= '&';
        $parsed_arguments .=
            "columns[" . $name . "].stage=". $args->{'dynamic_columns'}->{'stage'};
        $parsed_arguments .= '&';
        $parsed_arguments .=
            "columns[" . $name . "].type=". $args->{'dynamic_columns'}->{'type'};
        $parsed_arguments .= '&';
        $parsed_arguments .=
            "columns[" . $name . "].value=". $args->{'dynamic_columns'}->{'value'};

        if (exists($args->{'dynamic_columns'}->{'flags'})) {
            $parsed_arguments .= '&';
            $parsed_arguments .=
                "columns[" . $name . "].flags=". $args->{'dynamic_columns'}->{'flags'};
        }
    }
    if (exists($args->{'match_columns'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "match_columns=" . $args->{'match_columns'};
    }

    return $parsed_arguments;
}

sub _parse_result {
    my $result = shift;
    my $i = 0;

    if ($use_drilldown) {
        $i += 1;
        $use_drilldown = 0;
    }

    my $n_hits = $result->[$i][0][0];
    my @records;

    my $j = 0;
    for ($j = 2; $j < ($n_hits+2); $j++) {
        if (exists($result->[$i][$j])) {
            push(@records, $result->[$i][$j]);
        }
    }
    return ($n_hits, \@records);
}

sub _make_command {
    return 'select' . '?' . $command_args;
}

sub execute {
    if (defined $groonga_http_client) {
        my $command = _make_command;
        return _parse_result($groonga_http_client->send($command));
    }
    return;
}

1;
