# This Build.PL for Dist-Zilla-PluginBundle-Git-VersionManager was generated by
# Dist::Zilla::Plugin::ModuleBuildTiny::Fallback 0.025
use strict;
use warnings;

my %configure_requires = (
    'ExtUtils::MakeMaker' => '0',
    'Module::Build::Tiny' => '0.034',
);

my %errors = map {
    eval "require $_; $_->VERSION($configure_requires{$_}); 1";
    $_ => $@,
} keys %configure_requires;

if (!grep { $_ } values %errors)
{
    # This section for Dist-Zilla-PluginBundle-Git-VersionManager was generated by Dist::Zilla::Plugin::ModuleBuildTiny 0.015.
    use strict;
    use warnings;

    use 5.010;
    # use Module::Build::Tiny 0.034;
    Module::Build::Tiny::Build_PL();
}
else
{
    if (not $ENV{PERL_MB_FALLBACK_SILENCE_WARNING})
    {
        warn <<'EOW'
*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***

If you're seeing this warning, your toolchain is really, really old* and you'll
almost certainly have problems installing CPAN modules from this century. But
never fear, dear user, for we have the technology to fix this!

If you're using CPAN.pm to install things, then you can upgrade it using:

    cpan CPAN

If you're using CPANPLUS to install things, then you can upgrade it using:

    cpanp CPANPLUS

If you're using cpanminus, you shouldn't be seeing this message in the first
place, so please file an issue on github.

This public service announcement was brought to you by the Perl Toolchain
Gang, the irc.perl.org #toolchain IRC channel, and the number 42.

----

* Alternatively, you are running this file manually, in which case you need
to learn to first fulfill all configure requires prerequisites listed in
META.yml or META.json -- or use a cpan client to install this distribution.

You can also silence this warning for future installations by setting the
PERL_MB_FALLBACK_SILENCE_WARNING environment variable, but please don't do
that until you fix your toolchain as described above.


Errors from configure prereqs:
EOW
        . do {
            require Data::Dumper; Data::Dumper->new([ \%errors ])->Indent(2)->Terse(1)->Sortkeys(1)->Dump;
        };

        sleep 10 if -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
    }


    # This section was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.011.
    use strict;
    use warnings;

    require Module::Build; Module::Build->VERSION(0.28);


    my %module_build_args = (
      "configure_requires" => {
        "ExtUtils::MakeMaker" => 0,
        "Module::Build::Tiny" => "0.034",
        "perl" => "5.010"
      },
      "dist_abstract" => "A plugin bundle that manages your version in git",
      "dist_author" => [
        "Karen Etheridge <ether\@cpan.org>"
      ],
      "dist_name" => "Dist-Zilla-PluginBundle-Git-VersionManager",
      "dist_version" => "0.007",
      "license" => "perl",
      "module_name" => "Dist::Zilla::PluginBundle::Git::VersionManager",
      "recursive_test_files" => 1,
      "requires" => {
        "CPAN::Meta::Requirements" => 0,
        "Dist::Zilla::Plugin::BumpVersionAfterRelease" => "0.016",
        "Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional" => "0.004",
        "Dist::Zilla::Plugin::CopyFilesFromRelease" => 0,
        "Dist::Zilla::Plugin::Git::Commit" => "2.020",
        "Dist::Zilla::Plugin::Git::NextVersion" => 0,
        "Dist::Zilla::Plugin::Git::Tag" => 0,
        "Dist::Zilla::Plugin::NextRelease" => "5.033",
        "Dist::Zilla::Plugin::Prereqs" => 0,
        "Dist::Zilla::Plugin::RewriteVersion::Transitional" => "0.004",
        "Dist::Zilla::Plugin::VersionFromMainModule" => "0.04",
        "Dist::Zilla::Role::FileMunger" => 0,
        "Dist::Zilla::Role::PluginBundle::Config::Slicer" => 0,
        "Dist::Zilla::Role::PluginBundle::Easy" => 0,
        "Dist::Zilla::Role::PluginBundle::PluginRemover" => "0.103",
        "Dist::Zilla::Util" => 0,
        "List::Util" => "1.45",
        "Moose" => 0,
        "Moose::Util" => 0,
        "Moose::Util::TypeConstraints" => 0,
        "namespace::autoclean" => 0,
        "perl" => "5.010",
        "strict" => 0,
        "warnings" => 0
      },
      "test_requires" => {
        "CPAN::Meta::Check" => "0.011",
        "CPAN::Meta::Requirements" => 0,
        "Exporter" => 0,
        "File::Spec" => 0,
        "JSON::MaybeXS" => 0,
        "Module::Metadata" => 0,
        "Path::Tiny" => 0,
        "Test::DZil" => 0,
        "Test::Deep" => 0,
        "Test::Fatal" => 0,
        "Test::More" => "0.96",
        "if" => 0,
        "lib" => 0,
        "namespace::clean" => 0,
        "parent" => 0,
        "perl" => "5.010"
      }
    );


    my %fallback_build_requires = (
      "CPAN::Meta::Check" => "0.011",
      "CPAN::Meta::Requirements" => 0,
      "Exporter" => 0,
      "File::Spec" => 0,
      "JSON::MaybeXS" => 0,
      "Module::Metadata" => 0,
      "Path::Tiny" => 0,
      "Test::DZil" => 0,
      "Test::Deep" => 0,
      "Test::Fatal" => 0,
      "Test::More" => "0.96",
      "if" => 0,
      "lib" => 0,
      "namespace::clean" => 0,
      "parent" => 0,
      "perl" => "5.010"
    );


    unless ( eval { Module::Build->VERSION(0.4004) } ) {
      delete $module_build_args{test_requires};
      $module_build_args{build_requires} = \%fallback_build_requires;
    }

    my $build = Module::Build->new(%module_build_args);


    $build->create_build_script;
}
