package HashDataRole::Source::LinesInDATA;

use Role::Tiny;
use Role::Tiny::With;
with 'HashDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.004'; # VERSION

sub new {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my ($class, %args) = @_;

    my $fh = \*{"$class\::DATA"};
    my $fhpos_data_begin;
    if (defined ${"$class\::_HashData_fhpos_data_begin_cache"}) {
        $fhpos_data_begin = ${"$class\::_HashData_fhpos_data_begin_cache"};
        seek $fh, $fhpos_data_begin, 0;
    } else {
        $fhpos_data_begin = ${"$class\::_HashData_fhpos_data_begin_cache"} = tell $fh;
    }

    bless {
        fh => $fh,
        separator => $args{separator} // ':',
        fhpos_data_begin => $fhpos_data_begin,
        pos => 0, # iterator
    }, $class;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" if eof($self->{fh});
    $self->{fhpos_cur_item} = tell($self->{fh});
    chomp(my $line = readline($self->{fh}));
    my ($key, $value) = split /\Q$self->{separator}\E/, $line, 2 or die "Invalid line at position $self->{pos}: no separator ':'";
    $self->{pos}++;
    [$key, $value];
}

sub has_next_item {
    my $self = shift;
    !eof($self->{fh});
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    seek $self->{fh}, $self->{fhpos_data_begin}, 0;
    $self->{pos} = 0;
}

sub _get_pos_cache {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $self = shift;

    my $class = $self->{orig_class} // ref($self);
    return ${"$class\::_HashData_pos_cache"}
        if defined ${"$class\::_HashData_pos_cache"};

    # build
    my $pos_cache = [];
    $self->reset_iterator;
    while ($self->has_next_item) {
        $self->get_next_item;
        push @$pos_cache, $self->{fhpos_cur_item};
    }
    #use DD; dd $pos_cache;
    ${"$class\::_HashData_pos_cache"} = $pos_cache;
}

sub _get_hash_cache {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $self = shift;

    my $class = $self->{orig_class} // ref($self);
    return ${"$class\::_HashData_hash_cache"}
        if defined ${"$class\::_HashData_hash_cache"};

    my $hash_cache = {};
    $self->reset_iterator;
    while ($self->has_next_item) {
        my $item = $self->get_next_item;
        $hash_cache->{$item->[0]} = $self->{fhpos_cur_item};
    }
    #use DD; dd $hash_cache;
    ${"$class\::_HashData_hash_cache"} = $hash_cache;
}

sub get_item_at_pos {
    my ($self, $pos) = @_;

    my $pos_cache = $self->_get_pos_cache;
    if ($pos < 0) {
        die "Out of range" unless -$pos <= @{ $pos_cache };
    } else {
        die "Out of range" unless $pos < @{ $pos_cache };
    }

    my $oldfhpos = tell $self->{fh};
    seek $self->{fh}, $pos_cache->[$pos], 0;
    chomp(my $line = readline($self->{fh}));
    my ($key, $value) = split /\Q$self->{separator}\E/, $line, 2;
    seek $self->{fh}, $oldfhpos, 0;
    [$key, $value];
}

sub has_item_at_pos {
    my ($self, $pos) = @_;

    my $pos_cache = $self->_get_pos_cache;
    if ($pos < 0) {
        return -$pos <= @{ $pos_cache } ? 1:0;
    } else {
        return $pos < @{ $pos_cache } ? 1:0;
    }
}

sub get_item_at_key {
    my ($self, $key) = @_;

    my $hash_cache = $self->_get_hash_cache;
    die "No such key '$key'" unless exists $hash_cache->{$key};

    my $oldfhpos = tell $self->{fh};
    seek $self->{fh}, $hash_cache->{$key}, 0;
    chomp(my $line = readline($self->{fh}));
    my (undef, $value) = split /\Q$self->{separator}\E/, $line, 2;
    seek $self->{fh}, $oldfhpos, 0;
    $value;
}

sub has_item_at_key {
    my ($self, $key) = @_;

    my $hash_cache = $self->_get_hash_cache;
    exists $hash_cache->{$key};
}

sub get_all_keys {
    my ($self, $key) = @_;

    my $hash_cache = $self->_get_hash_cache;
    sort %$hash_cache;
}


sub fh {
    my $self = shift;
    $self->{fh};
}

sub fh_min_offset {
    my $self = shift;
    $self->{fhpos_data_begin};
}

sub fh_max_offset { undef }

1;
# ABSTRACT: Role to access hash data from DATA section, one line per item

__END__

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Source::LinesInDATA - Role to access hash data from DATA section, one line per item

=head1 VERSION

This document describes version 0.004 of HashDataRole::Source::LinesInDATA (from Perl distribution HashDataRoles-Standard), released on 2024-05-06.

=head1 DESCRIPTION

This role expects lines in the DATA section in the form of:

 <key>:<value>

Internally, a hash cache is built to speed up C<get_item_by_key>. Another array
cache is also built to speed up C<get_item_by_pos>.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<ArrayDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 new

Constructor. Arguments:

=over

=item * separator

Str. Separator character. Defaults to C<:> (colon).

=back

=head2 fh

Returns the DATA filehandle.

=head2 fh_min_offset

Returns the starting position of DATA.

=head2 fh_max_offset

Returns C<undef>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 SEE ALSO

Other C<HashDataRole::Source::*>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
