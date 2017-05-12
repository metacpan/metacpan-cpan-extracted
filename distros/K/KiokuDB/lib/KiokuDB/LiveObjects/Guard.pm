package KiokuDB::LiveObjects::Guard;
BEGIN {
  $KiokuDB::LiveObjects::Guard::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::LiveObjects::Guard::VERSION = '0.57';
use strict;
use warnings;

use Scalar::Util qw(weaken);

use namespace::clean -except => 'meta';

sub new {
    my ( $class, $hash, $key ) = @_;
    my $self = bless [ $hash, $key ], $class;
    weaken $self->[0];
    return $self;
}

sub key {
    $_[0][1];
}

sub DESTROY {
    my $self = shift;
    my ( $hash, $key ) = splice @$self;
    delete $hash->{$key} if $hash;
}

sub dismiss {
    my $self = shift;
    @$self = ();
}


__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::LiveObjects::Guard

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
