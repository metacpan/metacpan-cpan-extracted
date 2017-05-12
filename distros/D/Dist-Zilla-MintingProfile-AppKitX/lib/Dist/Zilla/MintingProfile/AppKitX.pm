package Dist::Zilla::MintingProfile::AppKitX;

# ABSTRACT: Mints a new AppKitX component

our $VERSION = '0.04';
use Moose;
with 'Dist::Zilla::Role::MintingProfile';
use File::ShareDir;
use Path::Class;        # sadly, we still need to use Path::Class :(
use Carp;
use namespace::autoclean;

sub profile_dir
{
    my ($self, $profile_name) = @_;

    die 'minting requires perl 5.014' unless $] >= 5.013002;

    my $dist_name = 'Dist-Zilla-MintingProfile-AppKitX';
    my $profile_dir = dir( File::ShareDir::dist_dir($dist_name) )
                      ->subdir( 'profiles', $profile_name );

    return $profile_dir if -d $profile_dir;

    confess "Can't find profile $profile_name via $self: it should be in $profile_dir";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::AppKitX - Mints a new AppKitX component

=head1 VERSION

version 0.04

=head1 AUTHOR

Alastair McGowan-Douglas <altreus@altre.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alastair McGowan-Douglas.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
