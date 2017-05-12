package KiokuDB::Backend::Role::Query::GIN;
BEGIN {
  $KiokuDB::Backend::Role::Query::GIN::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::Query::GIN::VERSION = '0.57';
use Moose::Role;

use namespace::clean -except => 'meta';

with qw(
    Search::GIN::Extract
    Search::GIN::Driver
);

has distinct => (
    isa => "Bool",
    is  => "rw",
    default => 0, # FIXME what should the default be?
);

sub search {
    my ( $self, $query, @args ) = @_;

    my %args = (
        distinct => $self->distinct,
        @args,
    );

    my @spec = $query->extract_values($self);

    my $ids = $self->fetch_entries(@spec);

    $ids = unique($ids) if $args{distinct};

    return $ids->filter(sub {[ $self->get(@$_) ]});
}

sub search_filter {
    my ( $self, $objects, $query, @args ) = @_;
    return $objects->filter(sub { [ grep { $query->consistent($self, $_) } @$_ ] });
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::Query::GIN

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
