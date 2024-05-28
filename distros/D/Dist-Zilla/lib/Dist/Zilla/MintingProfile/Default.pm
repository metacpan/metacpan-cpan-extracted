package Dist::Zilla::MintingProfile::Default 6.032;
# ABSTRACT: Default minting profile provider

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Dist::Zilla::Util;

#pod =head1 DESCRIPTION
#pod
#pod Default minting profile provider.
#pod
#pod This provider looks first in the F<~/.dzil/profiles/$profile_name> directory,
#pod if not found it looks among the default profiles shipped with Dist::Zilla.
#pod
#pod =cut

around profile_dir => sub {
  my ($orig, $self, $profile_name) = @_;

  $profile_name ||= 'default';

  # shouldn't look in user's config when testing
  if (!$ENV{DZIL_TESTING}) {
    my $profile_dir = Dist::Zilla::Util->_global_config_root
                    ->child('profiles', $profile_name);

    return $profile_dir if -d $profile_dir;
  }

  return $self->$orig($profile_name);
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Default - Default minting profile provider

=head1 VERSION

version 6.032

=head1 DESCRIPTION

Default minting profile provider.

This provider looks first in the F<~/.dzil/profiles/$profile_name> directory,
if not found it looks among the default profiles shipped with Dist::Zilla.

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
