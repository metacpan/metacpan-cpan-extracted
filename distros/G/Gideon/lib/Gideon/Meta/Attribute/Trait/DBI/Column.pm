package Gideon::Meta::Attribute::Trait::DBI::Column;
{
  $Gideon::Meta::Attribute::Trait::DBI::Column::VERSION = '0.0.3';
}
use Moose::Role;

#ABSTRACT: Column attribute trait

Moose::Util::meta_attribute_alias('Gideon::DBI::Column');

has column      => ( is => 'ro', isa => 'Str' );
has primary_key => ( is => 'ro', isa => 'Bool' );
has serial      => ( is => 'ro', isa => 'Bool' );

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Attribute::Trait::DBI::Column - Column attribute trait

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

It add properties to the attribute that Gideon::Driver::DBI uses to operate on
RDB

=head1 NAME

Gideon::Meta::Attribute::Trait::DBI::Column - Column attribute trait

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
