package Dist::Zilla::PluginBundle::Dancer;
BEGIN {
  $Dist::Zilla::PluginBundle::Dancer::AUTHORITY = 'cpan:YANICK';
}
$Dist::Zilla::PluginBundle::Dancer::VERSION = '0.0013';
# ABSTRACT: dzil plugins used by Dancer projects


use 5.10.0;

use strict;

use PerlX::Maybe;

use Moose;

with 'Dist::Zilla::Role::PluginBundle::Easy';

has authority => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub { $_[0]->payload->{authority} },
);

has git_remote => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->payload->{git_remote} || 'origin' },
);

sub test_compile_skip {
        return maybe skip => $_[0]->payload->{test_compile_skip}; 
};

has include_dotfiles => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    default => sub {
        $_[0]->payload->{include_dotfiles} // 1;
    },
);

sub configure {
    my ( $self ) = @_;
    my $arg = $self->payload;

    $self->add_plugins(
        [ 'GatherDir' => { 
                include_dotfiles => $self->include_dotfiles
            },
        ],
        [ 'Test::Compile' => { 
                $self->test_compile_skip,
                ':version' => '2.039',
            } ],
        qw/ 
            MetaTests
            Test::NoTabs
            PodSyntaxTests
            ExtraTests
            Test::ReportPrereqs
            PodWeaver
            PruneCruft
            ManifestSkip
            ExecDir
        /,
        [ 'AutoPrereqs' => { 
                ( skip => $arg->{autoprereqs_skip} )x!!$arg->{autoprereqs_skip} 
        } ],
        'MetaProvides::Package',
        'PkgVersion',
    );

    if ( my $authority = $self->authority ) {
        $self->add_plugins(
            [ 'Authority' => { authority => $authority } ],
        );
    }

    $self->add_plugins(
        qw/
            License
            MakeMaker
            MetaYAML
            MetaJSON
            /,
        [ 'GithubMeta' => { issues => 1, remote => $self->git_remote } ], 
        qw/
            Manifest
            UploadToCPAN
        /,
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Dancer - dzil plugins used by Dancer projects

=head1 VERSION

version 0.0013

=head1 DESCRIPTION

This is the plugin bundle that the core L<Dancer> crew use to release
their distributions. It's roughly equivalent to

    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [ExecDir]

    [AutoPrereqs]
    [MetaProvides::Package]
    [License]
    [MakeMaker]
    [MetaYAML]
    [MetaJSON]

    [GithubMeta]
    issues = 1
    remote = <git_remote>

    [Manifest]

    [PkgVersion]

    [Authority]

    [Test::Compile]
    [MetaTests]
    [Test::NoTabs]
    [PodSyntaxTests]
    [Test::ReportPrereqs]

    [PodWeaver]

    [UploadToCPAN]

=head2 ARGUMENTS

=head3 authority

For L<Dist::Zilla::Plugin::Authority>. If not given,
L<Dist::Zilla::Plugin::Authority> will not be used.

=head3 test_compile_skip

I<skip> option for L<Dist::Zilla::Plugin::Test::Compile>.

=head3 autoprereqs_skip

I<skip> option for L<Dist::Zilla::Plugin::AutoPrereqs>.

=head3 include_dotfiles

For L<Dist::Zilla::Plugin::GatherDir>. Defaults to I<1>.

=head3 git_remote

For the C<remote> argument of L<Dist::Zilla::Plugin::GithubMeta>. Defaults to
'origin'.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
