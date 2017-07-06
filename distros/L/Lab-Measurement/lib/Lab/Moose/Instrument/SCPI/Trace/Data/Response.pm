package Lab::Moose::Instrument::SCPI::Trace::Data::Response;
$Lab::Moose::Instrument::SCPI::Trace::Data::Response::VERSION = '3.552';
use Moose::Role;
use Lab::Moose::Instrument qw/getter_params/;
use Lab::Moose::Instrument::Cache;
use MooseX::Params::Validate;

sub trace_data_response_all {
    my ( $self, %args ) = validated_hash(
        \@_,
        getter_params(),
        trace => { isa => 'Str' },
    );

    my $trace = delete $args{trace};

    return $self->binary_query(
        command => "TRAC:DATA:RESP:ALL? $trace",
        %args
    );
}

1;
