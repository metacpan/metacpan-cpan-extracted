package HashDataRole::Source::DBI;

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'HashDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.003'; # VERSION

sub new {
    my ($class, %args) = @_;

    my $dsn      = delete $args{dsn};
    my $user     = delete $args{user};
    my $password = delete $args{password};
    my $dbh = delete $args{dbh};
    if (defined $dbh) {
    } elsif (defined $dsn) {
        require DBI;
        $dbh = DBI->connect($dsn, $user, $password, {RaiseError=>1});
    }

    my $table      = delete $args{table};  # XXX quote
    my $key_column = delete $args{key_column}; # XXX quote
    my $val_column = delete $args{val_column}; # XXX quote

    my $iterate_sth    = delete $args{iterate_sth};
    unless (defined $iterate_sth) {
        die "You don't specify 'iterate_sth', so you must specify ".
            "dbh/dsn+user+password & table & key_column & val_column, ".
            "so I can create a statement handle"
            unless $dbh && defined($table) && defined($key_column) && defined($val_column);
        my $query = "SELECT $key_column,$val_column FROM $table";
        $iterate_sth = $dbh->prepare($query);
    }

    my $get_by_key_sth = delete $args{get_by_key_sth};
    unless (defined $get_by_key_sth) {
        die "You don't specify 'iterate_sth', so you must specify ".
            "dbh/dsn+user+password & table & key_column & val_column, ".
            "so I can create a statement handle"
            unless $dbh && defined($table) && defined($key_column) && defined($val_column);
        my $query = "SELECT $val_column FROM $table WHERE $key_column=?";
        $get_by_key_sth = $dbh->prepare($query);
    }

    my $row_count_sth = delete $args{row_count_sth};
    unless (defined $row_count_sth) {
        die "You don't specify 'iterate_sth', so you must specify ".
            "dbh/dsn+user+password & table, ".
            "so I can create a statement handle"
            unless $dbh && defined($table);
        my $query = "SELECT COUNT(*) FROM $table";
        $row_count_sth = $dbh->prepare($query);
    }

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        #dbh => $dbh,
        iterate_sth => $iterate_sth,
        get_by_key_sth => $get_by_key_sth,
        row_count_sth => $row_count_sth,
        pos => undef, # iterator pos
        #buf => '', # exists when there is a buffer
    }, $class;
}

sub get_next_item {
    my $self = shift;
    $self->reset_iterator unless defined $self->{pos};

    if (exists $self->{buf}) {
        $self->{pos}++;
        return delete $self->{buf};
    } else {
        my $row = $self->{iterate_sth}->fetchrow_arrayref;
        die "StopIteration" unless $row;
        $self->{pos}++;
        [$row->[0], $row->[1]];
    }
}

sub has_next_item {
    my $self = shift;
    $self->reset_iterator unless defined $self->{pos};

    if (exists $self->{buf}) {
        return 1;
    }
    my $row = $self->{iterate_sth}->fetchrow_arrayref;
    return 0 unless $row;
    $self->{buf} = [$row->[0], $row->[1]];
    1;
}

sub get_item_count {
    my $self = shift;
    $self->{row_count_sth}->execute;
    my ($row_count) = $self->{row_count_sth}->fetchrow_array;
    $row_count;
}

sub reset_iterator {
    my $self = shift;
    $self->{iterate_sth}->execute;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub get_item_at_pos {
    my ($self, $pos) = @_;
    $self->reset_iterator if $self->{pos} > $pos;
    while (1) {
        die "Out of range" unless $self->has_next_item;
        my $item = $self->get_next_item;
        return $item if $self->{pos} > $pos;
    }
}

sub has_item_at_pos {
    my ($self, $pos) = @_;
    return 1 if $self->{pos} > $pos;
    while (1) {
        return 0 unless $self->has_next_item;
        $self->get_next_item;
        return 1 if $self->{pos} > $pos;
    }
}

sub get_item_at_key {
    my ($self, $key) = @_;
    $self->{get_by_key_sth}->execute($key);
    my $row = $self->{get_by_key_sth}->fetchrow_arrayref;
    die "No such key '$key'" unless $row;
    $row->[0];
}

sub has_item_at_key {
    my ($self, $key) = @_;
    $self->{get_by_key_sth}->execute($key);
    my $row = $self->{get_by_key_sth}->fetchrow_arrayref;
    $row ? 1:0;
}

sub get_all_keys {
    my $self = shift;
    my @keys;
    $self->reset_iterator;
    while ($self->has_next_item) {
        my $item = $self->get_next_item;
        push @keys, $item->[0];
    }
    @keys;
}

1;
# ABSTRACT: Role to access elements from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Source::DBI - Role to access elements from DBI

=head1 VERSION

This document describes version 0.003 of HashDataRole::Source::DBI (from Perl distribution HashDataRoles-Standard), released on 2024-01-15.

=head1 DESCRIPTION

This role expects hash data in L<DBI> database table or query.

Note: C<get_item_at_pos()> and C<has_item_at_pos()> are slow (O(n) in worst
case) because they iterate. Caching might be added in the future to speed this
up.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<HashDataRole::Spec::Basic>

=head1 METHODS

=head2 new

Usage:

 my $ary = $CLASS->new(%args);

Arguments:

=over

=item * iterate_sth

=item * get_by_key_sth

=item * row_count_sth

=item * dbh

=item * query

=item * table

=item * key_column

=item * val_column

Either all the C<*_sth> or L</dbh> + L</table> + L</key_column> + L</val_column>
is required.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 SEE ALSO

L<DBI>

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

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
