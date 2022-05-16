package File::KeePass::KDBX::Tie::AssociationList;
# ABSTRACT: Auto-type window association list

use warnings;
use strict;

use parent 'Tie::Array';

our $VERSION = '0.902'; # VERSION

sub TIEARRAY {
    my $class = shift;
    return bless [@_], $class;
}

sub FETCH {
    my ($self, $index) = @_;
    my ($entry, $k) = @$self;
    my $association = $entry->auto_type->{associations}[$index] or return;
    return $k->_tie({}, 'Association', $association);
}

sub FETCHSIZE {
    my ($self) = @_;
    my ($entry) = @$self;
    return scalar @{$entry->auto_type->{associations} || []};
}

sub STORE {
    my ($self, $index, $value) = @_;
    my ($entry, $k) = @$self;
    my %info = %$value;
    %$value = ();
    my $association = $entry->auto_type->{associations}[$index] = {
        window              => $info{window},
        keystroke_sequence  => $info{keys},
    };
    return $k->_tie($value, 'Association', $association);
}

sub STORESIZE {
    my ($self, $count) = @_;
    my ($entry) = @$self;
    splice @{$entry->auto_type->{associations}}, $count;
}

sub EXISTS {
    my ($self, $index) = @_;
    my ($entry) = @$self;
    return exists $entry->auto_type->{associations}[$index];
}

sub DELETE {
    my ($self, $index) = @_;
    my ($entry) = @$self;
    delete $entry->auto_type->{associations}[$index];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KeePass::KDBX::Tie::AssociationList - Auto-type window association list

=head1 VERSION

version 0.902

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
