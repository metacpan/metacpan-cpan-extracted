package HashData::Test::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-01'; # DATE
our $DIST = 'HashData'; # DIST
our $VERSION = '0.1.1'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;

with 'HashDataRole::Spec::Basic';

my $hash = {
    five  => "lima",
    four  => "empat",
    one   => "satu",
    three => "tiga",
    two   => "dua",
};
my $keys = [sort keys %$hash];

sub new {
    my $class = shift;
    bless {pos=>0}, $class;
}

sub _hash {
    my $self = shift;
    $hash;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" unless $self->{pos} < @$keys;
    my $key = $keys->[ $self->{pos}++ ];
    [$key, $hash->{$key}];
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @$keys;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_item_at_key {
    my ($self, $key) = @_;
    die "No such key '$key'" unless exists $hash->{$key};
    $hash->{$key};
}

sub has_item_at_key {
    my ($self, $key) = @_;
    exists $hash->{$key};
}

sub get_all_keys {
    my $self = shift;
    [@$keys];
}

1;

# ABSTRACT: A test hash data

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData::Test::Spec::Basic - A test hash data

=head1 VERSION

This document describes version 0.1.1 of HashData::Test::Spec::Basic (from Perl distribution HashData), released on 2021-06-01.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
