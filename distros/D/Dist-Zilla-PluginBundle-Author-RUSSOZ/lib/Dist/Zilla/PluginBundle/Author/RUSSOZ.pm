package Dist::Zilla::PluginBundle::Author::RUSSOZ;

use strict;
use warnings;

# ABSTRACT: configure Dist::Zilla like RUSSOZ
our $VERSION = '0.024';    # VERSION

use Moose 0.99;
use namespace::autoclean 0.09;
use version;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has fake => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        return 1 if exists $ENV{FAKE};
        ( defined $_[0]->payload->{fake} and $_[0]->payload->{fake} == 1 )
          ? 1
          : 0;
    },
);

has version => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return ( $_[0]->payload->{version} or 'none' ) },
);

has _version_types => (
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    lazy    => 1,
    builder => '_build_version_types',
);

sub _build_version_types {
    my $self = shift;
    return {
        'none'    => sub { },
        'auto'    => sub { $self->add_plugins('AutoVersion') },
        'gitnext' => sub { $self->add_plugins('Git::NextVersion') },
        'module'  => sub { $self->add_plugins('VersionFromMainModule') },
    };
}

sub _add_version {
    my $self = shift;
    my $spec = $self->version;
    return unless exists $self->_version_types->{$spec};
    $self->_version_types->{$spec}->();
    return;
}

has auto_prereqs => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => 1,
);

has use_no404 => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        ( defined $_[0]->payload->{use_no404}
              and $_[0]->payload->{use_no404} == 1 ) ? 1 : 0;
    },
);

has git => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        ( defined $_[0]->payload->{git} and $_[0]->payload->{git} == 0 )
          ? 0
          : 1;
    },
);

has github => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        return 0 unless $_[0]->git;
        ( defined $_[0]->payload->{github} and $_[0]->payload->{github} == 0 )
          ? 0
          : 1;
    },
);

has task_weaver => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        ( defined $_[0]->payload->{task_weaver}
              and $_[0]->payload->{task_weaver} == 1 ) ? 1 : 0;
    },
);

has signature => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        ( defined $_[0]->payload->{signature}
              and $_[0]->payload->{signature} == 0 ) ? 0 : 1;
    },
);

has report => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        ( defined $_[0]->payload->{report} and $_[0]->payload->{report} == 1 )
          ? 1
          : 0;
    },
);

sub configure {
    my $self = shift;

    # Basic sans upload
    $self->add_plugins(
        'GatherDir', 'PruneCruft',  'ManifestSkip', 'MetaYAML',
        'License',   'ExecDir',     'ShareDir',     'MakeMaker',
        'Manifest',  'TestRelease', 'ConfirmRelease',
    );
    $self->fake
      ? $self->add_plugins('FakeRelease')
      : $self->add_plugins('UploadToCPAN');

    $self->_add_version();

    $self->add_plugins('OurPkgVersion') unless $self->version eq 'module';
    $self->add_plugins(
        'MetaJSON',
        'ReadmeFromPod',
        'InstallGuide',
        'PerlTidy',
        [
            'GitFmtChanges' => {
                max_age    => 365,
                tag_regexp => q{^.*$},
                file_name  => q{Changes},
                log_format => q{short},
            }
        ],
    );

    $self->add_plugins('GithubMeta')  if $self->github;
    $self->add_plugins('AutoPrereqs') if $self->auto_prereqs;

    if ( $self->task_weaver ) {
        $self->add_plugins('TaskWeaver');
    }
    else {
        $self->add_plugins( 'ReportVersions::Tiny',
            [ 'PodWeaver' => { config_plugin => '@Author::RUSSOZ' }, ],
        );

        $self->add_plugins('Test::UseAllModules');
        $self->add_bundle( 'TestingMania' =>
              { disable => [ 'Test::CPAN::Changes', 'Test::Synopsis', ], } );
        $self->add_plugins('Test::Pod::No404s')
          if ( $self->use_no404 || $ENV{NO404} );
    }

    $self->add_plugins('Signature')   if $self->signature;
    $self->add_plugins('ReportPhase') if $self->report;
    $self->add_bundle('Git')          if $self->git;

    $self->add_plugins('ExtraTests');

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::RUSSOZ - configure Dist::Zilla like RUSSOZ

=head1 VERSION

version 0.024

=head1 SYNOPSIS

	# in dist.ini
	[@Author::RUSSOZ]
	; fake = 0
	; version = none | auto | gitnext
	; auto_prereqs = 1
	; github = 1
	; use_no404 = 0
	; task_weaver = 0
	; signature = 1
	; report = 0

=head1 DESCRIPTION

C<Dist::Zilla::PluginBundle::Author::RUSSOZ> provides shorthand for
a L<Dist::Zilla> configuration approximately like:

	[@Basic]

	[MetaJSON]
	[ReadmeFromPod]
	[InstallGuide]
	[GitFmtChanges]
	max_age    = 365
	tag_regexp = ^.*$
	file_name  = Changes
	log_format = short

	[OurPkgVersion]
	[GithubMeta]                        ; if github = 1
	[AutoPrereqs]                       ; unless auto_prereqs = 0

	[ReportVersions::Tiny]
	[PodWeaver]
	config_plugin = @Author::RUSSOZ

	; if task_weaver =1
	[TaskWeaver]

	; else (task_weaver = 0)
	[@TestingMania]
	disable = Test::CPAN::Changes, SynopsisTests
	; [Test::Pod::No404]

	; endif

	[Signature]                         ; if signature = 1
	[ReportPhase]                       ; if report = 1
	[@Git]

=head1 NAME

Dist::Zilla::PluginBundle::Author::RUSSOZ - configure Dist::Zilla like RUSSOZ

=head1 VERSION

version 0.024

=head1 TASK CONTENTS

=head1 USAGE

Just put C<[@Author::RUSSOZ]> in your F<dist.ini>. You can supply the following
options:

=for :list * version
How to handle version numbering. Possible values: none,
auto (will use L<Dist::Zilla::Plugin::AutoVersion>),
gitnext (will use Dist::Zilla::Plugin::Git::NextVersion).
Default = none.
* auto_prereqs
Whether the module will use C<AutoPrereqs> or not. Default = 1.
* github
If using github, enable C<[GithubMeta]>. Default = 1.
* use_no404
Whether to use C<[Test::Pod::No404]> in the distribution. Default = 0.
* task_weaver
Set to 1 if this is a C<Task::> distribution. It will enable C<[TaskWeaver]>
while disabling C<[PodWeaver]> and all release tests. Default = 0.
* fake
Set to 1 if this is a fake release. It will disable [UploadToCPAN] and
enable [FakeRelease]. It can also be enabled by setting the environemnt
variable C<FAKE>. Default = 0.
* signature
Whether to GPG sign the module or not. Default = 1.
* report
Whether to report the Dist::Zilla building phases. Default = 0.

=for Pod::Coverage configure

=head1 SEE ALSO

C<< L<Dist::Zilla> >>

=head1 ACKNOWLEDGMENTS

Much of the first implementation was shamelessly copied from
C<Dist::Zilla::PluginBundle::Author::DOHERTY>.

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2017 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2017 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
