package Dist::Zilla::Plugin::PERLANCAR::MetaResources;

our $DATE = '2020-10-27'; # DATE
our $VERSION = '0.041'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
#use experimental 'smartmatch';
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::MetaResources';

# both available due to Dist::Zilla
use Path::Class 'dir';
use Config::INI::Reader;

our %transform = (
    'lc' => sub { lc shift },
    'uc' => sub { uc shift },
    deb  => sub { 'lib'. (lc shift) .'-perl' },
    ''   => sub { shift },
);

use String::Formatter method_stringf => {
    -as => '_format_string',
    codes => {
        a => sub { $_[0]->_github->{'account'} },
        r => sub { $_[0]->_github->{'project'} },
        N => sub { $transform{$_[1] || ''}->( $_[0]->name ) },
    },
};

has name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->zilla->name },
);

has remote => (
    is      => 'ro',
    isa     => 'Str',
    default => 'origin',
);

has homepage => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://metacpan.org/release/%N',
);

has bugtracker_web => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://rt.cpan.org/Public/Dist/Display.html?Name=%N',
);

has repository_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'git://github.com/%a/%r.git',
);

has repository_web => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://github.com/%a/%r',
);

has _github => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,
);

sub _build__github {
    my $self = shift;

    my $root = dir('.git');
    my $ini = $root->file('config');

    die "GitHubMeta: need a .git/config file, and you don't have one\n"
        unless -e $ini;

    my $fh = $ini->openr;
    my $config = Config::INI::Reader->read_handle($fh);

    my $remote = $self->remote;
    die "GitHubMeta: no '$remote' remote found in .git/config\n"
        unless exists $config->{qq{remote "$remote"}};

    my $url = $config->{qq{remote "$remote"}}->{'url'};
    die "GitHubMeta: no url found for remote '$remote'\n"
        unless $url and length $url;

    die "GitHubMeta: no github host found in URL '$url'\n"
        unless $url =~ m!(:(//)?|\@)github\.com!i;

    my ($account, $project) = ($url =~ m{[:/]([^/]+)/([^/]+?)(?:\.git)?$});

    die "GitHubMeta: no github account name found in URL '$url'\n"
        unless $account and length $account;
    die "GitHubMeta: no github repository (project) found in URL '$url'\n"
        unless $project and length $project;

    $self->log_debug("github account: $account, github project: $project");
    return { account => $account, project => $project };
}

sub BUILD {
    my ($self, $params) = @_;

    if (eval {exists $params->{resources}->{homepage}}) {
        # if param is customized by the user, format it
        $params->{resources}->{homepage}
            &&= _format_string($params->{resources}->{homepage}, $self);
        # else user has asked for param to be disabled
    }
    else {
        # use our default
        $params->{resources}->{homepage}
            = _format_string($self->homepage, $self);
    }

    if (eval {exists $params->{resources}->{bugtracker}->{web}}) {
        $params->{resources}->{bugtracker}->{web}
            &&= _format_string($params->{resources}->{bugtracker}->{web}, $self);
    }
    else {
        $params->{resources}->{bugtracker}->{web}
            = _format_string($self->bugtracker_web, $self);
    }

    if (eval {exists $params->{resources}->{repository}->{url}}) {
        $params->{resources}->{repository}->{url}
            &&= _format_string($params->{resources}->{repository}->{url}, $self);
    }
    else {
        $params->{resources}->{repository}->{url}
            = _format_string($self->repository_url, $self);
    }

    if (eval {$params->{resources}->{repository}->{url}}) {
        $params->{resources}->{repository}->{type} = 'git';

        if (eval {exists $params->{resources}->{repository}->{web}}) {
            $params->{resources}->{repository}->{web}
                &&= _format_string($params->{resources}->{repository}->{web}, $self);
        }
        else {
            $params->{resources}->{repository}->{web}
                = _format_string($self->repository_web, $self);
        }
    }

    return $params;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# ABSTRACT: Set meta resources for dists

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PERLANCAR::MetaResources - Set meta resources for dists

=head1 VERSION

This document describes version 0.041 of Dist::Zilla::Plugin::PERLANCAR::MetaResources (from Perl distribution Dist-Zilla-Plugin-PERLANCAR-MetaResources), released on 2020-10-27.

=head1 SYNOPSIS

In dist.ini:

 [PERLANCAR::MetaResources]

=head1 DESCRIPTION

Code is based on L<Dist::Zilla::Plugin::MetaResourcesFromGit>. The difference is
the defaults: in this plugin, homepage by default is set to MetaCPAN release
page instead of github wiki.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PERLANCAR-MetaResources>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PERLANCAR-MetaResources>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PERLANCAR-MetaResources>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::PERLANCAR>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
