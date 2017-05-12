package KiokuDB::Test::Digested;
BEGIN {
  $KiokuDB::Test::Digested::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Digested::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Role::ID::Digest
    KiokuDB::Role::Immutable::Transitive
    MooseX::Clone
);

has [qw(foo bar)] => ( is => "ro" );

sub digest_parts {
    my $self = shift;

    return $self->foo, $self->bar;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Digested

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
