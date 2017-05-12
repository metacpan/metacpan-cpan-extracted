package Gideon::Meta::Attribute::Trait::Inflate;
{
  $Gideon::Meta::Attribute::Trait::Inflate::VERSION = '0.0.3';
}
use Moose::Role;

#ABSTRACT: Inflated attribute

with 'Gideon::Meta::Attribute::Trait::Inflated';

Moose::Util::meta_attribute_alias('Gideon::Inflate');

has inflator => ( is => 'ro', isa => 'CodeRef' );
has deflator => ( is => 'ro', isa => 'CodeRef' );

sub get_inflator {
    my $self = shift;
    $self->inflator;
}

sub get_deflator {
    my $self = shift;
    $self->deflator;
}

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Attribute::Trait::Inflate - Inflated attribute

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  # Store a document as JSON in the database

  package Document;
  use Gideon driver => 'DBI';
  use JSON;

  ...

  has content => (
    is => 'rw',
    traits => [ 'Gideon::DBI::Column', 'Gideon::Inflate' ],
    inflator => sub { decode_json $_[0] },
    deflator => sub { encode_json $_[0] }
  );

=head1 DESCRIPTION

It allows you to configurate an inflate and deflate methods for an attribute,
Gideon will use the C<inflator> method when retrieving the information from a
data store, and the C<deflator> before storing the information in the data store

=head1 NAME

Gideon::Meta::Attribute::Trait::Inflated - Inflated attribute

=head1 VERSION

version 0.0.3

=head1 ALIAS

Gideon::Inflate

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
