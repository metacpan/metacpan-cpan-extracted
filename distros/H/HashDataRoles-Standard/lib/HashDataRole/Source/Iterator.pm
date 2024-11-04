package HashDataRole::Source::Iterator;

use strict;
use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'HashDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-04'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.005'; # VERSION

sub _new {
    my ($class, %args) = @_;

    my $gen_iterator = delete $args{gen_iterator} or die "Please specify 'gen_iterator' argument";
    my $gen_iterator_params = delete $args{gen_iterator_params} // {};

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        gen_iterator => $gen_iterator,
        gen_iterator_params => $gen_iterator_params,
        iterator => undef,
        pos => 0,
        # buf => '', # exists when there is a buffer
    }, $class;
}

sub get_next_item {
    my $self = shift;
    $self->reset_iterator unless $self->{iterator};
    if (exists $self->{buf}) {
        $self->{pos}++;
        return delete $self->{buf};
    } else {
        my ($key, $val) = $self->{iterator}->();
        die "StopIteration" unless defined $key;
        $self->{pos}++;
        return [$key, $val];
    }
}

sub has_next_item {
    my $self = shift;
    if (exists $self->{buf}) {
        return 1;
    }
    $self->reset_iterator unless $self->{iterator};
    my ($key,$val) = $self->{iterator}->();
    return 0 unless defined $key;
    $self->{buf} = [$key,$val];
    1;
}

sub reset_iterator {
    my $self = shift;
    $self->{iterator} = $self->{gen_iterator}->(%{ $self->{gen_iterator_params} });
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub get_item_at_key {
    my ($self, $key) = @_;
    $self->reset_iterator;
    while (1) {
        return unless $self->has_next_item;
        my $item = $self->get_next_item;
        return $item if $item->[0] eq $key;
    }
}

sub has_item_at_key {
    my ($self, $key) = @_;
    $self->reset_iterator;
    while (1) {
        return 0 unless $self->has_next_item;
        my $item = $self->get_next_item;
        return 1 if $item->[0] eq $key;
    }
}

sub get_all_keys {
    my ($self) = @_;
    $self->reset_iterator;
    my @keys;
    while (1) {
        last unless $self->has_next_item;
        my $item = $self->get_next_item;
        push @keys, $item->[0];
    }
    @keys;
}

1;
# ABSTRACT: Get hash data from an iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Source::Iterator - Get hash data from an iterator

=head1 VERSION

This document describes version 0.005 of HashDataRole::Source::Iterator (from Perl distribution HashDataRoles-Standard), released on 2024-11-04.

=head1 SYNOPSIS

 package HashData::YourHash;
 use Role::Tiny::With;
 with 'HashDataRole::Source::Iterator';

 sub new {
     my $class = shift;
     $class->_new(
         gen_iterator => sub {
             return sub {
                 ...
             };
         },
     );
 }

=head1 DESCRIPTION

This role retrieves pairs from a simplistic iterator (a coderef). When called,
the iterator must return a non-undef element or undef to signal that all
pairs have been iterated.

C<reset_iterator()> will regenerate a new iterator.

Note: C<get_item_at_key()> and C<has_item_at_key()> are slow (O(n) in worst
case) and inefficient because they regenerate iterator and iterate everytime.
Caching might be added in the future to speed this up.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<HashDataRole::Spec::Basic>

=head1 METHODS

=head2 _new

Create object. This should be called by a consumer's C<new>. Usage:

 my $hash = $CLASS->_new(%args);

Arguments:

=over

=item * gen_iterator

Coderef. Required. Must return another coderef which is the iterator.

=back

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
