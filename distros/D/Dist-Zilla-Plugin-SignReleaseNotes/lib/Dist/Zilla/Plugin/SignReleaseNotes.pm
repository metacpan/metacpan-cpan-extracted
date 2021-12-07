use strict;
use warnings;

package Dist::Zilla::Plugin::SignReleaseNotes;

our $VERSION = '0.0001';

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
  my @tag;
  eval {
    @tag = $git->describe( qw/ --tags --abbrev=0 / );
  };

  if (($@ =~ /fatal: No names found, cannot describe anything/) || (@tag eq 0)){
    warn "[SignReleaseNotes]: No existing tag - tag must already exist!";
    return;
  }

  my $range = "$tag[0]..HEAD";
  my @sha1s_and_titles = $git->RUN('rev-list', $range , '--abbrev-commit' , {pretty=>'oneline' });

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

version 0.0001

=head1 DESCRIPTION

This plugin will sign a 'Release' file that includes:

  1. Git commits since the last tag
  2. the sha256 checksum of the file that is being distributed to CPAN

the file is then signed using Module::Signature.

The resulting file can be used as the Release information for GitHub or similar.

This plugin should appear after any other AfterBuild plugin in your C<dist.ini> file

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

This software is copyright (c) 2021 by Timothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
