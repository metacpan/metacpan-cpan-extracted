package Dist::Zilla::PluginBundle::OYOULE;

use v5.26;
use strictures 2;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle::Easy';

# ABSTRACT: Dist::Zilla plugin configuration for Author/OYOULE


has dist => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_payload('dist');
    },
);


has use_darkpan => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_payload(use_darkpan => 0);
    },
);


has use_github => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_payload(use_github => 1);
    },
);


has regenerate_license => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->_payload('regenerate_license' => 1);
    },
);


sub configure {
    my $self = shift;

    foreach my $entry (@{ $self->_bundles }) {
        $self->add_bundle(
            $entry->{bundle},
            $entry->{config},
        );
    }

    $self->add_plugins(@{ $self->_plugins });
}

sub _bundles {
    my $self = shift;

    return [
        {
            bundle => 'Starter',
            config => $self->_starter_config,
        },
    ];
}

sub _plugins {
    my $self = shift;

    my @plugins = (
        [
            MetaResources => MetaResources => {
                'bugtracker.web'  => $self->_tracker_url,
                'repository.url'  => $self->_repo_url,
                'repository.type' => 'git',
            },
        ],
        'PodWeaver',
        'Prereqs::FromCPANfile',
        [
            ReadmeAnyFromPod => 'ReadmeAnyFromPod/Markdown' => {
                type     => 'markdown',
                location => 'root',
                filename => 'README.md',
            },
        ],
    );

    if ($self->use_darkpan) {
        push @plugins, 'UploadToDarkPAN';
    }

    return \@plugins;
}

sub _starter_config {
    my $self = shift;

    my %config = (
        revision   => 5,
    );

    if ($self->use_darkpan) {
        $config{'-remove'} = ['UploadToCPAN'];
    }

    if ($self->regenerate_license) {
        push @{ $config{regenerate} }, 'LICENSE';
    }

    return \%config;
}

sub _payload {
    my ($self, $key, $default) = @_;

    return $self->payload->{$key} if defined $self->payload->{$key};

    die "Missing config option '$key' for \@OYOULE bundle" unless defined $default;

    return $default;
}

sub _repo_host {
    my $self = shift;

    return $self->use_github
        ? 'github.com'
        : 'git.oliver.youle.dev';
}

sub _repo_base {
    my $self = shift;

    return join('',
        'https://',
        $self->_repo_host,
        '/Olyol95/perl-',
        $self->dist,
    );
}

sub _tracker_url {
    my $self = shift;

    return $self->_repo_base . '/issues';
}

sub _repo_url {
    my $self = shift;

    return $self->_repo_base . '.git';
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::OYOULE - Dist::Zilla plugin configuration for Author/OYOULE

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

In your dist.ini

  [@OYOULE]
  dist        = Example-Distribution
  use_github  = 0
  use_darkpan = 1

=head1 DESCRIPTION

A personal plugin bundle for L<Dist::Zilla>.

=head1 OPTIONS

=over

=item C<dist>

The name of the distribution.

Required.

=item C<use_darkpan>

Boolean indicating whether or not to release the distribution
to a private CPAN mirror.

Defaults to 0.

When true, L<Dist::Zilla::Plugin::UploadToDarkPAN> is enabled.
When false, L<Dist::Zilla::Plugin::UploadToCPAN> is enabled.

=item C<use_github>

Boolean indicating whether or not the distribution lives
on GitHub.

Defaults to 1.

When false, the repo metadata will instead point to my
private git instance.

=item C<regenerate_license>

Boolean indicating whether or not to copy the generated
license back into the distribution root.

Defaults to 1.

=back

=head1 SEE ALSO

=over

=item L<Dist::Zilla>

=item L<Dist::Zilla::Plugin::UploadToCPAN>

=item L<Dist::Zilla::Plugin::UploadToDarkPAN>

=back

=head1 AUTHOR

Oliver Youle <oliver@youle.io>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Oliver Youle.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
