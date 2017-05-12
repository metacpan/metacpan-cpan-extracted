package Linux::GetPidstat::Writer;
use 5.008001;
use strict;
use warnings;

use Time::Piece;
use Linux::GetPidstat::Writer::File;
use Linux::GetPidstat::Writer::Mackerel;

sub new {
    my ( $class, %opt ) = @_;
    bless \%opt, $class;
}

sub output {
    my ($self, $ret_pidstats) = @_;

    my $file;
    if (length $self->{res_file}) {
        $file = Linux::GetPidstat::Writer::File->new(
            res_file => $self->{res_file},
            now      => $self->{now},
            dry_run  => $self->{dry_run},
        );
    }

    my $mackerel;
    if (length $self->{mackerel_api_key} && length $self->{mackerel_service_name}) {
        $mackerel = Linux::GetPidstat::Writer::Mackerel->new(
            mackerel_api_key      => $self->{mackerel_api_key},
            mackerel_service_name => $self->{mackerel_service_name},
            now                   => $self->{now},
            dry_run               => $self->{dry_run},
        );
    }

    # ex. backup_mysql => { cpu => 21.0 }
    while (my ($program_name, $s) = each %$ret_pidstats) {
        while (my ($metric_name, $metric) = each %$s) {
            if ($file) {
                $file->output($program_name, $metric_name, $metric);
            }

            if ($mackerel) {
                $mackerel->output($program_name, $metric_name, $metric);
            }
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::GetPidstat::Writer - Write pidstat's results to destinations

=head1 SYNOPSIS

    use Linux::GetPidstat::Writer;

    my $instance = Linux::GetPidstat::Writer->new(
        res_file              => './res',
        mackerel_api_key      => '',
        mackerel_service_name => '',
        dry_run               => '0',
    );
    $instance->output($results);

=cut
