use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::WriteVersion;
# ABSTRACT: Write the version to all Perl files and scripts

=head1 NAME

Dist::Zilla::Plugin::WriteVersion

=head1 DESCRIPTION

Overwrites version numbers in .pm-files, based on
  Dist::Zilla::Plugin::RewriteVersion
this is needed for cpan to understand the installed version number after being installed.

Takes a version number from wherever it was generated from and overwrites it
to each perl file and script to

  our $VERSION = '0.004';

The placeholder must be present in the file, otherwise the overwrite will fail.

=cut

our $VERSION = '0.001';

use Moose;
use namespace::autoclean;
use version ();

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ( $self, $file ) = @_;

    return if $file->is_bytes;

    if ( $file->name =~ m/\.pod$/ ) {
        $self->log_debug( [ 'Skipping: "%s" is pod only', $file->name ] );
        return;
    }

    my $version = $self->zilla->version;
    my $assign_regex = qr/^our \$VERSION = .[vV0-9.]+.;[^\n]*$/sm;
    my $code = "our \$VERSION = '$version';";

    if ( $self->rewrite_version( $file, $version, $assign_regex, $code ) ) {
        $self->log_debug( [ 'updating $VERSION assignment in %s', $file->name ] );
    }
    else {
        $self->log( [ q[Skipping: no "our $VERSION = '...'" found in "%s"], $file->name ] );
    }
    return;
}

sub rewrite_version {
    my ( $self, $file, $version, $assign_regex, $code ) = @_;

    my $content = $file->content;

    if ($content =~ s{$assign_regex}{$code}ms ) {
        $file->content($content);
        return 1;
    }

    return undef;
}

with(
    'Dist::Zilla::Role::FileMunger' => { -version => 5 },
    'Dist::Zilla::Role::FileFinderUser' =>
      { default_finders => [ ':InstallModules', ':ExecFiles' ], },
);

__PACKAGE__->meta->make_immutable;

1;
