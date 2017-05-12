package Dist::Zilla::PluginBundle::AMD;
# git description: v0.010-2-g993fa5a

BEGIN {
  $Dist::Zilla::PluginBundle::AMD::AUTHORITY = 'cpan:AMD';
}
{
  $Dist::Zilla::PluginBundle::AMD::VERSION = '0.011';
}
# ABSTRACT: Build your distributions like AMD does

use Moose 1.00;
use Method::Signatures::Simple;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(Bool Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use namespace::autoclean -also => 'lower';


has dist => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has authority => (
    is      => 'ro',
    isa     => Str,
    default => 'cpan:AMD',
);

# backcompat
has auto_prereq => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has auto_prereqs => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { shift->auto_prereq },
);

has is_task => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_task',
);

method _build_is_task {
    return $self->dist =~ /^Task-/ ? 1 : 0;
}

has weaver_config_plugin => (
    is      => 'ro',
    isa     => Str,
    default => '@AMD',
);

has static_version => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_static_version',
);

has release_branch => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_release_branch',
);

has disable_pod_coverage_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has disable_trailing_whitespace_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has disable_tab_tests => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has bugtracker_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_bugtracker_url',
    handles => {
        bugtracker_url => 'as_string',
    },
);

method _build_bugtracker_url {
    return sprintf $self->_rt_uri_pattern, $self->dist;
}

has bugtracker_email => (
    is      => 'ro',
    isa     => EmailAddress,
    lazy    => 1,
    builder => '_build_bugtracker_email',
);

method _build_bugtracker_email {
    return sprintf 'bug-%s@rt.cpan.org', $self->dist;
}

has _rt_uri_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
);

has homepage_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_homepage_url',
    handles => {
        homepage_url => 'as_string',
    },
);

method _build_homepage_url {
    return sprintf $self->_cpansearch_pattern, $self->dist;
}

has _cpansearch_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://metacpan.org/release/%s',
);

has repository => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_url',
    handles => {
        repository_url    => 'as_string',
        repository_scheme => 'scheme',
    },
);

has repository_at => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_repository_at',
);

has github_user => (
    is      => 'ro',
    isa     => Str,
    default => 'amd',
);

my $map_tc = Map[
    Str, Dict[
        pattern     => CodeRef,
        web_pattern => CodeRef,
        type        => Optional[Str],
        mangle      => Optional[CodeRef],
    ]
];

coerce $map_tc, from Map[
    Str, Dict[
        pattern     => Str|CodeRef,
        web_pattern => Str|CodeRef,
        type        => Optional[Str],
        mangle      => Optional[CodeRef],
    ]
], via {
    my %in = %{ $_ };
    return { map {
        my $k = $_;
        ($k => {
            %{ $in{$k} },
            (map {
                my $v = $_;
                (ref $in{$k}->{$v} ne 'CODE'
                     ? ($v => sub { $in{$k}->{$v} })
                     : ()),
            } qw(pattern web_pattern)),
        })
    } keys %in };
};

has _repository_host_map => (
    traits  => [qw(Hash)],
    isa     => $map_tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build__repository_host_map',
    handles => {
        _repository_data_for => 'get',
    },
);

sub lower { lc shift }

method _build__repository_host_map {
    my $github_pattern = sub { sprintf 'git://github.com/%s/%%s.git', $self->github_user };
    my $github_web_pattern = sub { sprintf 'http://github.com/%s/%%s', $self->github_user };
    my $scsys_web_pattern_proto = sub {
        return sprintf 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=%s/%%s.git;a=summary', $_[0];
    };

    return {
        github => {
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
            # mangle      => \&lower,
        },
        GitHub => {
            pattern     => $github_pattern,
            web_pattern => $github_web_pattern,
        },
        gitmo => {
            pattern     => 'git://git.moose.perl.org/%s.git',
            web_pattern => $scsys_web_pattern_proto->('gitmo'),
        },
        catsvn => {
            type        => 'svn',
            pattern     => 'http://dev.catalyst.perl.org/repos/Catalyst/%s/',
            web_pattern => 'http://dev.catalystframework.org/svnweb/Catalyst/browse/%s',
        },
        (map {
            ($_ => {
                pattern     => "git://git.shadowcat.co.uk/${_}/%s.git",
                web_pattern => $scsys_web_pattern_proto->($_),
            })
        } qw(catagits p5sagit dbsrgits)),
    };
}

method _build_repository_url {
    return $self->_resolve_repository_with($self->repository_at, 'pattern')
        if $self->has_repository_at;
    confess "Cannot determine repository url without repository_at. "
          . "Please provide either repository_at or repository."
}

has repository_web => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_repository_web',
    handles => {
        repository_web => 'as_string',
    },
);

method _build_repository_web {
    return $self->_resolve_repository_with($self->repository_at, 'web_pattern')
        if $self->has_repository_at;
    confess "Cannot determine repository web url without repository_at. "
          . "Please provide either repository_at or repository_web."
}

method _resolve_repository_with ($service, $thing) {
    my $dist = $self->dist;
    my $data = $self->_repository_data_for($service);
    confess "unknown repository service $service" unless $data;
    return sprintf $data->{$thing}->(),
        (exists $data->{mangle}
             ? $data->{mangle}->($dist)
             : $dist);
}

has repository_type => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_repository_type',
);

method _build_repository_type {
    my $data = $self->_repository_data_for($self->repository_at);
    return $data->{type} if exists $data->{type};

    for my $vcs (qw(git svn)) {
        return $vcs if $self->repository_scheme eq $vcs;
    }

    confess "Unable to guess repository type based on the repository url. "
          . "Please provide repository_type.";
}

override BUILDARGS => method ($class:) {
    my $args = super;
    return { %{ $args->{payload} }, %{ $args } };
};

method configure {
    # like @Basic, without License
    $self->add_plugins(qw(
      GatherDir
      PruneCruft
      ManifestSkip
      MetaYAML
      Readme
      ExtraTests
      ExecDir
      ShareDir
      MakeMaker
      Manifest
      TestRelease
      ConfirmRelease
      UploadToCPAN
    ));

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
    ));

    $self->add_plugins('NoTabsTests')
        unless $self->disable_tab_tests;

    $self->add_plugins('PodCoverageTests')
        unless $self->disable_pod_coverage_tests;

    $self->add_plugins(
        [MetaResources => {
            'repository.type'   => $self->repository_type,
            'repository.url'    => $self->repository_url,
            'repository.web'    => $self->repository_web,
            'bugtracker.web'    => $self->bugtracker_url,
            'bugtracker.mailto' => $self->bugtracker_email,
            'homepage'          => $self->homepage_url,
        }],
        [Authority => {
            authority   => $self->authority,
            do_metadata => 1,
        }],
        [EOLTests => {
            trailing_whitespace => $self->disable_trailing_whitespace_tests ? 0 : 1,
        }],
    );

    $self->is_task
        ? $self->add_plugins('TaskWeaver')
        : $self->add_plugins(
              [PodWeaver => {
                  config_plugin => $self->weaver_config_plugin,
              }],
          );

    $self->add_plugins('AutoPrereqs') if $self->auto_prereqs;


    $self->add_plugins('Git::Describe');
    $self->add_plugins('CheckChangesHasContent');

    $self->add_plugins(['NextRelease' =>
                       { format => '%-9v %{yyyy-MM-dd}d' }]);

    $self->add_plugins(['Git::CheckFor::CorrectBranch' =>
                        { release_branch => ($self->has_release_branch
                                             ? $self->release_branch
                                             : 'github')
                        }]);

    if ($self->has_static_version) {
            $self->add_plugins(['StaticVersion' => { version => $self->static_version }]);
    } else {
            $self->add_plugins('Git::NextVersion');
    }

    $self->add_bundle('@Git');
}

with 'Dist::Zilla::Role::PluginBundle::Easy';

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::AMD - Build your distributions like AMD does

=head1 SYNOPSIS

In dist.ini:

  [@AMD]
  dist = Distribution-Name
  repository_at = github

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration I use to build my
distributions.

It is roughly equivalent to:

  [@Basic] # without "License"

  [MetaConfig]
  [MetaJSON]
  [PkgVersion]
  [PodSyntaxTests]
  [PodCoverageTests]
  [NoTabsTests]
  [EOLTests]

  [MetaResources]
  repository.type   = git
  repository.url    = git://github.com/amd/${dist}
  repository.web    = http://github.com/amd/${dist}
  bugtracker.web    = http://rt.cpan.org/Public/Dist/Display.html?Name=${dist}
  bugtracker.mailto = bug-${dist}@rt.cpan.org
  homepage          = http://metacpan.org/release/${dist}

  [Authority]
  authority   = cpan:AMD
  do_metadata = 1

  [PodWeaver]
  config_plugin = @AMD

  [AutoPrereqs]
  [Git::Describe]

  [CheckChangesHasContent]

  [NextRelease]

  [Git::CheckFor::CorrectBranch]
  release_branch = github

  # if static_version
    [StaticVersion]
  # else
    [Git::NextVersion]

  [@Git]

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

