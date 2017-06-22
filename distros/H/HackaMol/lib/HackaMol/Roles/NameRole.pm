package HackaMol::Roles::NameRole;
$HackaMol::Roles::NameRole::VERSION = '0.040';
#ABSTRACT: provides name attribute
use 5.008;
use Moose::Role;

has 'name', is => 'rw', isa => 'Str', predicate => 'has_name' , clearer => 'clear_name';

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::NameRole - provides name attribute

=head1 VERSION

version 0.040

=head1 DESCRIPTION

simple role for the shared attribute 'name'. isa Str that is rw. useful for labeling, 
bookkeeping...

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
