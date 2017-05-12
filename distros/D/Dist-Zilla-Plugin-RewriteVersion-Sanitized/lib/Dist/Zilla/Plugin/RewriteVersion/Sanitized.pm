use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::RewriteVersion::Sanitized;

our $VERSION = '0.001006';

# ABSTRACT: RewriteVersion but force normalizing ENV{V} and other sources.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( extends with );

extends 'Dist::Zilla::Plugin::RewriteVersion';
with 'Dist::Zilla::Role::Version::Sanitize';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RewriteVersion::Sanitized - RewriteVersion but force normalizing ENV{V} and other sources.

=head1 VERSION

version 0.001006

=head1 DESCRIPTION

This is a subclass of L<< C<[RewriteVersion]>|Dist::Zilla::Plugin::RewriteVersion >> that applies version
sanitization from all the various possible input sources
( Similar to L<< C<[Git::NextVersion::Sanitized]>|Dist::Zilla::Plugin::Git::NextVersion::Sanitized >> )
by applying L<< C<Dist::Zilla::Role::Version::Sanitize>|Dist::Zilla::Role::Version::Sanitize >> to it.

Using this module instead of C<[RewriteVersion]> allows you to do

  V=2.6.0 dzil release

And V will be interpreted as if you'd written C<V=2.006000>

For details on the parameters this C<plugin> takes,
see L<< the documentation for Dist::Zilla::Role::Version::Sanitize|Dist::Zilla::Role::Version::Sanitize >>.

=head1 SEE ALSO

=over 4

=item * L<< C<[RewriteVersion]>|Dist::Zilla::Plugin::RewriteVersion >>

=item * L<< C<[RewriteVersion::Transitional]>|Dist::Zilla::Plugin::RewriteVersion::Transitional >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
