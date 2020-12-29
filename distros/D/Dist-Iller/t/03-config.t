use strict;
use Test::More;
use Test::Differences;
use Path::Tiny;
use File::chdir;
use Dist::Iller;
use syntax 'qi';

use lib 't/corpus/lib';
use Dist::Iller::Config::DistIllerTestConfig;

my $iller = Dist::Iller->new(filepath => 't/corpus/03-config-iller.yaml');
$iller->parse('first');
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

my $generated_dist_ini = $tempdir->child('dist.ini')->slurp_utf8;
my $generated_weaver_ini = $tempdir->child('weaver.ini')->slurp_utf8;
my $generated_cpanfile = $tempdir->child('cpanfile')->slurp_utf8;
my $generated_gitignore = $tempdir->child('.gitignore')->slurp;

my $spaces = qr/[\s\n\r]*/;
my $equals = qr/$spaces = $spaces/x;

like $generated_dist_ini, qr/PlacedBeforeExtraTests\]$spaces\[ExtraTests/x, '[PlacedBeforeExtraTests] inserted correctly';
like $generated_dist_ini, qr/ExecDir\]$spaces dir $equals bin/x, '[ExecDir]/bin changed and [PlacedAfter::ExecDir] inserted correctly';
unlike $generated_dist_ini, qr/\[License\]/, 'License removed';
like $generated_dist_ini, qr/\[LicenseImproved\] $spaces license $equals perl_5 $spaces \[Readme\]/x, '[LicenseImproved] inserted correctly';
like $generated_dist_ini, qr/\[Readme\] $spaces
                              headings $equals head1 $spaces
                              headings $equals head2 $spaces
                              more_root $equals no $spaces
                              suffix $equals md $spaces \[/x, '[Readme] changed correctly';
like $generated_dist_ini, qr/\[ExecDir\]$spaces dir $equals bin $spaces \[PlacedAfter::ExecDir\]/x, '[PlacedAfter::ExecDir] inserted correctly';
like $generated_dist_ini, qr/\[LastPlugin\] $spaces \[Prereqs /x, '[LastPlugin] is the last plugin';
like $generated_dist_ini, qr{\[Prereqs / DevelopSuggests\][\n\r\s]*Dist::Iller}, 'Dist::Iller only suggested';

like $generated_dist_ini, qr{Cruft::Pruner = 0}, 'Added prereq from plugin';
like $generated_dist_ini, qr/Another::Crufter = 1.2/, 'Added suggests prereq from plugin';
like $generated_dist_ini, qr/authordep Pod::Weaver::Section::Authors = 0\.001/, 'Used default prereq version';
like $generated_dist_ini, qr/Moose = 2.1400/, 'Wants correct Moose';
unlike $generated_dist_ini, qr/Moo = 2/, 'Moo not added';

eq_or_diff clean_ini($generated_weaver_ini), clean_ini(weaver()), 'Correct weaver.ini';

like $generated_cpanfile, qr/This::Thing/, 'cpanfile, prereq from config';
like $generated_cpanfile, qr/Another::Thing/, 'cpanfile, prereq from local iller.yaml';
like $generated_cpanfile, qr/ExtUtils::MakeMaker/, 'cpanfile, configure requires';
like $generated_cpanfile, qr/suggests 'Another::Crufter' => '1.2'/, 'cpanfile, added prereq from plugin';

like $generated_gitignore, qr/MYMETA/, 'gitignore: MYMETA.* is ignored';
like $generated_gitignore, qr/ThisFile/, 'gitignore: Ignores file added in config' or diag explain $generated_gitignore;
like $generated_gitignore, qr{/My-Own-Dist-*}, 'gitignore: Ignores built distribution dir, added by $self.distribution_name' or diag explain $generated_gitignore;
unlike $generated_gitignore, qr/inc/, 'gitignore: inc is not ignored, since it does not exist';

done_testing;

sub clean_ini {
    my $string = shift;
    $string =~ s{^(\s*?;.* on).*}{$1...};
    return clean($string);
}
sub clean_cpanfile {
    my $string = shift;
    $string =~ s{^(\s*?#.* on).*}{$1...};
    return clean($string);
}
sub clean {
    my $string = shift;
    $string =~ s{^\v}{};
    $string =~ s{^(\s*?;.* on).*}{$1...};
    return $string;
}

sub dist {
    return qqi{
        ; This file was auto-generated from iller.yaml by Dist::Iller on...
        ; The following configs were used:
        ; * Dist::Iller::Config::DistIllerTestConfig: 0.0001

        name = My-Own-Dist
        author = Erik Carlsson
        author = Ex Ample

        [GatherDir]

        [PruneCruft]

        [ManifestSkip]

        [TaskWeaver]

        [GithubMeta]
        homepage = https://metacpan.org/release/My-Own-Dist
        issues = 1

        [MetaYAML]

        [LicenseImproved]
        license = perl_5

        [Readme]
        headings = head1
        headings = head2
        more_root = no
        suffix = md

        [PlacedBeforeExtraTests]

        [ExtraTests]

        [ExecDir]
        dir = bin

        [PlacedAfter::ExecDir]

        [ShareDir]

        [MakeMaker]

        [Manifest]

        [TestRelease]

        [ConfirmRelease]
        default = @{[ '$self.confirm_release' ]}
        prompt = \$

        [UploadToCPAN]

        [LastPlugin]

        [Prereqs / DevelopRequires]
        Another::Thing = 0
        Dist::Iller = @{[ 'Dist::Iller'->VERSION ]}
        Dist::Iller::Config::DistIllerTestConfig = @{[ 'Dist::Iller::Config::DistIllerTestConfig'->VERSION ]}
        Dist::Zilla::Plugin::ConfirmRelease = 0
        Dist::Zilla::Plugin::ExecDir = 0
        Dist::Zilla::Plugin::ExtraTests = 0
        Dist::Zilla::Plugin::GatherDir = 0
        Dist::Zilla::Plugin::GithubMeta = 0
        Dist::Zilla::Plugin::LastPlugin = 0.02
        Dist::Zilla::Plugin::LicenseImproved = 0
        Dist::Zilla::Plugin::MakeMaker = 0
        Dist::Zilla::Plugin::Manifest = 0
        Dist::Zilla::Plugin::ManifestSkip = 0
        Dist::Zilla::Plugin::MetaYAML = 0
        Dist::Zilla::Plugin::PlacedAfter::ExecDir = 0
        Dist::Zilla::Plugin::PlacedBeforeExtraTests = 0
        Dist::Zilla::Plugin::PruneCruft = 0
        Dist::Zilla::Plugin::Readme = 0.01
        Dist::Zilla::Plugin::ShareDir = 0
        Dist::Zilla::Plugin::TaskWeaver = 0
        Dist::Zilla::Plugin::TestRelease = 0
        Dist::Zilla::Plugin::UploadToCPAN = 0
        Pod::Elemental::Transformer::List = 0.03
        Pod::Weaver::Plugin::SingleEncoding = 0
        Pod::Weaver::Plugin::Transformer = 0
        Pod::Weaver::PluginBundle::CorePrep = 0
        Pod::Weaver::Section::Authors = 0
        Pod::Weaver::Section::Collect = 0
        Pod::Weaver::Section::Generic = 0
        Pod::Weaver::Section::Leftovers = 0
        Pod::Weaver::Section::Legal = 0
        Pod::Weaver::Section::Name = 0
        Pod::Weaver::Section::Region = 0
        Pod::Weaver::Section::Version = 0
        This::Thing = 0

        [Prereqs / DevelopSuggests]
        Dist::Iller = @{[ 'Dist::Iller'->VERSION ]}
        Dist::Iller::Config::DistIllerTestConfig = @{[ 'Dist::Iller::Config::DistIllerTestConfig'->VERSION ]}

        [Prereqs / RuntimeRequires]
        Moose = 2.1400

        ; authordep Another::Thing = 0
        ; authordep Dist::Zilla::Plugin::ConfirmRelease = 0
        ; authordep Dist::Zilla::Plugin::ExecDir = 0
        ; authordep Dist::Zilla::Plugin::ExtraTests = 0
        ; authordep Dist::Zilla::Plugin::GatherDir = 0
        ; authordep Dist::Zilla::Plugin::GithubMeta = 0
        ; authordep Dist::Zilla::Plugin::LastPlugin = 0.02
        ; authordep Dist::Zilla::Plugin::LicenseImproved = 0
        ; authordep Dist::Zilla::Plugin::MakeMaker = 0
        ; authordep Dist::Zilla::Plugin::Manifest = 0
        ; authordep Dist::Zilla::Plugin::ManifestSkip = 0
        ; authordep Dist::Zilla::Plugin::MetaYAML = 0
        ; authordep Dist::Zilla::Plugin::PlacedAfter::ExecDir = 0
        ; authordep Dist::Zilla::Plugin::PlacedBeforeExtraTests = 0
        ; authordep Dist::Zilla::Plugin::PruneCruft = 0
        ; authordep Dist::Zilla::Plugin::Readme = 0.01
        ; authordep Dist::Zilla::Plugin::ShareDir = 0
        ; authordep Dist::Zilla::Plugin::TaskWeaver = 0
        ; authordep Dist::Zilla::Plugin::TestRelease = 0
        ; authordep Dist::Zilla::Plugin::UploadToCPAN = 0
        ; authordep Pod::Elemental::Transformer::List = 0.03
        ; authordep Pod::Weaver::Plugin::SingleEncoding = 0
        ; authordep Pod::Weaver::Plugin::Transformer = 0
        ; authordep Pod::Weaver::PluginBundle::CorePrep = 0
        ; authordep Pod::Weaver::Section::Authors = 0
        ; authordep Pod::Weaver::Section::Collect = 0
        ; authordep Pod::Weaver::Section::Generic = 0
        ; authordep Pod::Weaver::Section::Leftovers = 0
        ; authordep Pod::Weaver::Section::Legal = 0
        ; authordep Pod::Weaver::Section::Name = 0
        ; authordep Pod::Weaver::Section::Region = 0
        ; authordep Pod::Weaver::Section::Version = 0
        ; authordep This::Thing = 0
        };
}

sub weaver {
    return qi{
        ; This file was auto-generated from iller.yaml by Dist::Iller on...
        ; The following configs were used:
        ; * Dist::Iller::Config::DistIllerTestConfig: 0.0001

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

        [-Transformer / List]
        transformer = List
        };
}

sub cpanfile {
    return qqi{
        # This file was auto-generated from iller.yaml by Dist::Iller on...

        on runtime => sub {
            requires 'Moose' => '2.1400';
        };
        on develop => sub {
            requires 'Another::Thing' => '0';
            requires 'Dist::Iller' => '@{[ "Dist::Iller"->VERSION ]}';
            requires 'Dist::Iller::Config::DistIllerTestConfig' => '0.0001';
            requires 'Dist::Zilla::Plugin::ConfirmRelease' => '0';
            requires 'Dist::Zilla::Plugin::ExecDir' => '0';
            requires 'Dist::Zilla::Plugin::ExtraTests' => '0';
            requires 'Dist::Zilla::Plugin::GatherDir' => '0';
            requires 'Dist::Zilla::Plugin::GithubMeta' => '0';
            requires 'Dist::Zilla::Plugin::LastPlugin' => '0.02';
            requires 'Dist::Zilla::Plugin::LicenseImproved' => '0';
            requires 'Dist::Zilla::Plugin::MakeMaker' => '0';
            requires 'Dist::Zilla::Plugin::Manifest' => '0';
            requires 'Dist::Zilla::Plugin::ManifestSkip' => '0';
            requires 'Dist::Zilla::Plugin::MetaYAML' => '0';
            requires 'Dist::Zilla::Plugin::PlacedAfter::ExecDir' => '0';
            requires 'Dist::Zilla::Plugin::PlacedBeforeExtraTests' => '0';
            requires 'Dist::Zilla::Plugin::PruneCruft' => '0';
            requires 'Dist::Zilla::Plugin::Readme' => '0.01';
            requires 'Dist::Zilla::Plugin::ShareDir' => '0';
            requires 'Dist::Zilla::Plugin::TaskWeaver' => '0';
            requires 'Dist::Zilla::Plugin::TestRelease' => '0';
            requires 'Dist::Zilla::Plugin::UploadToCPAN' => '0';
            requires 'Pod::Elemental::Transformer::List' => '0.03';
            requires 'Pod::Weaver::Plugin::SingleEncoding' => '0';
            requires 'Pod::Weaver::Plugin::Transformer' => '0';
            requires 'Pod::Weaver::PluginBundle::CorePrep' => '0';
            requires 'Pod::Weaver::Section::Authors' => '0';
            requires 'Pod::Weaver::Section::Collect' => '0';
            requires 'Pod::Weaver::Section::Generic' => '0';
            requires 'Pod::Weaver::Section::Leftovers' => '0';
            requires 'Pod::Weaver::Section::Legal' => '0';
            requires 'Pod::Weaver::Section::Name' => '0';
            requires 'Pod::Weaver::Section::Region' => '0';
            requires 'Pod::Weaver::Section::Version' => '0';
            requires 'This::Thing' => '0';
        };
        };
}
