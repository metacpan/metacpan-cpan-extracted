package HTML::FormHandler::Field::TextCSV;
# ABSTRACT: CSV Text field from multiple
$HTML::FormHandler::Field::TextCSV::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';


has '+deflate_method' => ( default => sub { \&textcsv_deflate } );
has '+inflate_method' => ( default => sub { \&textcsv_inflate } );
has 'multiple' => ( isa => 'Bool', is => 'rw', default => '0' );
sub build_value_when_empty { [] }
sub _inner_validate_field {
    my $self = shift;
    my $value = $self->value;
    return unless $value;
    if ( ref $value ne 'ARRAY' ) {
        $value = [$value];
        $self->_set_value($value);
    }
}

sub textcsv_deflate {
    my ( $self, $value ) = @_;
    if( defined $value && length $value ) {
        my $value = ref $value eq 'ARRAY' ? $value : [$value];
        my $new_value = join(',', @$value);
        return $new_value;
    }
    return $value;
}

sub textcsv_inflate {
    my ( $self, $value ) = @_;
    if ( defined $value && length $value ) {
        my @values = split(/,/, $value);
        return \@values;
    }
    return $value;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::TextCSV - CSV Text field from multiple

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

A text field that takes multiple values from a database and converts
them to comma-separated values. This is intended for javascript fields
that require that, such as 'select2'.

=head1 NAME

HTML::FormHandler::Field::TextCSV

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
