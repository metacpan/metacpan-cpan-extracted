package KiokuDB::Role::Verbosity;
BEGIN {
  $KiokuDB::Role::Verbosity::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Verbosity::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for printing diagnosis to STDERR

use namespace::clean -except => 'meta';

has verbose => (
    isa => "Bool",
    is  => "ro",
);

sub BUILD {
    my $self = shift;

    STDERR->autoflush(1) if $self->verbose;
}

sub v {
    my $self = shift;
    return unless $self->verbose;

    STDERR->print(@_);
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Verbosity - A role for printing diagnosis to STDERR

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    $self->v("blah blah\n"); # only printed if $self->verbose is true

=head1 DESCRIPTION

This role provides the C<verbose> attribute and a C<v> method that you can use
to emit verbose output to C<STDERR>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
