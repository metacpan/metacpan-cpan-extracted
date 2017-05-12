package Gideon::Meta::Class::Trait::Persisted;
{
  $Gideon::Meta::Class::Trait::Persisted::VERSION = '0.0.3';
}
use Moose::Role;

#ABSTRACT: Persisted class role

has '__is_persisted' => ( is => 'rw', isa => 'Bool' );

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Class::Trait::Persisted - Persisted class role

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

Attribute used by Gideon to determine if an object is persisted within a data store
or not

=head1 NAME

Gideon::Meta::Class::Trait::Persisted

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
