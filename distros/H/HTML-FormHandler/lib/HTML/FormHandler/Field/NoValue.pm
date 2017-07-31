package HTML::FormHandler::Field::NoValue;
# ABSTRACT: base class for submit field
$HTML::FormHandler::Field::NoValue::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field';


has 'html' => ( is => 'rw', isa => 'Str', default => '' );
has 'value' => (
    is        => 'rw',
    predicate => 'has_value',
    clearer   => 'clear_value',
);

sub _result_from_fields {
    my ( $self, $result ) = @_;
    my $value = $self->get_default_value;
    if ( $value ) {
        $self->value($value);
    }
    $self->_set_result($result);
    $result->_set_field_def($self);
    return $result;
}

sub _result_from_input {
    my ( $self, $result, $input, $exists ) = @_;
    $self->_set_result($result);
    $result->_set_field_def($self);
    return $result;
}

sub _result_from_object {
    my ( $self, $result, $value ) = @_;
    $self->_set_result($result);
    $result->_set_field_def($self);
    return $result;
}

sub fif { }

has '+widget'    => ( default => '' );
has '+noupdate'  => ( default => 1 );

sub validate_field { }

#sub clear_value { }

sub render {
    my $self = shift;
    return $self->html;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::NoValue - base class for submit field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This is the base class for the Submit & Reset fields. It can be used for fields that
do not produce valid 'values'. It should not be used for fields that
produce a value or need validating.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
