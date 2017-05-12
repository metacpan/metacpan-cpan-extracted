use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::Git::NextVersion::Sanitized;

our $VERSION = '0.002003';

# ABSTRACT: Sanitize versions handed to you by Git::NextVersion

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( extends with );
extends 'Dist::Zilla::Plugin::Git::NextVersion';
with 'Dist::Zilla::Role::Version::Sanitize';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::NextVersion::Sanitized - Sanitize versions handed to you by Git::NextVersion

=head1 VERSION

version 0.002003

=head1 SYNOPSIS

This exist, mostly because I accidentally keep doing

    V=2.6.0 dzil release # shit, I mean 2.006000

Or

    V=2.00001 dzil release # Crap, I can't count, how many 0's is that?

So this wraps L<< C<::Role::Version::Sanitize>|Dist::Zilla::Role::Version::Sanitize >> around
L<< C<[Git::NextVersion]>|Dist::Zilla::Plugin::Git::NextVersion >>

=head1 AUTHOR

Kent Fredric <kentnl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
