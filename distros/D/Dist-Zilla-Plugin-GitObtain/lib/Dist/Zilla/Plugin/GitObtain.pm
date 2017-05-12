package Dist::Zilla::Plugin::GitObtain;
{
  $Dist::Zilla::Plugin::GitObtain::VERSION = '0.06';
}

# ABSTRACT: obtain files from a git repository before building a distribution

use Git::Wrapper;
use File::Spec::Functions;
use File::Path qw/ make_path remove_tree /;
use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::BeforeBuild';

has 'git_dir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '.',
);

has _repos => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

sub BUILDARGS {
    my $class = shift;
    my %repos = ref($_[0]) ? %{$_[0]} : @_;

    my $zilla = delete $repos{zilla};
    my $plugin_name = delete $repos{plugin_name};

    my %args;
    for my $project (keys %repos) {
        if ($project =~ /^--/) {
            (my $arg = $project) =~ s/^--//;
            $args{$arg} = delete $repos{$project};
            next;
        }
        my ($url,$tag) = split ' ', $repos{$project};
        $tag ||= 'master';
        $repos{$project} = { url => $url, tag => $tag };
    }

    return {
        zilla => $zilla,
        plugin_name => $plugin_name,
        _repos => \%repos,
        git_dir => $args{git_dir} || '.',
        %args,
    };
}

sub before_build {
    my $self = shift;

    if (-d $self->git_dir) {
        $self->log("using existing dir " . $self->git_dir);
    } else {
        $self->log("creating dir " . $self->git_dir);
        make_path($self->git_dir) or die "Can't create dir " . $self->git_dir . " -- $!";
    }
    for my $project (keys %{$self->_repos}) {
        my ($url,$tag) = map { $self->_repos->{$project}{$_} } qw/url tag/;
        my $dir = catfile($self->git_dir, $project);
        if (-d $dir) {
            if (-e catfile($dir, ".git")) {
                my $git = Git::Wrapper->new($dir);
                my ($wc_url) = $git->config("remote.origin.url");
                if ($wc_url eq $url) {
                    my $branch;
                    for ($git->config({ list => 1 })) {
                        next unless /^branch\.(\w+)\.remote=origin$/;
                        $branch = $1;
                        last;
                    }
                    $self->log("$project: checkout $branch");
                    $git->checkout($branch);
                    $self->log("$project: pull latest changes");
                    $git->pull;
                    $self->log("$project: checkout $tag");
                    $git->checkout($tag);
                } else {
                    die "$project directory is not a GIT repository for $url ($wc_url)\n";
                }
            } else {
                die "$project directory exists but is not a GIT repository\n";
            }
        } else {
            $self->log("cloning $project ($url)");
            my $git = Git::Wrapper->new($self->git_dir);
            $git->clone($url,$project) or die "Can't clone repository $url -- $!";
            next unless $tag;
            $self->log("$project: checkout $tag");
            my $git_tag = Git::Wrapper->new($dir);
            $git_tag->checkout($tag);
        }
    }
}


__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::GitObtain - obtain files from a git repository before building a distribution

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your F<dist.ini>:

  [GitObtain]
    ;project    = url                                           tag
    rakudo      = git://github.com/rakudo/rakudo.git            2010.06
    http-daemon = git://gitorious.org/http-daemon/mainline.git

=head1 DESCRIPTION

This module uses L<Git::Wrapper> to obtain files from git repositories
before building a distribution.

Projects downloaded via git would be placed into the current directory
by default. To specify an alternate location, use the C<--git_dir>
option. This directory and any intermediate directories in the path will
be created if they do not already exist.

Following the C<[GitObtain]> section header is the list of git
repositories to download and include in the distribution. Each
repository is specified by the name of the directory in which the
repository will be checked out, an equals sign (C<=>), the URL to the
git repository, and an optional "tag" to checkout. Anything that may be
passed to C<git checkout> may be used for the "tag"; the default is
C<master>. The repository directory will be created beneath the path
specified in the section heading. So,

  [GitObtain]
    --git_dir       = foo
    my_project      = git://github.com/example/my_project.git
    another_project = git://github.com/example/another_project.git

will create a F<foo> directory beneath the current directory and
F<my_project> and F<another_project> directories inside of the F<foo>
directory. Each of the F<my_project> and F<another_project> directories
will be git repositories.

To specify multiple target directories in which to obtain git repositories,
use alternate section names in the section header:

  [GitObtain / alpha ]
    --git_dir       = foo
    my_project      = git://github.com/example/my_project.git

  [GitObtain / beta ]
    --git_dir       = bar
    another_project = git://github.com/example/another_project.git

The above example config contains 2 GitObtain sections called C<alpha>
and C<beta>. The C<alpha> section creates repositories in the F<foo>
directory and the C<beta> section creates repositories in the F<bar>
directory.

=head1 AUTHOR

Jonathan Scott Duff <duff@pobox.com>

=head1 COPYRIGHT

This software is copyright (c) 2010 by Jonathan Scott Duff

This is free sofware; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language itself.

=cut
