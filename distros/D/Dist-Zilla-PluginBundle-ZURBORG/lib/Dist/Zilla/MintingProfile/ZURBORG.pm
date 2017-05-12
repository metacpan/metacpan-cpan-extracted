use strictures 2;

package Dist::Zilla::MintingProfile::ZURBORG;

our $VERSION = '0.007'; # VERSION

use Moose;

with 'Dist::Zilla::Role::MintingProfile' => { -version => '5.047' };

use File::ShareDir;
use Path::Tiny;
use Carp;
use namespace::autoclean;

sub profile_dir
{
    my ($self, $profile_name) = @_;

    my $dist_name = 'Dist-Zilla-PluginBundle-ZURBORG'; # '{{ $dist->name }}';

    my $profile_dir = path(File::ShareDir::dist_dir($dist_name))->child('profiles', $profile_name);

    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name via $self: it should be in $profile_dir";
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Dist::Zilla::MintingProfile::ZURBORG

=head1 VERSION

version 0.007

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/zurborg/libdist-zilla-pluginbundle-zurborg-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg <zurborg@cpan.org>.

This is free software, licensed under:

  The ISC License

=cut
