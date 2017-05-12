package Form::Processor::Field::USZipcode;
$Form::Processor::Field::USZipcode::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';



sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    return $self->add_error( 'US Zip code must be 5 or 9 digits' )
        unless $self->input =~ /^(\s*\d{5}(?:[-]\d{4})?\s*)$/;

    return 1;
}


# ABSTRACT: Checks that input looks like a US Zip.




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::USZipcode - Checks that input looks like a US Zip.

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field simply looks for a 5 or 9 digit number.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

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
