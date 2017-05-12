package Dist::Zilla::Plugin::Repository;
{
    $Dist::Zilla::Plugin::Repository::VERSION = '0.20';
}

# ABSTRACT: Automatically sets repository URL from svn/svk/Git checkout for Dist::Zilla

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

has git_remote => (
    is      => 'ro',
    isa     => 'Str',
    default => 'origin',
);

has github_http => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has _found_repo => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build__found_repo {
    my $self = shift;
    my @info = $self->_find_repo( \&_execute );

    unshift @info, 'url' if @info == 1;

    my %repo = @info;

    $repo{$_} ||= '' for qw(type url web);

    return \%repo;
}

has 'repository' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_repository {
    shift->_found_repo->{url};
}

has type => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->_found_repo->{type} },
);

has web => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->_found_repo->{web} },
);

sub metadata {
    my ( $self, $arg ) = @_;

    my %repo;
    $repo{url}  = $self->repository if $self->repository;
    $repo{type} = $self->type       if $self->type;
    $repo{web}  = $self->web        if $self->web;

    return unless $repo{url} or $repo{web};

    return { resources => { repository => \%repo } };
}

sub _execute {
    my ($command) = @_;
    $ENV{LC_ALL} = "C";
    `$command`;
}

# Copy-Paste of Module-Install-Repository, thank MIYAGAWA
sub _find_repo {
    my ( $self, $execute ) = @_;

    my %repo;

    if ( -e ".git" ) {
        $repo{type} = 'git';
        if ( $execute->( 'git remote show -n ' . $self->git_remote ) =~
            /URL: (.*)$/m )
        {
            # XXX Make it public clone URL, but this only works with github
            my $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;

            $repo{url} = $git_url unless $git_url eq 'origin';    # RT 55136

            if ( $git_url =~ /^(?:git|https?):\/\/(github\.com.*?)\.git$/ ) {
                $repo{web} = "https://$1";

                if ( $self->github_http ) {

                    # I prefer https://github.com/user/repository
                    # to git://github.com/user/repository.git
                    delete $repo{url};
                    $self->log( "github_http is deprecated.  "
                          . "Consider using META.json instead,\n"
                          . "which can store URLs for both git clone "
                          . "and the web front-end." );
                }    # end if github_http
            }    # end if Github repository

        }
        elsif ( $execute->('git svn info') =~ /URL: (.*)$/m ) {
            %repo = ( qw(type svn  url), $1 );
        }

        # invalid github remote might come back with just the remote name
        if ( $repo{url} && $repo{url} =~ /\A\w+\z/ ) {
            delete $repo{$_} for qw/url type web/;
            $self->log( "Skipping invalid git remote " . $self->git_remote );
        }
    }
    elsif ( -e ".svn" ) {
        $repo{type} = 'svn';
        if ( $execute->('svn info') =~ /URL: (.*)$/m ) {
            my $svn_url = $1;
            if ( $svn_url =~ /^https(\:\/\/.*?\.googlecode\.com\/svn\/.*)$/ ) {
                $svn_url = 'http' . $1;
            }
            $repo{url} = $svn_url;
        }
    }
    elsif ( -e "_darcs" ) {

        # defaultrepo is better, but that is more likely to be ssh, not http
        $repo{type} = 'darcs';
        if ( my $query_repo = $execute->('darcs query repo') ) {
            if ( $query_repo =~ m!Default Remote: (http://.+)! ) {
                return %repo, url => $1;
            }
        }

        open my $handle, '<', '_darcs/prefs/repos' or return;
        while (<$handle>) {
            chomp;
            return %repo, url => $_ if m!^http://!;
        }
    }
    elsif ( -e ".hg" ) {
        $repo{type} = 'hg';
        if ( $execute->('hg paths') =~ /default = (.*)$/m ) {
            my $mercurial_url = $1;
            $mercurial_url =~ s!^ssh://hg\@(bitbucket\.org/)!https://$1!;
            $repo{url} = $mercurial_url;
        }
    }
    elsif ( -e "$ENV{HOME}/.svk" ) {

        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = $execute->('svk info') or return;
      SVK_INFO: {
            if ( $svk_info =~ /Mirrored From: (.*), Rev\./ ) {
                return qw(type svn  url) => $1;
            }

            if ( $svk_info =~ m!Merged From: (/mirror/.*), Rev\.! ) {
                $svk_info = $execute->("svk info /$1") or return;
                redo SVK_INFO;
            }
        }
    }

    return %repo;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Repository - Automatically sets repository URL from svn/svk/Git checkout for Dist::Zilla

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    # dist.ini
    [Repository]

=head1 DESCRIPTION

The code is mostly a copy-paste of L<Module::Install::Repository>

=head2 ATTRIBUTES

=over 4

=item * git_remote

This is the name of the remote to use for the public repository (if
you use Git). By default, unsurprisingly, to F<origin>.

=item * github_http

B<This attribute is deprecated.>
If the remote is a GitHub repository, list only the https url
(https://github.com/fayland/dist-zilla-plugin-repository) and not the actual
clonable url (git://github.com/fayland/dist-zilla-plugin-repository.git).
This used to default to true, but as of 0.16 it defaults to false.

The CPAN Meta 2 spec defines separate keys for the clonable C<url> and
web front-end C<web>.  The Meta 1 specs allowed only 1 URL.  If you
set C<github_http> to true, the C<url> key will be removed from the v2
metadata, and the v1 metadata will then use the C<web> key.

Instead of setting C<github_http>, you should use the MetaJSON plugin
to include a v2 META.json file with both URLs.

=item * repository

You can set this attribute if you want a specific repository instead of the
plugin to auto-identify your repository.

An example would be if you're releasing a module from your fork, and you don't
want it to identify your fork, so you can specify the repository explicitly.

In the L<Meta 2 spec|CPAN::Meta::Spec>, this is the C<url> key.

=item * type

This should be the (lower-case) name of the most common program used
to work with the repository, e.g. git, svn, cvs, darcs, bzr or hg.
It's normally determined automatically, but you can override it.

=item * web

This is a URL pointing to a human-usable web front-end for the
repository.  Currently, only Github repositories get this set automatically.

=back

=for Pod::Coverage metadata

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Moritz Onken <onken@netcubed.de>

=item *

Christopher J. Madsen <perl@cjmweb.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam, Ricardo SIGNES, Moritz Onken, Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
