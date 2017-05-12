package KiokuDB::TypeMap::Entry::Alias;
BEGIN {
  $KiokuDB::TypeMap::Entry::Alias::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Alias::VERSION = '0.57';
use Moose;
# ABSTRACT: An alias in the typemap to another entry

use namespace::clean -except => 'meta';

has to => (
    isa => "Str",
    is  => "ro",
    required => 1,
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Alias - An alias in the typemap to another entry

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    my $typemap = KiokuDB::TypeMap->new(
        entries => {
            'Some::Class' => KiokuDB::TypeMap::Entry::Alias->new(
                to => "Some::Other::Class",
            ),
            'Some::Other::Class' => ...,
        },
    );

=head1 DESCRIPTION

This pseudo-entry directs the typemap resolution to re-resolve with the key in
the C<to> field.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
