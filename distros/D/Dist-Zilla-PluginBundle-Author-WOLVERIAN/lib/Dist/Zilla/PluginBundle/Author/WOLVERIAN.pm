package Dist::Zilla::PluginBundle::Author::WOLVERIAN;
BEGIN {
  $Dist::Zilla::PluginBundle::Author::WOLVERIAN::AUTHORITY = 'cpan:WOLVERIAN';
}
BEGIN {
  $Dist::Zilla::PluginBundle::Author::WOLVERIAN::VERSION = 'v0.0.8';
}

use MooseX::Declare;

# ABSTRACT: Dist::Zilla according to wolverian
class Dist::Zilla::PluginBundle::Author::WOLVERIAN
    with Dist::Zilla::Role::PluginBundle::Easy {

    use Moose::Autobox;

    use Dist::Zilla::Plugin::ModuleBuild;
    use Dist::Zilla::Plugin::AutoPrereqs;
    use Dist::Zilla::Plugin::MinimumPerl;
    use Dist::Zilla::Plugin::MetaJSON;
    use Dist::Zilla::Plugin::PodWeaver;
    use Dist::Zilla::Plugin::InstallGuide;

    use Dist::Zilla::Plugin::Git;

    use Dist::Zilla::Plugin::MetaTests;
    use Dist::Zilla::Plugin::PodSyntaxTests;
    use Dist::Zilla::Plugin::PodCoverageTests;
    use Dist::Zilla::Plugin::EOLTests;
    use Dist::Zilla::Plugin::MinimumVersionTests;

    use Dist::Zilla::Plugin::Authority;
    use Dist::Zilla::Plugin::Bugtracker;
    use Dist::Zilla::Plugin::Repository;
    use Dist::Zilla::Plugin::GithubMeta;

    method configure {
        $self->add_bundle(Filter => {
            -bundle => '@Basic',
            -remove => ["MakeMaker"]
        });

        $self->add_bundle(Filter => {
            -bundle     => '@Git',
            -remove     => ['Git::Commit'],
            tag_format  => '%v',
            tag_message => '%v'
        });

        $self->add_plugins(qw/
            ModuleBuild
            AutoPrereqs
            PkgVersion
            MinimumPerl
            MetaJSON
            PodWeaver
            InstallGuide

            MetaTests
            PodSyntaxTests
            PodCoverageTests
            EOLTests
            MinimumVersionTests

            Bugtracker
            Repository
            GithubMeta
        /);

        my $authority_conf = $self->config_slice('authority');

        $self->add_plugins([
            Authority => (
                $authority_conf->exists('authority')
                    ? $authority_conf
                    : { authority => 'cpan:WOLVERIAN' }
            )
        ]);

        $self->add_plugins([
            "Git::NextVersion" => {
                first_version  => "v0.0.1",
                version_regexp => '^(v.+)$'
            }
        ]);
    }
}

# vi: ft=perl-mxd et

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::WOLVERIAN - Dist::Zilla according to wolverian

=head1 VERSION

version v0.0.8

=head1 AUTHOR

Ilmari Vacklin <ilmari.vacklin@cs.helsinki.fi>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ilmari Vacklin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

