package HashData::Test::Spec::Basic;

use strict;
use warnings;

use Role::Tiny::With;

with 'HashDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-22'; # DATE
our $DIST = 'HashData'; # DIST
our $VERSION = '0.1.2'; # VERSION

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

This document describes version 0.1.2 of HashData::Test::Spec::Basic (from Perl distribution HashData), released on 2024-01-22.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashData>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
