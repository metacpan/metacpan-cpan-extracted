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
    'drilldown_sort_keys',
    'dynamic_columns',
    'match_columns',
    'query_expander',
    'post_filter'
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
        $parsed_arguments .= "output_columns=";

        my $output_columns = $args->{'output_columns'};
        foreach my $output_column (@$output_columns) {
            $parsed_arguments .= $output_column . ',';
        }
        chop($parsed_arguments);
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
    if (exists($args->{'drilldown_sort_keys'})) {
        $use_drilldown = 1;
        $parsed_arguments .= '&';
        $parsed_arguments .= "drilldown_sort_keys=" . $args->{'drilldown_sort_keys'};
    }
    if (exists($args->{'dynamic_columns'})) {
        my $dynamic_columns = $args->{'dynamic_columns'};

        for (my $i = 0; $i < scalar(@$dynamic_columns); $i++) {
            if (exists($dynamic_columns->[$i]->{'name'})
                && exists($dynamic_columns->[$i]->{'stage'})
                && exists($dynamic_columns->[$i]->{'type'})
                && exists($dynamic_columns->[$i]->{'value'})
               ) {
                ;
            } else {
                croak "Missing required argument";
            }

            my $name = $dynamic_columns->[$i]->{'name'};

            $parsed_arguments .= '&';
            $parsed_arguments .=
                "columns[" . $name . "].stage=". $dynamic_columns->[$i]->{'stage'};
            $parsed_arguments .= '&';
            $parsed_arguments .=
                "columns[" . $name . "].type=". $dynamic_columns->[$i]->{'type'};
            $parsed_arguments .= '&';
            $parsed_arguments .=
                "columns[" . $name . "].value=". $dynamic_columns->[$i]->{'value'};

            if (exists($dynamic_columns->[$i]->{'flags'})) {
                $parsed_arguments .= '&';
                $parsed_arguments .=
                    "columns[" . $name . "].flags=". $dynamic_columns->[$i]->{'flags'};
            }
        }
    }
    if (exists($args->{'match_columns'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "match_columns=" . $args->{'match_columns'};
    }
    if (exists($args->{'query_expander'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "query_expander=" . $args->{'query_expander'};
    }
    if (exists($args->{'post_filter'})) {
        $parsed_arguments .= '&';
        $parsed_arguments .= "post_filter=" . $args->{'post_filter'};
    }

    return $parsed_arguments;
}

sub _parse_result {
    my $result = shift;
    my %result_set = ();
    my @records = ();
    my @drilldown_result_records = ();

    if ($use_drilldown) {
        $result_set{'n_hits_drilldown'} = $result->[1][0][0];

        my @column_names_drilldown;
        for (my $i = 0; $result->[1][1][$i]; $i++) {
            push(@column_names_drilldown, $result->[1][1][$i][0]);
        }

        for (my $i = 0, my $j = 2; $i < $result_set{'n_hits_drilldown'}; $i++, $j++) {
            my %record = ();
            for (my $k=0; $k < @column_names_drilldown; $k++) {
                $record{"drilldown_" . $column_names_drilldown[$k]} = "$result->[1][$j][$k]";
            }
            push(@drilldown_result_records, \%record);
        }
        $use_drilldown = 0;
    }

    $result_set{'n_hits'} = $result->[0][0][0];

    my @column_names;
    for (my $i = 0; $result->[0][1][$i]; $i++) {
        push(@column_names, $result->[0][1][$i][0]);
    }
    for (my $i = 0, my $j = 2; $i < $result_set{'n_hits'}; $i++, $j++) {
        my %record = ();
        for (my $k=0; $k < @column_names; $k++) {
            $record{"$column_names[$k]"} = $result->[0][$j][$k];
        }
        push(@records, \%record);
    }
    $result_set{'records'} = \@records;
    $result_set{'drilldown_result_records'} = \@drilldown_result_records;

    return \%result_set;
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
