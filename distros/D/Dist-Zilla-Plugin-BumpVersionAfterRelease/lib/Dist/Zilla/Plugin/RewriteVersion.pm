use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::RewriteVersion;
# ABSTRACT: Get and/or rewrite module versions to match distribution version

our $VERSION = '0.015';

use Moose;
use namespace::autoclean;
use version ();

#pod =attr allow_decimal_underscore
#pod
#pod Allows use of decimal versions with underscores.  Default is false.  (Version
#pod tuples with underscores are never allowed!)
#pod
#pod =cut

has allow_decimal_underscore => (
    is  => 'ro',
    isa => 'Bool',
);

#pod =attr global
#pod
#pod If true, all occurrences of the version pattern will be replaced.  Otherwise,
#pod only the first occurrence is replaced.  Defaults to false.
#pod
#pod =cut

has global => (
    is  => 'ro',
    isa => 'Bool',
);

#pod =attr skip_version_provider
#pod
#pod If true, rely on some other mechanism for determining the "current" version
#pod instead of extracting it from the C<main_module>. Defaults to false.
#pod
#pod This enables hard-coding C<version => in C<dist.ini> among other tricks.
#pod
#pod =cut

has skip_version_provider => ( is => ro =>, lazy => 1, default => undef );

#pod =attr add_tarball_name
#pod
#pod If true, when the version is written, it will append a comment with the name of
#pod the tarball it comes from.  This helps users track down the source of a
#pod module if its name doesn't match the tarball name.  If the module is
#pod a TRIAL release, that is also in the comment.  For example:
#pod
#pod     our $VERSION = '0.010'; # from Foo-Bar-0.010.tar.gz
#pod     our $VERSION = '0.011'; # TRIAL from Foo-Bar-0.011-TRIAL.tar.gz
#pod
#pod This option defaults to false.
#pod
#pod =cut

has add_tarball_name => ( is => ro =>, lazy => 1, default => undef );

sub provide_version {
    my ($self) = @_;
    return if $self->skip_version_provider;
    # override (or maybe needed to initialize)
    return $ENV{V} if exists $ENV{V};

    my $file    = $self->zilla->main_module;
    my $content = $file->content;

    my $assign_regex = $self->assign_re();

    my ( $quote, $version ) = $content =~ m{^$assign_regex[^\n]*$}ms;

    $self->log_debug( [ 'extracted version from main module: %s', $version ] )
      if $version;
    return $version;
}

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

    $self->check_valid_version($version);

    if ( $self->rewrite_version( $file, $version ) ) {
        $self->log_debug( [ 'updating $VERSION assignment in %s', $file->name ] );
    }
    else {
        $self->log( [ q[Skipping: no "our $VERSION = '...'" found in "%s"], $file->name ] );
    }
    return;
}

sub rewrite_version {
    my ( $self, $file, $version ) = @_;

    my $content = $file->content;

    my $code = "our \$VERSION = '$version';";
    $code .= " # TRIAL" if $self->zilla->is_trial;

    if ( $self->add_tarball_name ) {
        my $tarball = $self->zilla->archive_filename;
        $code .= ( $self->zilla->is_trial ? "" : " #" ) . " from $tarball";
    }

    $code .= "\n\$VERSION = eval \$VERSION;"
      if $version =~ /_/ and scalar( $version =~ /\./g ) <= 1;

    my $assign_regex = $self->assign_re();

    if (
        $self->global
        ? ( $content =~ s{^$assign_regex[^\n]*$}{$code}msg )
        : ( $content =~ s{^$assign_regex[^\n]*$}{$code}ms )
      )
    {
        $file->content($content);
        return 1;
    }

    return;
}

with(
    'Dist::Zilla::Role::FileMunger' => { -version => 5 },
    'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::FileFinderUser' =>
      { default_finders => [ ':InstallModules', ':ExecFiles' ], },
    'Dist::Zilla::Plugin::BumpVersionAfterRelease::_Util',
);

around dump_config => sub {
    my ( $orig, $self ) = @_;
    my $config = $self->$orig;

    $config->{ +__PACKAGE__ } = {
        finders => [ sort @{ $self->finder } ],
        (
            map { $_ => $self->$_ ? 1 : 0 } qw(global skip_version_provider add_tarball_name)
        ),
    };

    return $config;
};

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RewriteVersion - Get and/or rewrite module versions to match distribution version

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    # in your code, declare $VERSION like this:
    package Foo;
    our $VERSION = '1.23';

    # in your dist.ini
    [RewriteVersion]

=head1 DESCRIPTION

This module is both a C<VersionProvider> and C<FileMunger>.

This module finds a version in a specific format from the main module file and
munges all gathered files to match.  You can override the version found with
the C<V> environment variable, similar to
L<Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion>, in which case all
the gathered files have their C<$VERSION> set to that value.

By default, versions B<must> be "strict" -- decimal or 3+ part tuple with a
leading "v".  The C<allow_decimal_underscore> option, if enabled, will also
allow decimals to contain an underscore.  All other version forms are
not allowed, including: "v1.2", "1.2.3" and "v1.2.3_4".

Only the B<first> occurrence of a C<$VERSION> declaration in each file is
relevant and/or affected (unless the L</global> attribute is set) and it must
exactly match this regular expression:

    qr{^our \s+ \$VERSION \s* = \s* '$version::LAX'}mx

It must be at the start of a line and any trailing comments are deleted.  The
original may have double-quotes, but the re-written line will have single
quotes.

The very restrictive regular expression format is intentional to avoid
the various ways finding a version assignment could go wrong and to avoid
using L<PPI>, which has similar complexity issues.

For most modules, this should work just fine.

See L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease> for
more details and usage examples.

=head1 ATTRIBUTES

=head2 allow_decimal_underscore

Allows use of decimal versions with underscores.  Default is false.  (Version
tuples with underscores are never allowed!)

=head2 global

If true, all occurrences of the version pattern will be replaced.  Otherwise,
only the first occurrence is replaced.  Defaults to false.

=head2 skip_version_provider

If true, rely on some other mechanism for determining the "current" version
instead of extracting it from the C<main_module>. Defaults to false.

This enables hard-coding C<version => in C<dist.ini> among other tricks.

=head2 add_tarball_name

If true, when the version is written, it will append a comment with the name of
the tarball it comes from.  This helps users track down the source of a
module if its name doesn't match the tarball name.  If the module is
a TRIAL release, that is also in the comment.  For example:

    our $VERSION = '0.010'; # from Foo-Bar-0.010.tar.gz
    our $VERSION = '0.011'; # TRIAL from Foo-Bar-0.011-TRIAL.tar.gz

This option defaults to false.

=for Pod::Coverage munge_files munge_file rewrite_version provide_version

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::RewriteVersion::Transitional>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
