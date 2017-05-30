package Linux::GetPidstat::Collector::Parser;
use 5.008001;
use strict;
use warnings;

use Exporter qw(import);
use List::Util qw(sum reduce);

our @EXPORT = qw(parse_pidstat_output);

sub parse ($) {
    my $lines = shift;

    my $ret;

    my $mapping = _get_metric_rule_mapping();
    my $pid_rule = delete $mapping->{pid};
    while (my ($name, $metric_rule) = each %$mapping) {
        my $metric = _get_metric_mean($metric_rule, $pid_rule, $lines);
        unless (defined $metric) {
            warn (sprintf "Empty metric: name=%s, lines=%s\n",
                $name, join ',', @$lines);
            return;
        }

        # ex. cpu => 21.0
        $ret->{$name} = $metric;
    }

    return $ret;
}

sub _get_metric_rule_mapping() {
    my $convert_from_kilobytes = sub { my $raw = shift; return $raw * 1000 };

    return {
        pid => {
            column_num   => 2,
        },
        cpu => {
            column_num   => 6,
        },
        memory_percent => {
            column_num   => 12,
        },
        memory_rss => {
            column_num   => 11,
            convert_func => $convert_from_kilobytes,
        },
        stk_size => {
            column_num   => 13,
            convert_func => $convert_from_kilobytes,
        },
        stk_ref => {
            column_num   => 14,
            convert_func => $convert_from_kilobytes,
        },
        disk_read_per_sec => {
            column_num   => 15,
            convert_func => $convert_from_kilobytes,
        },
        disk_write_per_sec => {
            column_num   => 16,
            convert_func => $convert_from_kilobytes,
        },
        cswch_per_sec => {
            column_num   => 18,
        },
        nvcswch_per_sec => {
            column_num   => 19,
        },
    };
}

sub _get_metric_mean($$) {
    my ($metric_rule, $pid_rule, $lines) = @_;

    my %metrics;
    for (@$lines) {
        my @fields = split " ";

        my $pid = $fields[$pid_rule->{column_num}];
        next unless defined $pid && $pid =~ /^\d+$/;

        my $metric = $fields[$metric_rule->{column_num}];
        next unless defined $metric && $metric =~ /^[-+]?[0-9.]+$/;
        if (my $cf = $metric_rule->{convert_func}) {
            $metric = $cf->($metric);
        }

        $metrics{$pid} = [] unless exists $metrics{$pid};
        push @{ $metrics{$pid} }, $metric;
    }

    return unless %metrics;
    return reduce { $a + _mean(@$b) } (0, values %metrics);
}

sub _mean(@) {
    return sprintf '%.2f', sum(@_)/@_;
}

*parse_pidstat_output = \&parse;

1;
__END__

=encoding utf-8

=head1 NAME

Linux::GetPidstat::Collector::Parser - Parse pidstats' output

=head1 SYNOPSIS

    use Linux::GetPidstat::Collector::Parser;

    my $ret = parse_pidstat_output($output);

=cut

