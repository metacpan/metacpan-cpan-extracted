package Lab::Moose::Instrument::Zhinst;
$Lab::Moose::Instrument::Zhinst::VERSION = '3.682';
#ABSTRACT: Base class for Zurich Instruments device drivers

use 5.010;
use Moose;
use MooseX::Params::Validate qw/validated_list validated_hash/;
use Carp;

# do not make imported functions available as methods.
use namespace::autoclean;
use YAML::XS 'Dump';

# FIXME: put this into separate module?
use constant {
    ZI_LIST_NODES_RECURSIVE => 1,
    ZI_LIST_NODES_ABSOLUTE  => 2,
};

extends 'Lab::Moose::Instrument';

has device => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_get_device',
    lazy    => 1,
);


sub _get_device {
    my $self = shift;

    my $nodes = $self->list_nodes(
        path => '/',
        mask => ZI_LIST_NODES_ABSOLUTE | ZI_LIST_NODES_RECURSIVE
    );

    my @devices = $nodes =~ m{^/dev\w*}gmi;
    my %hash = map { $_ => 1 } @devices;
    @devices = keys %hash;
    if ( @devices == 0 ) {
        croak "no connected devices";
    }
    if ( @devices > 1 ) {
        croak
            "found multiple devices: @devices. Give explicit device argument.";
    }
    return $devices[0];
}


sub list_nodes {
    my ( $self, %args ) = validated_hash(
        \@_,

        # Proper validation is done in Connection::Zhinst.
        path => { isa => 'Str' },
        mask => { isa => 'Int' },
    );

    $args{method} = 'ListNodes';
    my $command = Dump( \%args );
    return $self->binary_query( command => $command );
}


sub get_value {
    my ( $self, %args ) = validated_hash(
        \@_,
        path => { isa => 'Str' },
        type => { isa => 'Str' },
    );

    $args{method} = 'Get';
    my $command = Dump( \%args );
    return $self->binary_query( command => $command );
}


sub sync_set_value {
    my ( $self, %args ) = validated_hash(
        \@_,
        path  => { isa => 'Str' },
        type  => { isa => 'Str' },
        value => { isa => 'Str' },
    );

    $args{method} = 'SyncSet';
    my $command = Dump( \%args );
    return $self->binary_query( command => $command );
}


sub sync_poll {
    my ( $self, %args ) = validated_hash(
        \@_,
        path    => { isa => 'Str' },
        timeout => { isa => 'Num', optional => 1 },
    );
    $args{method} = 'SyncPoll';
    my $command = Dump( \%args );
    return $self->binary_query( command => $command );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Zhinst - Base class for Zurich Instruments device drivers

=head1 VERSION

version 3.682

=head1 METHODS

=head2 list_nodes

 my $nodes = $instr->list_nodes(path => $path, mask => $mask);

Call L<Lab::Zhinst> ListNodes method.

=head2 get_value

 my $filter_order = $instr->get_value(path => "$device/demods/0/order", type => 'I');
 my $demod_hash = $instr->get_value(path => "$device/demods/0/sample", type => 'DemodSample');

Call L<Lab::Zhinst> Get* method.
Supported values for the C<$type> argument: I (integer), D (double), B (byte
array), Demod, DIO, AuxIn.

=head2 sync_set_value

 my $set_tc = $instr->sync_set_value(
     path => "$device/demods/0/timeconstant",
     type => 'D',
     value => '1.1',
 );

Call L<Lab::Zhinst> SyncSet* method. Supported values for C<$type>: I, D, B.

=head2 sync_poll

 my $sample = $instr->sync_poll(
     path => "$device/imps/0/sample",
     timeout => 0.1,
 );

Poll event and return the most recent value in the event. Before doing the
poll, flush the event queque with a Sync to ensure that we get a newly recorded
event.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
