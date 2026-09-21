package File::SOPS::Format::ENV::Ordered;
# ABSTRACT: the tied hash that keeps a flat format's parse in document order
our $VERSION = '0.004';
use strict;
use warnings;
use namespace::clean;

###############################################################################
# A ~15-line Tie::Hash is what "order preserving" means for a format whose
# parser has none: docs/adr/0036's condition 2 says a tied hash "and nothing
# else", because `keys` is what File::SOPS::_document_leaves walks.
#
# YAML::PP's own ordered hash (YAML::PP::Preserve::Hash) is not a separately
# loadable class and Tie::IxHash is not a prerequisite of this distribution, so
# this is the cheapest thing that meets the contract. Only STORE, FETCH, EXISTS
# and the iteration pair are exercised by the two handlers; the rest are here
# so that the tie is not a trap for a later caller.
#
# This module knows nothing about either format and loads nothing from this
# distribution -- Format::ENV and Format::INI load IT, and the dependency runs
# only that way.
#
# k158 moved it out of File/SOPS/Format/ENV.pm, where k36's
# one-new-file boundary put it, WITHOUT renaming it: both handlers already tie
# to this package name, and the move is meant to change nothing at all. It
# keeps ENV's namespace because that is the handler it was written for; INI
# uses it where it stands rather than growing a second copy, which is how the
# two would drift apart.
###############################################################################


sub TIEHASH  { bless { order => [], value => {}, at => 0 }, $_[0] }
sub STORE    {
    my ($self, $key, $value) = @_;
    push @{ $self->{order} }, $key unless exists $self->{value}{$key};
    $self->{value}{$key} = $value;
}
sub FETCH    { $_[0]->{value}{ $_[1] } }
sub EXISTS   { exists $_[0]->{value}{ $_[1] } }
sub DELETE   {
    my ($self, $key) = @_;
    @{ $self->{order} } = grep { $_ ne $key } @{ $self->{order} };
    delete $self->{value}{$key};
}
sub CLEAR    { $_[0]->{order} = []; $_[0]->{value} = {} }
sub FIRSTKEY { $_[0]->{at} = 0; $_[0]->{order}[0] }
sub NEXTKEY  { $_[0]->{order}[ ++$_[0]->{at} ] }
sub SCALAR   { scalar @{ $_[0]->{order} } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Format::ENV::Ordered - the tied hash that keeps a flat format's parse in document order

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Format::ENV::Ordered;

    my %doc;
    tie %doc, 'File::SOPS::Format::ENV::Ordered';

    $doc{PORT} = undef;
    $doc{HOST} = undef;

    my @keys = keys %doc;   # => ('PORT', 'HOST'), the order they were stored

=head1 DESCRIPTION

A hash whose keys iterate in the order they were first stored, tied rather than
blessed: it is used through C<tie> and never through a constructor.

It exists for one job. MAC verification walks the document in B<document
order>, and a handler supplies that order by returning a tree of the same shape
as its own C<parse> whose mappings iterate the way the file reads
(docs/adr/0036). YAML and JSON get theirs from a second parser; the flat
formats have none to get it from, so their order lives in the hash itself.
Condition 2 of that contract calls this a tied hash B<and nothing else>,
because L<File::SOPS>'s walk reads the order with C<keys> -- a handler that
returns a plain hash hands it Perl's randomised iteration order, and the
document then fails verification with an error that names the MAC and nothing
else.

Both flat handlers tie to it:
L<File::SOPS::Format::ENV/parse_in_document_order> for a dotenv document, and
L<File::SOPS::Format::INI/parse_in_document_order> for an ini one, which ties a
second hash per section.

Two things follow from what the order reader is for, and both make this class
smaller than an ordered hash would otherwise have to be:

=over 4

=item * B<The values are never read>, only the shape, so the handlers store
C<undef> in every slot. Nothing that goes into one of these hashes reaches the
digest as data.

=item * B<It is not a general-purpose ordered hash and is not offered as one.>
L<Tie::IxHash> is not a prerequisite of this distribution and
L<YAML::PP>'s C<YAML::PP::Preserve::Hash> is not separately loadable, which is
why this is here at all rather than a dependency.

=back

=head1 THE TIE INTERFACE

C<STORE> appends a key to the order the first time it is stored and leaves the
order alone when an existing key is overwritten; C<FIRSTKEY> and C<NEXTKEY>
iterate that order; C<FETCH>, C<EXISTS>, C<DELETE>, C<CLEAR> and C<SCALAR> do
what their names say. The handlers exercise only C<STORE>, C<FETCH>, C<EXISTS>
and the iteration pair -- the rest are implemented so that a later caller does
not meet a hash that silently drops half of what a hash does.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS::Format::ENV> - the dotenv handler, the first caller

=item * L<File::SOPS::Format::INI> - the ini handler, the second one

=item * L<File::SOPS> - the MAC walk that reads the order

=item * docs/adr/0036 - the order-preserving reparse, and the contract this
class is condition 2 of

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
