package KiokuDB::TypeMap::Entry::Std::ID;
BEGIN {
  $KiokuDB::TypeMap::Entry::Std::ID::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Std::ID::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Provides a default compile_id method

use namespace::clean -except => 'meta';

sub compile_id {
    my ( $self, $class, @args ) = @_;

    return "generate_uuid";
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Std::ID - Provides a default compile_id method

=head1 VERSION

version 0.57

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This role provides a default compile_id method.  It is designed to be used
in conjunction with other roles to create a full L<KiokuDB::TypeMap::Entry>
implementation.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
