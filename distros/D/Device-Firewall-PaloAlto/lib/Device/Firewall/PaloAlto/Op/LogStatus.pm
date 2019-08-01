package Device::Firewall::PaloAlto::Op::LogStatus;
$Device::Firewall::PaloAlto::Op::LogStatus::VERSION = '0.1.9';
use strict;
use warnings;
use 5.010;

use parent qw(Device::Firewall::PaloAlto::JSON);

use Device::Firewall::PaloAlto::Errors qw(ERROR);
use Regexp::Common qw(time);
use DateTime;

# VERSION
# PODNAME
# ABSTRACT: Logging status of a Palo Alto firewall.



sub _new {
    my $class = shift;
    my ($api_response) = @_;

    return $api_response unless $api_response;

    my $raw_log_status = $api_response->{result};
    my %log_obj = _extract_log_collection_data($raw_log_status);

    return bless \%log_obj, $class;
}



sub seq_numbers {
    my $self = shift;
    my ($log_type) = @_;

    return unless defined $self->{$log_type};

    return @{$self->{$log_type}}{ qw(last_seq_num_fwd last_seq_num_acked) };
}


sub total {
    my $self = shift;
    my ($log_type) = @_;

    return 0 unless $self->{$log_type};

    return $self->{$log_type}{total_logs} // 0;
}


# This takes in the raw response from the API call.
# It returns a hash with the log collector log information
sub _extract_log_collection_data {
    my ($raw_input) = @_;

    my %lc_info;

    while ($raw_input =~ m{
            (config|system|threat|traffic|hipmatch|gtp-tunnel|userid|auth|sctp)
            \s+
            (\d{4}\/\d{1,2}\/\d{1,2} \s+ \d{1,2}:\d{1,2}:\d{1,2} | Not\sAvailable)
            \s+
            (\d{4}\/\d{1,2}\/\d{1,2} \s+ \d{1,2}:\d{1,2}:\d{1,2} | Not\sAvailable)
            \s+
            (\d+)
            \s+
            (\d+)
            \s+
            (\d+)
    }xmsg) {
        @{$lc_info{$1}}{qw(last_log last_log_sent last_seq_num_fwd last_seq_num_acked total_logs)} = ($2, $3, $4, $5, $6);
    }

    return %lc_info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::LogStatus - Logging status of a Palo Alto firewall.

=head1 VERSION

version 0.1.9

=head1 DESCRIPTION

This module represents the logging status of a Palo Alto firewall. It contains methods to retreive
the sequence numbers and totals for each individual log type (traffic, threat, etc) sent by the firewall to Panorama or log collectors.

=head1 METHODS

=head2 seq_numbers

    my ($last_sent, $last_acked) = $fw->op->loggung_statis->seq_numbers( 'traffic' );

Returns a list of two sequence numbers for a log type. The first entry is the last sequence number sent,
and the second entry is the last sequence number that has been acknowledged by the log collector.

If the firewall is not connected to a log collector, an empty list will be returned.

=head2 total

    my $total_logs = $fw->op->logging_status->total( 'threat' );

Returns an integer representing the total number of logs forwarded from the device for a specific type.

If the firewall is not connected to a log collector, a total of 0 is returned.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
