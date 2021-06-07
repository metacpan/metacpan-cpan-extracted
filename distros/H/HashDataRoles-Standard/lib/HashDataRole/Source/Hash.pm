package HashDataRole::Source::Hash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-21'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'HashDataRole::Spec::Basic';
with 'Role::TinyCommons::Collection::GetItemByPos'; # bonus

sub new {
    my ($class, %args) = @_;

    my $hash = delete $args{hash} or die "Please specify 'hash' argument";

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    # cache keys for iteration
    my $keys = [];
    for my $key (sort keys %$hash) {
        push @$keys, $key;
    }

    bless {
        hash => $hash,
        _keys => $keys,
        pos => 0,
    }, $class;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" unless $self->{pos} < @{ $self->{_keys} };
    my $key = $self->{_keys}->[ $self->{pos}++ ];
    [$key, $self->{hash}{$key}];
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @{ $self->{_keys} };
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
    scalar @{ $self->{_keys} };
}

sub get_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        die "Out of range" unless -$pos <= @{ $self->{_keys} };
    } else {
        die "Out of range" unless $pos < @{ $self->{_keys} };
    }
    my $key = $self->{_keys}->[$pos];
    [$key, $self->{hash}{$key}];
}

sub has_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        return -$pos <= @{ $self->{_keys} } ? 1:0;
    } else {
        return $pos < @{ $self->{_keys} } ? 1:0;
    }
}

sub get_item_at_key {
    my ($self, $key) = @_;
    die "No such key '$key'" unless exists $self->{hash}{$key};
    $self->{hash}{$key};
}

sub has_item_at_key {
    my ($self, $key) = @_;
    exists $self->{hash}{$key};
}

sub get_all_keys {
    my ($self, $key) = @_;
    @{$self->{_keys}};
}

1;
# ABSTRACT: Get hash data from a Perl hash

__END__

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Source::Hash - Get hash data from a Perl hash

=head1 VERSION

This document describes version 0.001 of HashDataRole::Source::Hash (from Perl distribution HashDataRoles-Standard), released on 2021-05-21.

=head1 SYNOPSIS

 my $hd = HashData::Array->new(hash => {one=>"satu", two=>"dua", three=>"tiga"});

=head1 DESCRIPTION

This role retrieves hash items from a Perl hash.

C<get_next_item()> and C<get_item_at_pos()> will return a pair of C<< [$key,
$value] >>. C<get_item_at_key()> will return just the pair value.

Internally, an array of keys will be constructed from the hash for deterministic
iteration using C<has_next_item()> and C<get_next_item()>.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<HashDataRole::Spec::Basic>

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-HashDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HashData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
