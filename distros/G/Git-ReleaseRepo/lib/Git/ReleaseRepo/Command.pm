package Git::ReleaseRepo::Command;
{
  $Git::ReleaseRepo::Command::VERSION = '0.006';
}

use strict;
use warnings;
use Moose;
use App::Cmd::Setup -command;
use Cwd qw( getcwd );
use YAML qw( LoadFile DumpFile );
use List::Util qw( first );
use File::HomeDir;
use File::Spec::Functions qw( catfile catdir );
use Git::Repository qw( +Git::ReleaseRepo::Repository );

has config_file => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        catfile( $_[0]->repo_dir, '.git', 'release' );
    },
);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        if ( -f $self->config_file ) {
            return LoadFile( $self->config_file ) || {};
        }
        else {
            return {};
        }
    },
);

sub write_config {
    my ( $self ) = @_;
    return DumpFile( $self->config_file, $self->config );
}

has repo_dir => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { getcwd },
);

has git => (
    is      => 'ro',
    isa     => 'Git::Repository',
    lazy    => 1,
    default => sub {
        my $repo_dir = $_[0]->repo_dir;
        my $git = Git::Repository->new(
            work_tree => $_[0]->repo_dir,
            git_dir => catdir( $_[0]->repo_dir, '.git' ),
        );
        return $git;
    },
);

has release_prefix => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return $_[0]->config->{version_prefix};
    },
);

sub repo_name_from_url {
    my ( $self, $repo_url ) = @_;
    my ( $repo_name ) = $repo_url =~ m{/([^/]+)$};
    $repo_name =~ s/[.]git$//;
    return $repo_name;
}

sub opt_spec {
    return ();
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    inner();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
