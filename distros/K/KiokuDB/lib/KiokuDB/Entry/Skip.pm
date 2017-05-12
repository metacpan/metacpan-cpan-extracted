package KiokuDB::Entry::Skip;
BEGIN {
  $KiokuDB::Entry::Skip::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Entry::Skip::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

has prev => (
    isa => "KiokuDB::Entry",
    is  => "ro",
    handles => [qw(id)],
);

has root => (
    isa => "Bool",
    is  => "rw",
    predicate => "has_root",
);

has object => (
    isa => "Any",
    is  => "rw",
    weak_ref => 1,
    predicate => "has_object",
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Entry::Skip

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
