package Dist::Zilla::Plugin::ReversionOnRelease;

use strict;
use 5.008_005;
our $VERSION = '0.06';

use version;
use Version::Next;
use Moose;
with(
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
);

has 'prompt' => (is => 'ro', isa => 'Bool', default => 0);


qr/ ( (?i: Revision: \s+ ) | v | )
    ( \d+ (?: [.] \d+)* )
    ( (?: _ \d+ )? ) /x;
# from perl-reversion
my $VersionRegexp =
  qr{ ^ (
            .*?  [\$\*] (?: \w+ (?: :: | ' ) )* VERSION \s* = \D*?
            |
            \s* package \s+ [\w\:\']+ \s+
        )
            ( (?i: Revision: \s+ ) | v | )
            ( \d+ (?: [.] \d+)* )
            ( (?: _ \d+ )? )
            ( .* ) $ }x;

sub munge_files {
    my $self = shift;

    return unless $ENV{DZIL_RELEASING};

    my $version = $self->reversion;

    if ($self->prompt) {
        my $given_version = $self->zilla->chrome->prompt_str(
            "Next release version? ", {
                default => $version,
                check => sub {
                    eval { version->parse($_[0]); 1 },
                },
            },
        );

        $version = $given_version;
    }

    $self->munge_file($_, $version) for @{ $self->found_files };
    $self->zilla->version($version);

    return;
}

sub reversion {
    my $self = shift;

    my $new_ver = $self->zilla->version;

    if ($ENV{V}) {
        $self->log("Overriding VERSION to $ENV{V}");
        $new_ver = $ENV{V};
    } elsif ($self->is_released($new_ver)) {
        $self->log_debug("$new_ver is released. Bumping it");
        $new_ver = Version::Next::next_version($new_ver);
    } else {
        $self->log_debug("$new_ver is not released yet. No need to bump");
    }

    $new_ver;
}

sub is_released {
    my($self, $new_ver) = @_;

    my $changes_file = 'Changes';

    if (! -e $changes_file) {
        $self->log("No $changes_file found in your directory: Assuming $new_ver is released.");
        return 1;
    }

    my $changelog = Dist::Zilla::File::OnDisk->new({ name => $changes_file });

    grep /^$new_ver(?:-TRIAL)?(?:\s+|$)/,
      split /\n/, $changelog->content;
}

sub filter_pod {
    my($self, $cb) = @_;

    my $in_pod;

    return sub {
        my $line = shift;

        if ($in_pod) {
            /^=cut/ and do { $in_pod = 0; return };
        } else {
            /^=(?!cut)/ and do { $in_pod = 1; return };
            return $cb->($line);
        }
    };
}

sub rewrite_version {
    my($self, $file, $pre, $ver, $post, $new_ver) = @_;

    my $current = $self->zilla->version;

    if (defined $current && $current ne $ver) {
        $self->log([ 'Skipping: "%s" has different $VERSION: %s != %s', $file->name, $ver, $current ]);
        return $pre . $ver . $post;
    }

    $self->log([ 'Bumping $VERSION in %s to %s', $file->name, "$new_ver" ]);

    return $pre . $new_ver . $post;
}

sub munge_file {
    my($self, $file, $new_ver) = @_;

    my $scanner = $self->filter_pod(sub {
        s{$VersionRegexp}{
            $self->rewrite_version($file, $1, $2.$3.$4, $5, $new_ver)
        }e;
    });

    my $munged;

    my @content = split /\n/, $file->content, -1;
    for (@content) {
        $scanner->($_) && $munged++;
    }

    $file->content(join("\n", @content)) if $munged;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::ReversionOnRelease - Bump and reversion $VERSION on release

=head1 SYNOPSIS

  [VersionFromModule]
  [ReversionOnRelease]
  prompt = 1
  [CopyFilesFromRelease]
  match = \.pm$

=head1 DESCRIPTION

This is a Dist::Zilla plugin that bumps version (a la C<perl-reversion
-bump>) in-place with the .pm files inside C<lib>. You should most
likely use this plugin in combination with
L<Dist::Zilla::Plugin::VersionFromModule> so that current VERSION is
taken out of your main module, and then the released file is written
back after the release with L<Dist::Zilla::Plugin::CopyFilesFromRelease>.

Unlike C<perl-reversion>, this module uses L<Version::Next> to get
more naturally incremented version, instead of a little strict 3-digit
rules in L<Perl::Version>.

You B<should not> use this plugin with any code munging or Pod::Weaver
plugins.

By default, this plugin bumps version by the smallest possible
increase - if you have 0.001, the next version is 0.002. You can
override that by either running the plugin with C<prompt> option to
give the desired value from the prompt, or by setting the environment
variable C<V>:

  > V=1.001000 dzil release

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Dist::Milla>

=item * L<Version::Next>

=item * L<Dist::Zilla::Plugin::BumpVersion>

=item * L<Dist::Zilla::Plugin::RewriteVersion> - also takes $VERSION from the main module; ensures all $VERSIONs are consistent 

=item * L<Dist::Zilla::Plugin::BumpVersionAfterRelease> - edits the $VERSION in the repository code to reflect the new version, after release

=item * L<Dist::Zilla::Plugin::RewriteVersion::Transitional> - like L<Dist::Zilla::Plugin::RewriteVersion>, but munges the version in if it was not already present

=item * L<Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional> - like L<Dist::Zilla::Plugin::BumpVersionAfterRelease>, but also adds the $VERSION into the repository code if it was not already present

=back

=cut
