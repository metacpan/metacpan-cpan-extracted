package Dist::Zilla::Role::Stash::Login 6.032;
# ABSTRACT: a stash with username/password credentials

use Moose::Role;
with 'Dist::Zilla::Role::Stash';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod A Login stash must provide a C<username> and C<password> method.
#pod
#pod =cut

requires 'username';
requires 'password';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Stash::Login - a stash with username/password credentials

=head1 VERSION

version 6.032

=head1 OVERVIEW

A Login stash must provide a C<username> and C<password> method.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
