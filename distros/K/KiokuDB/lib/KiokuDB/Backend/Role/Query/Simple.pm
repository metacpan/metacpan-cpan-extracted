package KiokuDB::Backend::Role::Query::Simple;
BEGIN {
  $KiokuDB::Backend::Role::Query::Simple::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::Query::Simple::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Simple query api

use namespace::clean -except => 'meta';

requires "simple_search";

sub simple_search_filter {
    my ( $self, $stream, $proto ) = @_;
    return $stream;
}

# FIXME unify with Attribute, and put this in the default simple_search_filter
# implementation
# that way *really* lazy backends can just alias simple_search to scan and
# still be feature complete even if they are retardedly slow

sub compare_naive {
    my ( $self, $got, $exp ) = @_;

    foreach my $key ( keys %$exp ) {
        return unless overload::StrVal($got->{$key}) eq overload::StrVal($exp->{$key});
    }

    return 1;
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::Query::Simple - Simple query api

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Backend::Role::Query::Simple);

    sub simple_search {
        my ( $self, $proto ) = @_;

        # return all candidate entries in the root set matching fields in $proto
        return Data::Stream::Bulk::Foo->new(...);
    }

=head1 DESCRIPTION

This role requires a C<simple_search> method to be implemented.

The method accepts one argument, the hash of the proto to search for.

This is still loosely defined, but the basic functionality is based on
attribute matching:

    $kiokudb->search({ name => "Mia" });

will search for objects whose C<name> attribute contains the string C<Mia>.

More complex operations will be defined in the future.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
