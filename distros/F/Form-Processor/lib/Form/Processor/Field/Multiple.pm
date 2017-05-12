package Form::Processor::Field::Multiple;
$Form::Processor::Field::Multiple::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Select';



sub init_multiple {1}    # allow multiple values.

sub init_size {5}        # default to showing five items if showing in a select list.



sub options {
    my $self    = shift;
    my @options = $self->SUPER::options( @_ );
    my $value   = $self->value;


    # This places the currently selected options at the top of the list
    # Makes the drop down lists a bit nicer

    if ( @options && defined $value ) {
        my %selected = map { $_ => 1 } ref( $value ) eq 'ARRAY' ? @$value : ( $value );

        my @out = grep { $selected{ $_->{value} } } @options;
        push @out, grep { !$selected{ $_->{value} } } @options;

        return wantarray ? @out : \@out;
    }

    return wantarray ? @options : \@options;
}


# ABSTRACT: Select one or more options



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Multiple - Select one or more options

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This inherits from the Select field, which just provides options.
and sets the "multiple" flag true to accept multiple options.
If a field inherits from Select but you want to use it as a multiple
select then just define the file as such.

This also will arrange the currently selected items to the top of the list.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Select".

=head1 METHODS

=head2 options

This options methods will re-arrange the opitions list to display
the currently selected items on top.

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
