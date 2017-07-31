package Lab::Moose::Instrument::SCPI::Trace::Data::Response;
#ABSTRACT: ???
$Lab::Moose::Instrument::SCPI::Trace::Data::Response::VERSION = '3.554';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Trace::Data::Response - ???

=head1 VERSION

version 3.554

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
