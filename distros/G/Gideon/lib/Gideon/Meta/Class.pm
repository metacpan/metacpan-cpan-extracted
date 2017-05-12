package Gideon::Meta::Class;
{
  $Gideon::Meta::Class::VERSION = '0.0.3';
}
use Moose::Role;

#ABSTRACT: Gideon metaclass

has store => ( is => 'rw', isa => 'Str' );

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Class - Gideon metaclass

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

All Gideon classes use this metaclass

=head1 NAME

Gideon::Meta::Class - Metaclass for all Gideon classes

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
