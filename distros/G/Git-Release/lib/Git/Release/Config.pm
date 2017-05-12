package Git::Release::Config;
use warnings;
use strict;
use Mo;
use File::Spec;

has repo => ();

sub ready_prefix {
    my $self = shift;
    return $self->repo->config('release.ready-prefix') || 'ready';
}

sub released_prefix {
    my $self = shift;
    return $self->repo->config('release.released-prefix') || 'released';
}

sub site_prefix {
    my $self = shift;
    return $self->repo->config('release.site-prefix') || 'site';
}

sub release_prefix {
    my $self = shift;
    return $self->repo->config('release.release-prefix') || 'release'; 
}

sub hotfix_prefix {
    my $self = shift;
    return $self->repo->config('release.hotfix-prefix') || 'hotfix';
}

sub feature_prefix {
    my $self = shift;
    return $self->repo->config('release.release-prefix') || 'feature'; 
}

sub develop_branch {
    my $self = shift;
    return $self->repo->config('release.develop-branch') || 'develop';
}

sub rc_branch {
    my $self = shift;
    return $self->repo->config('release.rc-branch') || 'rc';
}

sub branch_doc_ext {
    my $self = shift;
    return $self->repo->config('release.branch-doc-ext') || 'mkd';
}

sub branch_doc_path {
    my $self = shift;
    return $self->repo->config('release.branch-doc-dir') || File::Spec->join('doc','branches');
}

1;
