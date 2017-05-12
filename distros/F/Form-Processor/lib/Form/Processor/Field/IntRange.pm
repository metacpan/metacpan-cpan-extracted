package Form::Processor::Field::IntRange;
$Form::Processor::Field::IntRange::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Select';


use Rose::Object::MakeMethods::Generic (
    scalar => [
        label_format => { interface => 'get_set_init' },
    ],
);


sub init_range_start  { return 1 }
sub init_range_end    { return 10 }
sub init_label_format { return '%d' }

sub init_options {
    my $self = shift;

    my $start = $self->range_start;
    my $end   = $self->range_end;

    for ( $start, $end ) {
        die 'Both range_start and range_end must be defined' unless defined $_;
        die 'Integer ranges must be integers' unless /^\d+$/;
    }

    die 'range_start must be less than range_end' unless $start < $end;

    my $format = $self->label_format || die 'IntRange needs label_format';

    return [
        map {
            { value => $_, label => sprintf( $format, $_ ) }
            } $self->range_start .. $self->range_end
    ];
}


# ABSTRACT: Select an integer range in a select list




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::IntRange - Select an integer range in a select list

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field generates a select list of numbers from 1 to 10.  The range can be
overridden in the constructor:

    age => {
        type        => 'IntRange',
        range_start => 0,
        range_end   => 100,
    },

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Select"

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
