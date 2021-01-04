use strict;
use Test::More;
use Test::Differences;
use Dist::Iller;
use syntax 'qs';
use Path::Tiny;
use DateTime;
use File::chdir;

my $iller = Dist::Iller->new(filepath => 't/corpus/02-builder.yaml');
$iller->parse('before');

my $tempdir = Path::Tiny->tempdir();

my $current_dir = path('.')->realpath;
{
    local $CWD = $tempdir->stringify;
    $iller->generate_files('before');
}
$iller->parse('after');
{
    local $CWD = $tempdir->stringify;
    $iller->generate_files('after');
}


eq_or_diff clean($tempdir->child('dist.ini')->slurp_utf8), clean(dist()), 'Correct dist.ini';
eq_or_diff clean($tempdir->child('weaver.ini')->slurp_utf8), clean(weaver()), 'Correct weaver.ini';

done_testing;

sub clean {
    my $string = shift;
    $string =~ s{^\v}{};
    $string =~ s{^(\s*?;.* on).*}{$1...};
    return $string;
}

sub dist {
    my $current_year = DateTime->now->year;
    return qqs{
        ; This file was auto-generated from iller.yaml by Dist::Iller on

        author = Erik Carlsson
        copyright_year = $current_year

        [GatherDir]

        [PruneCruft]

        [ManifestSkip]

        [MetaYAML]

        [License]

        [Readme]

        [ExtraTests]

        [ExecDir]

        [ShareDir]

        [MakeMaker]

        [Manifest]

        [TestRelease]

        [ConfirmRelease]

        [UploadToCPAN]

        [Prereqs / DevelopRequires]
        Dist::Zilla::Plugin::ConfirmRelease = 0
        Dist::Zilla::Plugin::ExecDir = 0
        Dist::Zilla::Plugin::ExtraTests = 0
        Dist::Zilla::Plugin::GatherDir = 0
        Dist::Zilla::Plugin::License = 0
        Dist::Zilla::Plugin::MakeMaker = 0
        Dist::Zilla::Plugin::Manifest = 0
        Dist::Zilla::Plugin::ManifestSkip = 0
        Dist::Zilla::Plugin::MetaYAML = 0
        Dist::Zilla::Plugin::Prereqs = 0
        Dist::Zilla::Plugin::PruneCruft = 0
        Dist::Zilla::Plugin::Readme = 0
        Dist::Zilla::Plugin::ShareDir = 0
        Dist::Zilla::Plugin::TestRelease = 0
        Dist::Zilla::Plugin::UploadToCPAN = 0
        Pod::Weaver::Plugin::SingleEncoding = 0
        Pod::Weaver::PluginBundle::CorePrep = 0
        Pod::Weaver::Section::Authors = 0
        Pod::Weaver::Section::Collect = 0
        Pod::Weaver::Section::Generic = 0
        Pod::Weaver::Section::Leftovers = 0
        Pod::Weaver::Section::Legal = 0
        Pod::Weaver::Section::Name = 0
        Pod::Weaver::Section::Region = 0
        Pod::Weaver::Section::Version = 0

        [Prereqs / DevelopSuggests]
        Dist::Iller = @{[ 'Dist::Iller'->VERSION ]}

        [Prereqs / RuntimeRequires]
        CPAN::Uploader = 0
        Moose = 0

        ; authordep CPAN::Uploader = 0
        ; authordep Dist::Zilla::Plugin::ConfirmRelease = 0
        ; authordep Dist::Zilla::Plugin::ExecDir = 0
        ; authordep Dist::Zilla::Plugin::ExtraTests = 0
        ; authordep Dist::Zilla::Plugin::GatherDir = 0
        ; authordep Dist::Zilla::Plugin::License = 0
        ; authordep Dist::Zilla::Plugin::MakeMaker = 0
        ; authordep Dist::Zilla::Plugin::Manifest = 0
        ; authordep Dist::Zilla::Plugin::ManifestSkip = 0
        ; authordep Dist::Zilla::Plugin::MetaYAML = 0
        ; authordep Dist::Zilla::Plugin::Prereqs = 0
        ; authordep Dist::Zilla::Plugin::PruneCruft = 0
        ; authordep Dist::Zilla::Plugin::Readme = 0
        ; authordep Dist::Zilla::Plugin::ShareDir = 0
        ; authordep Dist::Zilla::Plugin::TestRelease = 0
        ; authordep Dist::Zilla::Plugin::UploadToCPAN = 0
        ; authordep Moose = 0
        ; authordep Pod::Weaver::Plugin::SingleEncoding = 0
        ; authordep Pod::Weaver::PluginBundle::CorePrep = 0
        ; authordep Pod::Weaver::Section::Authors = 0
        ; authordep Pod::Weaver::Section::Collect = 0
        ; authordep Pod::Weaver::Section::Generic = 0
        ; authordep Pod::Weaver::Section::Leftovers = 0
        ; authordep Pod::Weaver::Section::Legal = 0
        ; authordep Pod::Weaver::Section::Name = 0
        ; authordep Pod::Weaver::Section::Region = 0
        ; authordep Pod::Weaver::Section::Version = 0
    };
}

sub weaver {
    return qs{
        ; This file was auto-generated from iller.yaml by Dist::Iller on

        [@CorePrep]

        [-SingleEncoding]

        [Name]

        [Version]

        [Region / prelude]

        [Generic / Synopsis]

        [Generic / Description]

        [Generic / Overview]

        [Collect / Attributes]
        command = attr
        header = ATTRIBUTES

        [Collect / Methods]
        command = method
        header = METHODS

        [Collect / Functions]
        command = func
        header = FUNCTIONS

        [Leftovers]

        [Region / postlude]

        [Authors]

        [Legal]
    };
}
