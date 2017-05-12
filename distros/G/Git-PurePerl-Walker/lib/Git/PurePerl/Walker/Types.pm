use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker::Types;

our $VERSION = '0.004001';

# ABSTRACT: Misc utility types for Git::PurePerl::Walker

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use MooseX::Types -declare => [
  qw(
    GPPW_Repository
    GPPW_Methodish
    GPPW_Method
    GPPW_OnCommitish
    GPPW_OnCommit
    ),
];

use MooseX::Types::Moose qw( Str CodeRef );

## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
class_type GPPW_Repository, { 'class' => 'Git::PurePerl' };
role_type GPPW_Method,      { role    => 'Git::PurePerl::Walker::Role::Method' };
role_type GPPW_OnCommit,    { role    => 'Git::PurePerl::Walker::Role::OnCommit' };
union GPPW_Methodish, [ Str, GPPW_Method ];
union GPPW_OnCommitish, [ Str, CodeRef, GPPW_OnCommit ];
## use critic

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::Types - Misc utility types for Git::PurePerl::Walker

=head1 VERSION

version 0.004001

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
