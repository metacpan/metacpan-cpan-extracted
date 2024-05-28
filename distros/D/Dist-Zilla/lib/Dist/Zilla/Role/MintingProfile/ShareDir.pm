package Dist::Zilla::Role::MintingProfile::ShareDir 6.032;
# ABSTRACT: something that keeps its minting profile in a sharedir

use Moose::Role;
with 'Dist::Zilla::Role::MintingProfile';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use File::ShareDir;
use Dist::Zilla::Path;

#pod =head1 DESCRIPTION
#pod
#pod This role includes L<Dist::Zilla::Role::MintingProfile>, providing a
#pod C<profile_dir> method that looks in the I<module>'s L<ShareDir|File::ShareDir>.
#pod
#pod =cut

sub profile_dir {
  my ($self, $profile_name) = @_;

  my $profile_dir = path( File::ShareDir::module_dir($self->meta->name) )
                  ->child( $profile_name );

  return $profile_dir if -d $profile_dir;

  confess "Can't find profile $profile_name via $self";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::MintingProfile::ShareDir - something that keeps its minting profile in a sharedir

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This role includes L<Dist::Zilla::Role::MintingProfile>, providing a
C<profile_dir> method that looks in the I<module>'s L<ShareDir|File::ShareDir>.

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
