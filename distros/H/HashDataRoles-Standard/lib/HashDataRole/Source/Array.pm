package HashDataRole::Source::Array;

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;

with 'HashDataRole::Spec::Basic';
with 'Role::TinyCommons::Collection::GetItemByPos'; # bonus

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-04'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.005'; # VERSION

sub new {
    my ($class, %args) = @_;

    my $ary = delete $args{array} or die "Please specify 'array' argument";

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    # create a hash from an array for quick lookup by key. we also check for
    # duplicates here.
    my $hash = {};
    for my $elem (@$ary) {
        die "Duplicate key '$elem->[0]'" if exists $hash->{$elem->[0]};
        $hash->{$elem->[0]} = $elem;
    }

    bless {
        array => $ary,
        _hash => $hash,
        pos => 0,
    }, $class;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" unless $self->{pos} < @{ $self->{array} };
    $self->{array}->[ $self->{pos}++ ];
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @{ $self->{array} };
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub get_item_count {
    my $self = shift;
    scalar @{ $self->{array} };
}

sub get_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        die "Out of range" unless -$pos <= @{ $self->{array} };
    } else {
        die "Out of range" unless $pos < @{ $self->{array} };
    }
    $self->{array}->[ $pos ];
}

sub has_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        return -$pos <= @{ $self->{array} } ? 1:0;
    } else {
        return $pos < @{ $self->{array} } ? 1:0;
    }
}

sub get_item_at_key {
    my ($self, $key) = @_;
    die "No such key '$key'" unless exists $self->{_hash}{$key};
    $self->{_hash}{$key}[1];
}

sub has_item_at_key {
    my ($self, $key) = @_;
    exists $self->{_hash}{$key};
}

sub get_all_keys {
    my ($self, $key) = @_;
    # to be more deterministic
    sort keys %{$self->{_hash}};
}

1;
# ABSTRACT: Get hash data from a Perl array

__END__

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Source::Array - Get hash data from a Perl array

=head1 VERSION

This document describes version 0.005 of HashDataRole::Source::Array (from Perl distribution HashDataRoles-Standard), released on 2024-11-04.

=head1 SYNOPSIS

 my $hd = HashData::Array->new(array => [["one","satu"], ["two","dua"], ["three","tiga"]]);

=head1 DESCRIPTION

This role retrieves hash items from a Perl array. Each array element must in
turn be a two-element array.

C<get_next_item()> and C<get_item_at_pos()> will return a pair of C<< [$key,
$value] >>. C<get_item_at_key()> will return just the pair value.

Internally, a hash will be constructed from the array for quick lookup of key.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<HashDataRole::Spec::Basic>

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 SEE ALSO

L<HashData>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
