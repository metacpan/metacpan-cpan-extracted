package Hash::Persistent::Memory;

# ABSTRACT: in-memory persistent object which doesn't really store anything

use strict;
use warnings;

sub new {
    return bless {} => shift;
}

sub commit {}

# we probably should cleanup $self contents, but Hash::Persistent currently doesn't do it.
sub remove {
    my $self = shift;
    delete $self->{$_} for keys %$self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Persistent::Memory - in-memory persistent object which doesn't really store anything

=head1 VERSION

version 1.02

=head1 AUTHORS

=over 4

=item *

Vyacheslav Matyukhin <me@berekuk.ru>

=item *

Andrei Mishchenko <druxa@yandex-team.ru>

=item *

Artyom V. Kulikov <breqwas@yandex-team.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
