package Dist::Zilla::Plugin::ReadmeAddDevInfo;

# ABSTRACT: Dist::Zilla::Plugin::ReadmeAddDevInfo - add info how to contribute to the project

use v5.10;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints qw(enum);
use namespace::autoclean;
use Dist::Zilla::File::OnDisk;
use Path::Tiny;

our $VERSION = 0.01;

# same as Dist::Zilla::Plugin::ReadmeAnyFromPod
with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
  Dist::Zilla::Role::FileMunger
);

sub mvp_multivalue_args { ('badges') }

has phase => (
    is      => 'ro',
    isa     => enum([qw(build release filemunge)]),
    default => 'build',
);

has before => (
    is  => 'ro',
    isa => 'Str',
);

has readme_file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @candidates = qw/ README.md README.mkdn README.markdown /;


        # only for the filemunge phase do we look
        # in the slurped files
        if( $self->phase eq 'filemunge' ) {
            for my $file ( @{ $self->zilla->files } ) {
                return $file if grep { $file->name eq $_ } @candidates;
            }
        }
        else {
            # for the other phases we look on disk
            my $root = path($self->zilla->root);

            return Dist::Zilla::File::OnDisk->new( 
                name    => "$_",
                content => $_->slurp_raw,
                encoding => 'bytes',
            ) for grep { -f $_ } map { $root->child($_) } @candidates 
        }

        $self->log_fatal('README file not found');
    },
);

sub after_build {
    my ($self) = @_;
    $self->add_info if $self->phase eq 'build';
}

sub after_release {
    my ($self) = @_;
    $self->add_info if $self->phase eq 'release';
}

sub munge_files {
    my $self = shift;

    $self->add_info if $self->phase eq 'filemunge';
}

sub add_info {
    my $self = shift;

    my $distname = $self->zilla->name;
    my $distmeta = $self->zilla->distmeta;
    my $repository = $distmeta->{resources}->{repository}->{url};
    return unless $repository;
    my ($base_url, $user_name, $repository_name) = ($repository =~ m{^\w+://(.*)/([^\/]+)/(.*?)(\.git|\/|$)});
    return unless $repository_name;

    if ( '.git' ne substr $repository, -4 ) {
        $repository .= '.git';
    }

    my $info = qq~
## Development

The distribution is contained in a Git repository, so simply clone the
repository

```
\$ git clone $repository
```

and change into the newly-created directory.

```
\$ cd $distname
```

The project uses [`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) to
build the distribution, hence this will need to be installed before
continuing:

```
\$ cpanm Dist::Zilla
```

To install the required prequisite packages, run the following set of
commands:

```
\$ dzil authordeps --missing | cpanm
\$ dzil listdeps --author --missing | cpanm
```

The distribution can be tested like so:

```
\$ dzil test
```

To run the full set of tests (including author and release-process tests),
add the `--author` and `--release` options:

```
\$ dzil test --author --release
```
~;

    my $readme  = $self->readme_file;
    my $content = $readme->encoded_content;

    if ( !$self->before ) {
        $content .= "\n\n$info";
    }
    else {
        my $before = $self->before;
        $content =~ s{^(\Q$before\E)}{\n$info\n$before}m;
    }

    $readme->content($content);

    # need to write it to disk if we're in a
    # phase that is not filemunge
    path( $readme->name )->spew_raw( $readme->encoded_content )
        if $self->phase ne 'filemunge';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::ReadmeAddDevInfo - Dist::Zilla::Plugin::ReadmeAddDevInfo - add info how to contribute to the project

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # in dist.ini
    [ReadmeAddDevInfo]
    phase = release

=head1 CONFIG

=head2 phase

    [ReadmeAddDevInfo]
    phase = release

Which Dist::Zilla phase to add the info: C<build>, C<release> or C<filemunge>.
For the C<build> and C<release> phases, the README that is on disk will
be modified, whereas for the C<filemunge> it's the internal zilla version of
the README that will be modified.

The default is C<build>.

=head1 SEE ALSO

L<Minilla>, L<Dist::Zilla::Plugin::TravisCI::StatusBadge>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
