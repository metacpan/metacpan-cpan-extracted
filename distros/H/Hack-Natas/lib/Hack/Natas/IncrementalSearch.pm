package Hack::Natas::IncrementalSearch;
use strict;
use warnings;
use v5.16.0;
our $VERSION = '0.003'; # VERSION
# ABSTRACT: do incremental searches for some Natas challenges

use Types::Standard qw(Int Str);
use Type::Utils qw(class_type);
use Moo::Role;
requires qw(
    password_length
    guess_next_char
    password
);

has password_so_far => (
    is      => 'rw',
    isa     => Str,
    default => sub { '' },
);


sub run {
    my $self = shift;

    foreach my $pos (1 .. $self->password_length) {
        $self->password_so_far( $self->password_so_far . $self->guess_next_char($pos) );
    }
    $self->password( $self->password_so_far );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Hack::Natas::IncrementalSearch - do incremental searches for some Natas challenges

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This is a role for incrementally guessing the password in one-character
slices. It provides a C<password_so_far> attribute, which is used to
build up the full password. It requires that consumers have:

=over 4

=item * password_length

An integer which tells us how long the password is, so the search will stop
once we have the whole thing.

=item * guess_next_char

A method which, when called with the current position in the password, returns
the next character.

=back

=head1 METHODS

=head2 run

This is the only method you need to call. It will do the search, and once
C<password_length> characters of the password have been guessed using
C<guess_next_char>, the C<password> attribute will be set.

=head1 AVAILABILITY

The project homepage is L<https://hashbang.ca/tag/natas>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Hack::Natas/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Hack-Natas>
and may be cloned from L<git://github.com/doherty/Hack-Natas.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Hack-Natas/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
