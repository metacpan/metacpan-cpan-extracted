package Linux::GetPidstat::Writer::Mackerel;
use 5.008001;
use strict;
use warnings;

use Carp;
use Time::Piece;
use WebService::Mackerel;
use JSON::XS qw/decode_json/;

sub new {
    my ( $class, %opt ) = @_;

    my $mackerel = WebService::Mackerel->new(
        api_key      => $opt{mackerel_api_key},
        service_name => $opt{mackerel_service_name},
    );
    $opt{mackerel} = $mackerel;
    $opt{mackerel_metric_key_prefix} = "" unless defined $opt{mackerel_metric_key_prefix};

    bless \%opt, $class;
}

sub output {
    my ($self, $program_name, $metric_name, $metric) = @_;
    my $graph_name = sprintf("custom.%s%s.%s", $self->{mackerel_metric_key_prefix}, $metric_name, $program_name);

    my $metric_type = $self->{mackerel_metric_type};
    if ($self->{dry_run}) {
        printf "(dry_run) mackerel post: type=%s, name=%s, time=%s, metric=%s\n",
            $metric_type, $graph_name, $self->{now}->epoch, $metric;
        return;
    }

    my $res = do {
        if ($metric_type eq "service") {
            $self->{mackerel}->post_service_metrics([{
                "name"  => $graph_name,
                "time"  => $self->{now}->epoch,
                "value" => $metric,
            }]);
        } elsif ($metric_type eq "host") {
            $self->{mackerel}->post_host_metrics([{
                "hostId" => $self->{mackerel_host_id},
                "name"   => $graph_name,
                "time"   => $self->{now}->epoch,
                "value"  => $metric,
            }]);
        } else {
            croak "Invalid metric type of mackerel: type=$metric_type";
        }
    };

    my $content = eval { decode_json $res; };
    if (chomp $@) {
        carp "Failed mackerel post $metric_type metrics: err=$@, res=$res";
        return;
    }

    my $is_success = $content->{success} || 0;
    if ($is_success != JSON::true or $content->{error}) {
        use Data::Dumper;
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        carp "Failed mackerel post $metric_type metrics: res=" . Data::Dumper::Dumper($content);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::GetPidstat::Writer::Mackerel - Write pidstat's results to mackerel

=head1 SYNOPSIS

    use Linux::GetPidstat::Writer::Mackerel;

    my $instance = Linux::GetPidstat::Writer::Mackerel->new(
        mackerel_metric_type  => 'service',
        mackerel_api_key      => 'api_key',
        mackerel_service_name => 'service_name',
        now                   => $t,
        dry_run               => $self->{dry_run},
    );
    $instance->output('backup_mysql', 'cpu', '21.20');

=cut

