package Fey::Hash::ColumnsKey;

use strict;
use warnings;

our $VERSION = '0.47';

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub get {
    my $self     = shift;
    my $key_cols = shift;

    my $key = join "\0", map { $_->name() } @{$key_cols};

    return $self->{$key};
}

sub store {
    my $self     = shift;
    my $key_cols = shift;
    my $sql      = shift;

    my $key = join "\0", map { $_->name() } @{$key_cols};

    return $self->{$key} = $sql;
}

1;

# ABSTRACT: A hash where the keys are sets of Fey::Column objects

__END__

=pod

=head1 NAME

Fey::Hash::ColumnsKey - A hash where the keys are sets of Fey::Column objects

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  my $hash = Fey::Hash::ColumnsKey->new();

  $hash->store( [ $col1, $col2 ] => $sql );

=head1 DESCRIPTION

This class is a helper for L<Fey::Meta::Class::Table>. It is used to
cache SQL statements with a set of columns as the key. You should
never need to use it directly.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
