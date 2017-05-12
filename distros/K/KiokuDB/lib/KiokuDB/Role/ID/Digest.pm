package KiokuDB::Role::ID::Digest;
BEGIN {
  $KiokuDB::Role::ID::Digest::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::ID::Digest::VERSION = '0.57';
use Moose::Role;

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Role::ID::Content
    KiokuDB::Role::WithDigest
);

sub kiokudb_object_id { shift->digest }

#has '+digest' => ( traits => [qw(KiokuDB::ID)] ); # to avoid data redundancy?

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::ID::Digest

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
