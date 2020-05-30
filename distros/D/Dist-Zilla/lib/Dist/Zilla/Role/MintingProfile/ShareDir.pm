package Dist::Zilla::Role::MintingProfile::ShareDir 6.015;
# ABSTRACT: something that keeps its minting profile in a sharedir

use Moose::Role;
with 'Dist::Zilla::Role::MintingProfile';

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

version 6.015

=head1 DESCRIPTION

This role includes L<Dist::Zilla::Role::MintingProfile>, providing a
C<profile_dir> method that looks in the I<module>'s L<ShareDir|File::ShareDir>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
