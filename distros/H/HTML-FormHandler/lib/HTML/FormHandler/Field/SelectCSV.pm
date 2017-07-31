package HTML::FormHandler::Field::SelectCSV;
# ABSTRACT: Multiple select field from CSV value
$HTML::FormHandler::Field::SelectCSV::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Select';


has '+inflate_default_method' => ( default => sub { \&selectcsv_inflate_default } );
has '+deflate_value_method' => ( default => sub { \&selectcsv_deflate_value } );
has '+multiple' => ( default => 1 );
sub build_value_when_empty { undef }

sub selectcsv_inflate_default {
    my ( $self, $value ) = @_;
    if( defined $value ) {
        my @values = split (/,/, $value);
        return @values;
    }
    return;
}

sub selectcsv_deflate_value {
    my ( $self, $value ) = @_;
    if ( defined $value ) {
        my $str = join( ',', sort @$value );
        return $str;
    }
    return;
}

sub fif {
    my $self = shift;
    my $fif = $self->next::method;
    $fif = [] if $fif eq '';
    return $fif;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::SelectCSV - Multiple select field from CSV value

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

A multiple select field for comma-separated values in the database.
It expects database values like: '1,5,7'. The string will be inflated
into an arrayref for validation and form filling, and will be deflated
into a comma-separated string in the output value.

This field is useful for MySQL 'set' columns.

=head1 NAME

HTML::FormHandler::Field::SelectCSV

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
