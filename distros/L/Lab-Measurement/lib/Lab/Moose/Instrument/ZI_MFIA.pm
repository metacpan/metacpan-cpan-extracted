package Lab::Moose::Instrument::ZI_MFIA;
$Lab::Moose::Instrument::ZI_MFIA::VERSION = '3.682';
#ABSTRACT: Zurich Instruments MFIA Impedance Analyzer.

use 5.010;
use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument 'timeout_param';
use Lab::Moose::Instrument::Cache;

extends 'Lab::Moose::Instrument::ZI_MFLI';


sub get_impedance_sample {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
    );
    return $self->sync_poll(
        path => $self->device() . "/imps/0/sample",
        %args
    );
}

# FIXME: warn/croak on AUTO freq, bw, ...

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::ZI_MFIA - Zurich Instruments MFIA Impedance Analyzer.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $mfia = instrument(
     type => 'ZI_MFIA',
     connection_type => 'Zhinst',
     connection_options => {
         host => '132.188.12.13',
         port => 8004,
     });

 $mfia->set_frequency(value => 10000);

 # Get impedance sample
 my $sample = $mfia->get_impedance_sample();
 my $real = $sample->{realz};
 my $imag = $sample->{imagz};
 my $parameter_1 = $sample->{param0};
 my $parameter_2 = $sample>{param1};

=head1 METHODS

Supports all methods provided by L<Lab::Moose::Instrument::ZI_MFLI>.

=head2 get_impedance_sample

 my $sample = $mfia->get_impedance_sample(timeout => $timeout);
 # keys in $sample: timeStamp, realz, imagz, frequency, phase, flags, trigger,
 # param0, param1, drive, bias

Return impedance sample as hashref. C<$timeout> argument is optional.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
