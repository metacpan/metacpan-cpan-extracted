package Form::Processor::Field::Boolean;
$Form::Processor::Field::Boolean::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field';


sub init_widget { return 'radio' }    # although not really used.


sub value {
    my $self = shift;

    my $v = $self->SUPER::value( @_ );

    return unless defined $v;

    return $v ? 1 : 0;
}


# ABSTRACT: A true or false field


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Boolean - A true or false field

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field returnes undef if no value is defined, 0 if defined and false,
and 1 if defined and true.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "radio".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

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
