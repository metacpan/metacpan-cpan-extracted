package File::KeePass::KDBX::Tie::GroupList;
# ABSTRACT: Database group list

use warnings;
use strict;

use File::KDBX::Loader::KDB;

use parent 'Tie::Array';

our $VERSION = '0.901'; # VERSION

sub TIEARRAY {
    my $class = shift;
    my $self = bless [@_], $class;
    splice(@$self, 1, 0, '_kpx_groups') if @$self == 2;
    return $self;
}

sub FETCH {
    my ($self, $index) = @_;
    my ($thing, $method, $k) = @$self;
    my $group = $thing->$method->[$index] or return;
    return $k->_tie({}, 'Group', $k->kdbx->_wrap_group($group));
}

sub FETCHSIZE {
    my ($self) = @_;
    my ($thing, $method) = @$self;
    return scalar @{$thing->$method};
}

sub STORE {
    my ($self, $index, $value) = @_;
    return if !$value;
    my ($thing, $method, $k) = @$self;
    my $group_info = File::KDBX::Loader::KDB::_convert_keepass_to_kdbx_group($value);
    %$value = ();
    return $k->_tie($value, 'Group', $thing->$method->[$index] = $k->kdbx->_wrap_group($group_info));
}

sub STORESIZE {
    my ($self, $count) = @_;
    my ($thing, $method) = @$self;
    splice @{$thing->$method}, $count;
}

sub EXISTS {
    my ($self, $index) = @_;
    my ($thing, $method) = @$self;
    return exists $thing->$method->[$index];
}

sub DELETE {
    my ($self, $index) = @_;
    my ($thing, $method) = @$self;
    delete $thing->$method->[$index];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX::Tie::GroupList - Database group list

=head1 VERSION

version 0.901

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KeePass-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
