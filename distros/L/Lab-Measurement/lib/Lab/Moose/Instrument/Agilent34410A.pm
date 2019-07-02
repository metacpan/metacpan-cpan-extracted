package Lab::Moose::Instrument::Agilent34410A;
$Lab::Moose::Instrument::Agilent34410A::VERSION = '3.682';
#ABSTRACT: Agilent 34410A digital multimeter.


use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::HP34410A';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x0957, pid => 0x0607 };
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Agilent34410A - Agilent 34410A digital multimeter.

=head1 VERSION

version 3.682

=head1 DESCRIPTION

Alias for L<Lab::Moose::Instrument::HP34410A> with adjusted USB vendor/product IDs.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
