package Lab::Moose::Instrument::SCPI::Initiate;
#ABSTRACT: Role for the SCPI INITiate subsystem used by Rohde&Schwarz
$Lab::Moose::Instrument::SCPI::Initiate::VERSION = '3.682';
use Moose::Role;
use Lab::Moose::Instrument
    qw/validated_no_param_setter validated_setter validated_getter/;
use Lab::Moose::Instrument::Cache;
use MooseX::Params::Validate;


cache initiate_continuous => ( getter => 'initiate_continuous_query' );

sub initiate_continuous {
    my ( $self, %args )
        = validated_no_param_setter( \@_, value => { isa => 'Bool' } );

    my $value = delete $args{value};
    $value = $value ? 1 : 0;

    $self->write( command => "INIT:CONT $value", %args );
    $self->cached_initiate_continuous($value);
}

sub initiate_continuous_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_initiate_continuous(
        $self->query( command => 'INIT:CONT?', %args ) );
}


sub initiate_immediate {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    $self->write( command => 'INIT', %args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Initiate - Role for the SCPI INITiate subsystem used by Rohde&Schwarz

=head1 VERSION

version 3.682

=head1 METHODS

=head2 initiate_continuous_query

=head2 initiate_continuous

Query/Set whether to use single sweeps or continuous sweep mode.

=head2 initiate_immediate

 $self->initiate_immediate();

Start a new single sweep.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
