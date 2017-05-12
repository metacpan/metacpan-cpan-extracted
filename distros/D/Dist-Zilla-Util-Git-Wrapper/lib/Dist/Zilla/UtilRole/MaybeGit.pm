use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::UtilRole::MaybeGit;

our $VERSION = '0.004002';

# ABSTRACT: A role to make adding a ->git method easy, and low-complexity

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( with has );
with 'Dist::Zilla::UtilRole::MaybeZilla';

has 'git' => ( is => ro =>, isa => Object =>, lazy_build => 1 );

sub _build_git {
  my ($self) = @_;
  require Dist::Zilla::Util::Git::Wrapper;
  return Dist::Zilla::Util::Git::Wrapper->new( zilla => $self->zilla );
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::UtilRole::MaybeGit - A role to make adding a ->git method easy, and low-complexity

=head1 VERSION

version 0.004002

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
