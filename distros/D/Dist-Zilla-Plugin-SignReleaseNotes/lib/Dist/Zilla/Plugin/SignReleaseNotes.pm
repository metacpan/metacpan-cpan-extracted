use strict;
use warnings;

package Dist::Zilla::Plugin::SignReleaseNotes;

our $VERSION = '0.0006';

# ABSTRACT: Create and signs a 'Release' notes file
use Moose;
use Exporter qw(import);
with 'Dist::Zilla::Role::AfterRelease';

has sign => (is => 'ro', default => 'always');

sub do_sign {
  my $self      = shift;
  my $dir       = shift;
  my $plaintext = shift;

  use Module::Signature qw/ $SIGNATURE $Preamble /;

  $SIGNATURE = 'Release' . "-" . $self->get_version();
  $Preamble = '';
  require File::chdir;

  local $File::chdir::CWD = $dir;

  my $signed;
  if (my $version = Module::Signature::_has_gpg()) {
    $signed = Module::Signature::_sign_gpg($SIGNATURE, $plaintext, $version);
  }
  elsif (eval {require Crypt::OpenPGP; 1}) {
    $signed = Module::Signature::_sign_crypt_openpgp($SIGNATURE, $plaintext);
  }
}

sub after_release {
  my $self     = shift;
  my $filename = shift;

  my $digest = $self->get_checksum($filename);

  my @sha1s_and_titles = get_git_checksums_and_titles();

  my $file = $self->create_release_file (
    $digest,
    $filename,
    @sha1s_and_titles
  );

  $self->do_sign('./', $file)
    if $self->sign =~ /always/i;
}

sub get_git_checksums_and_titles {
  my $self     = shift;

  use Git::Wrapper;
  my $git = Git::Wrapper->new('./');

  my @tags = $git->RUN('for-each-ref', 'refs/tags/*', '--sort=-taggerdate', '--count=2', '--format=%(refname:short)');

  if (($@ =~ /fatal: No names found, cannot describe anything/) || (@tags eq 0)){
    warn "[SignReleaseNotes]: No existing tag - tag must already exist!";
    return;
  }

  my $range = "$tags[1]...$tags[0]";
  my @sha1s_and_titles = $git->RUN('log', {pretty=>'%h %s' }, $range);

  return @sha1s_and_titles;

}

sub get_checksum {
  my $self     = shift;
  my $filename = shift;

  use Digest::SHA;
  my $sha = Digest::SHA->new('sha256');
  my $digest;
  if ( -e $filename ) {
      open my $fh, '<:raw', $filename  or die "$filename: $!";
      $sha->addfile($fh);
      $digest = $sha->hexdigest;
  }
  return $digest;
}

sub get_version {
  my ($self) = @_;

  return $self->{zilla}->version;
}

sub get_name {
  my ($self, $filename) = @_;

  $filename =~ s/-+\d+.*$//g;
  $filename =~ s/-/::/g;
  return $filename;
}

sub create_release_file {
  my ($self, $digest, $filename, @sha1s_and_titles) = @_;

  my $version = $self->get_version();
  my $name = $self->get_name($filename);

  my $file = "$name\n";
  $file .= "\n";
  $file .= "Release $version\n";
  $file .= "\n";
  $file .= "Change Log\n";

  foreach (@sha1s_and_titles) {
    $file .= "  - $_\n";
  }

  $file .= "\n";
  $file .= "SHA256 hash of CPAN release\n";
  $file .= "\n";
  $file .= "$digest *$filename\n";
  $file .= "\n";

  return $file;
}

sub BUILDARGS {
  my $self = shift;
  my $args = @_ == 1 ? shift : {@_};
  $args->{sign} = $ENV{DZSIGN} if exists $ENV{DZSIGN};
  $args;
}

no Moose;

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SignReleaseNotes - Create and signs a 'Release' notes file

=head1 VERSION

version 0.0006

=head1 DESCRIPTION

This plugin will sign a 'Release' file that includes:

  1. Git commits since the last tag
  2. the sha256 checksum of the file that is being distributed to CPAN

the file is then signed using Module::Signature.

The resulting file can be used as the Release information for GitHub or similar.

This plugin should appear after any other AfterBuild plugin in your C<dist.ini> file

=head1 SAMPLE OUTPUT

=over

    -----BEGIN PGP SIGNED MESSAGE-----
    Hash: RIPEMD160

    Dist::Zilla::Plugin::SignReleaseNotes

    Release 0.0004

    Change Log
      - 5c4df12 v0.0004
      - 9000d39 Increment version number
      - 1835a25 rev-list --tags matching commits that it should not

    SHA256 hash of CPAN release

    0b05776713165ad90d1385669e56dcd9f0abed8701f4e4652f5aa270687a3435 *Dist-Zilla-Plugin-SignReleaseNotes-0.0004.tar.gz

    -----BEGIN PGP SIGNATURE-----

    iQIzBAEBAwAdFiEEMguXHBCUSzAt6mNu1fh7LgYGpfkFAmH91iYACgkQ1fh7LgYG
    pfmwrg//TXpyu8UeAaotLR0RFuLdmt9IrFmpflJ0SqwyY8MPBJOdb5BiwzSLDthi
    1BNUtj4P+UsVlWrmXVufUYMEsGPyim6fD656NrUNds+PQQok3bTfR9qf341CY9Cq
    MoR0an/u5APRaB4SurHs/lA3Nf/TRfAjkwBX4hzaRG1Iw9IcSHi5/gRBMA1E/+zT
    /1GxkICjo0CrSe7REUiGmVf96TYGi/3D18pP/09Gnc6f1DMuKihiLy8BY57j9MCW
    g6BWL8aXDpNvJFwwZv2h6OPLKF04xfjnVYzaAloCOaf2vHxb2ocv2KbOas8oWglf
    BmameSAIHpxRTdV01M40V8eA6IHEDT4pUXGydggb9LQ/2s3X2n0AJN4HDwxtclvI
    cF85Kfp2e5lqYJwHKN+tmQm3NUEJkvj+yM5tKeSoJWmba87fe7DKfhKHUSL7rqT5
    PI2aKbs0auR2b5cXegUnNqKAjnF+I4pY/yWkmhUNPqQ+ctE/dy85opI6sQ1nIQ4v
    Q3oIFhs4y+XkQorsorJJn3MtdrxTow/CoOjQ/Mydd11xpQSlXkTAO3TqxEiXIz0l
    i4RybXbqlFB9MAbs9dbC96Lq5hxroxeIVxo99r9Q327it1gQWPMCnfUV9LKmzusZ
    2j18EynyALPs/onwA4VOIi1kC3As8d+1cBfhaFaZf9vgryXQx84=
    =kzjP
    -----END PGP SIGNATURE-----

=back

=head1 ATTRIBUTES

=over

=item sign

A string value. If C<always> then a signature will be created after an archive is created.
If C<always> then the 'Release' file will be signed after the release. Default is C<always>

This attribute can be overridden by an environment variable C<DZSIGN>

=back

=head1 METHODS

=over

=item after_release

The main processing function includes getting the git information.  Should likely
be split up.

=item create_release_file

Create's the plaintext Release file contents.

=item do_sign

Signs the 'Release' file to Module::Signature.  Unfortunately we cannot use
the Module::Signature::sign function as it gets its plaintext from the list
of files that are normally used.

=item sub get_git_checksums_and_titles

Gets the short version of the checksums and the titles of each git commit since the
most recent tag that was found in the repo.

=item get_checksum

Get's the checksum of the file being released.  Expects the filename and returns
the checksum (currently sha256 only).

=item get_name

Get's the name of the Distribution being released.  This takes it from
the filename.  There is likely a better way to obtain it.

=item get_version

Get's the version of the Distribution being released.  This takes it from
the $self->{zilla}->version.  There is likely a better way to obtain it.

=back

=head1 AUTHOR

  Timothy Legge <timlegge@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Timothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Timothy Legge

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Timothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
