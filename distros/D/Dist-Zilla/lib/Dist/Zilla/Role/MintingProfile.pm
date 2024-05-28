package Dist::Zilla::Role::MintingProfile 6.032;
# ABSTRACT: something that can find a minting profile dir

use Moose::Role;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Dist::Zilla::Path;
use File::ShareDir;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing this role should provide C<profile_dir> method, which,
#pod given a minting profile name, returns its directory.
#pod
#pod The minting profile is a directory, containing arbitrary files used during
#pod creation of new distribution. Among other things notably, it should contain the
#pod 'profile.ini' file, listing the plugins used for minter initialization.
#pod
#pod The default implementation C<profile_dir> looks in the module's
#pod L<ShareDir|File::ShareDir>.
#pod
#pod After installing your profile, users will be able to start a new distribution,
#pod based on your profile with the:
#pod
#pod   $ dzil new -P Provider -p profile_name Distribution::Name
#pod
#pod =cut

requires 'profile_dir';

around profile_dir => sub {
  my ($orig, $self, @args) = @_;
  path($self->$orig(@args));
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::MintingProfile - something that can find a minting profile dir

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Plugins implementing this role should provide C<profile_dir> method, which,
given a minting profile name, returns its directory.

The minting profile is a directory, containing arbitrary files used during
creation of new distribution. Among other things notably, it should contain the
'profile.ini' file, listing the plugins used for minter initialization.

The default implementation C<profile_dir> looks in the module's
L<ShareDir|File::ShareDir>.

After installing your profile, users will be able to start a new distribution,
based on your profile with the:

  $ dzil new -P Provider -p profile_name Distribution::Name

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
