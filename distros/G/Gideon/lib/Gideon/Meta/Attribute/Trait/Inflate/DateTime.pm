package Gideon::Meta::Attribute::Trait::Inflate::DateTime;
{
  $Gideon::Meta::Attribute::Trait::Inflate::DateTime::VERSION = '0.0.3';
}
use Moose::Role;

with 'Gideon::Meta::Attribute::Trait::Inflated';

Moose::Util::meta_attribute_alias('Gideon::Inflate::DBI::DateTime');


sub get_inflator {
    my ( $self, $source ) = @_;
    $self->inflator;
}

sub get_deflator {
    my ( $self, $source ) = @_;
    $self->deflator;
}

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Attribute::Trait::Inflate::DateTime

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
