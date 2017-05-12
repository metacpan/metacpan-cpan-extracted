package Dist::Zilla::Plugin::MetaResourcesFromGit;
BEGIN {
  $Dist::Zilla::Plugin::MetaResourcesFromGit::VERSION = '1.103620';
}

use Moose;
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
    default => 'https://github.com/%a/%r/wiki',
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

    my ($account, $project) = ($url =~ m{[:/](.+)/(.+)\.git$});

    die "GitHubMeta: no github account name found in .git/config\n"
        unless $account and length $account;
    die "GitHubMeta: no github repository (project) found in .git/config\n"
        unless $project and length $project;

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

# ABSTRACT: Metadata resource URLs from Git configuration



__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::MetaResourcesFromGit - Metadata resource URLs from Git configuration

=head1 VERSION

version 1.103620

=head1 SYNOPSIS

In your C<dist.ini> or C<profile.ini>:

 [MetaResourcesFromGit]

=head1 DESCRIPTION

This plugin is a drop-in replacement for L<Dist::Zilla::Plugin::MetaResources>
for users of Git. It I<automatically> provides three resource links to your
distribution metadata, based on the name of the distribution and the remote
URL of the Git repository you are working from.

The default links are equivalent to:

 homepage        = https://github.com/%a/%r/wiki
 bugtracker.web  = https://rt.cpan.org/Public/Dist/Display.html?Name=%N
 repository.url  = git://github.com/%a/%r.git
 repository.web  = https://github.com/%a/%r
 repository.type = git

Any other resources provided to this Plugin are passed through to the
C<MetaResources> Plugin as-is. If you wish to override one of the above, use
the formatting options below. If you wish to suppress the appearance of one of
the above resources, set an empty or false value in C<dist.ini>.

=head1 CONFIGURATION

=head2 Plugin Options

=over 4

=item C<name>

The name of your Perl distribution in the format used by CPAN. It defaults to
the C<name> option you have provided in C<dist.ini>.

=item C<remote>

The alias of the Git remote URL from which the working repository is cloned.
It defaults to C<origin>.

=item C<homepage>

A link on the CPAN page of your distribution, defaulting to the wiki page of a
constructed L<http://github.com> repository for your code. You can use the
formatting options below when overriding this value.

=item C<bugtracker.web>

A link on the CPAN page of your distribution, defaulting to its corresponding
L<http://rt.cpan.org> homepage. You can use the formatting options below when
overriding this value.

=item C<repository.url>

A link on the CPAN page of your distribution, defaulting to the read-only
clone URL belonging to a contructed L<http://github.com> repository for your
code. You can use the formatting options below when overriding this value.

=item C<repository.web>

A link on the CPAN page of your distribution, defaulting to the web based
source browsing page for at L<http://github.com> for the C<repository.url>.
You can use the formatting options below when overriding this value.

=back

=head2 Formatting Options

The following codes may be used when overriding the C<homepage>,
C<bugtracker.web>, <repository.url> and C<repository.web> configuration
options.

=over 4

=item C<%a>

The "account" (username) as parsed from the remote repository URL in the local
Git configuration. This is currently (probably) GitHub-centric.

=item C<%r>

The "repository" (or, project name) as parsed from the remote repiository URL
in the local Git configuration. This is currently (probably) GitHub-centric.

=item C<%N>

The name of the distribution as given to the C<name> option in your
C<dist.ini> file. You can also use C<< %{lc}N >> or C<< %{uc}N >> to get the
name in lower or upper case respectively, or C<< %{deb}N >> to get the name in
a Debian GNU/Linux package-name format (C<libfoo-bar-perl>).

=back

=head1 TODO

=over 4

=item * Make things less GitHub-centric.

=back

=head1 THANKS

To C<cjm> from IRC for suggesting this as a better way to meet my needs.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

