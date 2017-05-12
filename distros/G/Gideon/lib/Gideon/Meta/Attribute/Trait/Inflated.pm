package Gideon::Meta::Attribute::Trait::Inflated;
{
  $Gideon::Meta::Attribute::Trait::Inflated::VERSION = '0.0.3';
}
use Moose::Role;

#ABSTRACT: Inflated Role

Moose::Util::meta_attribute_alias('Gideon::Inflated');

requires 'get_inflator', 'get_deflator';

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Attribute::Trait::Inflated - Inflated Role

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

Interface for inflated attributes

=head1 NAME

Gideon::Meta::Attribute::Trait::Inflated - Inflated Role

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
