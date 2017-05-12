use strict;
use warnings;
package Dist::Zilla::Plugin::AutoMetaResources;
our $AUTHORITY = 'cpan:AJGB';
#ABSTRACT: Automagical MetaResources
$Dist::Zilla::Plugin::AutoMetaResources::VERSION = '1.21';
use Moose;
with 'Dist::Zilla::Role::MetaProvider';


sub _subs(@) {
    my ($format, $vars) = @_;
    $format =~ s/%\{([\w_\.]+)\}/$vars->{$1} || ''/ge;
    return $format;
}

has '_resources' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);


has '_repository_map' => (
    is => 'ro',
    lazy => 1,
    builder => '_build__repository_map',
);

sub _build__repository_map {
    # based on Dist::Zilla::PluginBundle::FLORA
    return {
        github => {
            url => 'git://github.com/%{user}/%{lcdist}.git',
            web => 'https://github.com/%{user}/%{lcdist}',
            type => 'git',
        },
        gitmo => {
            url => 'git://git.moose.perl.org/%{dist}.git',
            web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/%{dist}.git;a=summary',
            type => 'git',
        },
        catsvn => {
            url => 'http://dev.catalyst.perl.org/repos/Catalyst/%{dist}/',
            web => 'http://dev.catalystframework.org/svnweb/Catalyst/browse/%{dist}',
            type => 'svn',
        },
        bitbucket => {
            url  => 'git://bitbucket.org:%{user}/%{lcdist}.git',
            web  => 'https://bitbucket.org/%{user}/%{lcdist}',
            type => 'git',
        },
        (map {
            ($_ => {
                url     => "git://git.shadowcat.co.uk/$_/%{dist}.git",
                web => "http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=$_/%{dist}.git;a=summary",
                type    => 'git',
            })
        } qw(catagits p5sagit dbsrgits)),
    };
}

has '_bugtracker_map' => (
    is => 'ro',
    lazy => 1,
    builder => '_build__bugtracker_map',
);

sub _build__bugtracker_map {
    return {
        rt => {
            web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=%{dist}',
            mailto => 'bug-%{dist}@rt.cpan.org',
        },
        github => {
            web => 'https://github.com/%{user}/%{lcdist}/issues',
        },
        bitbucket => {
            web => 'https://bitbucket.org/%{user}/%{lcdist}/issues',
        },
    };
}

sub BUILDARGS {
    my ($class, @arg) = @_;
    my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};

    return {
        zilla => $zilla,
        plugin_name => $name,
        _resources => \%copy,
    }
}


sub metadata {
    my $self = shift;

    my $resources = {};
    my %names = (
        dist => $self->zilla->name,
        lcdist => lc $self->zilla->name,
    );

    while (my ($arg, $opts) = each %{$self->_resources} ) {
        next unless $opts;

        my ($res, $type) = split(/\./, $arg);

        if ( my $method = $self->can("_${res}_map") ) {
            next unless $type;
            my $map = $method->($self)->{lc $type};
            for my $var ( keys %$map ) {
                $resources->{$res}->{$var} = _subs $map->{$var}, {
                    %names,
                    (
                        ref $opts ?
                            %{$opts->[0]} :
                            map {
                                my ($k, $v) = split(/:/, $_);
                                $k => $v
                            } split(/;/, $opts)
                    )
                };
            }
        } else {
            $resources->{$arg} = _subs $opts, \%names;
        }
    }

    return {
        resources => $resources,
    };
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AutoMetaResources - Automagical MetaResources

=head1 VERSION

version 1.21

=head1 SYNOPSIS

    # dist.ini
    name = Dist-Zilla-Plugin-AutoMetaResources
    ...

    [AutoMetaResources]
    bugtracker.github  = user:ajgb
    repository.github  = user:ajgb
    homepage           = https://metacpan.org/release/%{dist}

or in PluginBundle::Easy

    $self->add_plugins(
        [
            AutoMetaResources => {
                'bugtracker.github' => [{ user => 'ajgb' }],
                'repository.github' => [{ user => 'ajgb' }],
                'homepage' => 'https://metacpan.org/release/%{dist}',
            }
        ]
    );

both for Dist::Zilla::Plugin::AutoMetaResources would be equivalent of

    [MetaResources]
    bugtracker.web    = https://github.com/ajgb/dist-zilla-plugin-autometaresources/issues
    repository.url    = git://github.com/ajgb/dist-zilla-plugin-autometaresources.git
    repository.web    = http://github.com/ajgb/dist-zilla-plugin-autometaresources
    repository.type   = git
    homepage          = https://metacpan.org/release/Dist-Zilla-Plugin-AutoMetaResources

=head1 DESCRIPTION

If you find repeating the dist name again in the configuration really
annoying, this plugin comes to the rescue!

=head1 CONFIGURATION

Most of the known resources requires just boolean flag to be enabled, but you
are free to pass your own options:

    bugtracker.rt =  dist:Other-Name;lcdist:other-name

which is transformed to:

    [{
        dist => 'Other-Name',
        lcdist => 'other-name',
    }]

=head2 BUGTRACKER

B<RT bugtracker>:

    [AutoMetaResources]
    bugtracker.rt = 1

    # same as
    [MetaResources]
    bugtracker.web    = https://rt.cpan.org/Public/Dist/Display.html?Name=%{dist}
    bugtracker.mailto = bug-%{dist}@rt.cpan.org

B<GitHub issues>:

    [AutoMetaResources]
    bugtracker.github = user:ajgb

    # same as
    [MetaResources]
    bugtracker.web    = http://github.com/ajgb/%{lcdist}/issues

B<Bitbucket issues>:

    [AutoMetaResources]
    bugtracker.bitbucket = user:ajgb

    # same as
    [MetaResources]
    bugtracker.web    = https://bitbucket.org/ajgb/%{lcdist}/issues

=head2 REPOSITORY

B<GitHub repository>:

    [AutoMetaResources]
    repository.github = user:ajgb
    # or
    repository.GitHub = user:ajgb

    # same as
    [MetaResources]
    repository.url    = git://github.com/ajgb/%{lcdist}.git
    repository.web    = http://github.com/ajgb/%{lcdist}
    repository.type   = git

B<Bitbucket repository>:

    [AutoMetaResources]
    repository.bitbucket = user:ajgb

    # same as
    [MetaResources]
    repository.url    = git://bitbucket.org:ajgb/%{lcdist}.git
    repository.web    = https://bitbucket.org/ajgb/%{lcdist}
    repository.type   = git

B<Git Moose repository>:

    [AutoMetaResources]
    repository.gitmo = 1

    # same as
    [MetaResources]
    repository.url    = git://git.moose.perl.org/%{dist}.git
    repository.web    = http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/%{dist}.git;a=summary
    repository.type   = git

B<Catalyst Subversion repository>:

    [AutoMetaResources]
    repository.catsvn = 1

    # same as
    [MetaResources]
    repository.url    = http://dev.catalyst.perl.org/repos/Catalyst/%{dist}/
    repository.web    = http://dev.catalystframework.org/svnweb/Catalyst/browse/%{dist}
    repository.type   = svn

B<Shadowcat's Git repositories>:

    [AutoMetaResources]
    repository.catagits = 1

    # same as
    [MetaResources]
    repository.url    = git://git.shadowcat.co.uk/catagits/%{dist}.git
    repository.web    = http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/%{dist}.git;a=summary
    repository.type   = git

and

    [AutoMetaResources]
    repository.p5sagit = 1

    # same as
    [MetaResources]
    repository.url    = git://git.shadowcat.co.uk/p5sagit/%{dist}.git
    repository.web    = http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/%{dist}.git;a=summary
    repository.type   = git

and

    [AutoMetaResources]
    repository.dbsrgits = 1

    # same as
    [MetaResources]
    repository.url    = git://git.shadowcat.co.uk/dbsrgits/%{dist}.git
    repository.web    = http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=dbsrgits/%{dist}.git;a=summary
    repository.type   = git

=head2 OTHER

    [AutoMetaResources]
    homepage = https://metacpan.org/release/%{dist}

You are free to pass other valid metadata options to be included as resources.
Values can contain following variables:

=over

=item I<%{dist}>

Name of the distribution

=item I<%{lcdist}>

Name of the distribution (lowercase)

=back

=for Pod::Coverage     metadata

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
