use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "yet another distribution builder",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => ["CPAN", "Distribution", "Package", "Perl", "Release"],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "Dist-Inkt",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            runtime => {
                              requires => {
                                "CPAN::Changes"            => 0,
                                "CPAN::Meta"               => 0,
                                "CPAN::Meta::Requirements" => 0,
                                "Data::Dump"               => 0,
                                "File::chdir"              => 0,
                                "List::MoreUtils"          => 0,
                                "Module::CPANfile"         => 1.0002,
                                "Module::Metadata"         => 0,
                                "Module::Runtime"          => 0,
                                "Module::Signature"        => 0,
                                "Moose"                    => "2.0800",
                                "namespace::autoclean"     => 0,
                                "Path::FindDev"            => 0,
                                "Path::Iterator::Rule"     => 0,
                                "Path::Tiny"               => 0,
                                "perl"                     => 5.010001,
                                "RDF::DOAP::Lite"          => 0,
                                "Software::License"        => 0,
                                "Types::Path::Tiny"        => 0,
                                "Types::Standard"          => 0,
                              },
                            },
                            test => { requires => { "Test::More" => 0.96 } },
                          },
  "provides"           => {
                            "Dist::Inkt"                              => { file => "lib/Dist/Inkt.pm", version => 0.026 },
                            "Dist::Inkt::Profile::Simple"             => { file => "lib/Dist/Inkt/Profile/Simple.pm", version => 0.026 },
                            "Dist::Inkt::Role::CopyFiles"             => { file => "lib/Dist/Inkt/Role/CopyFiles.pm", version => 0.026 },
                            "Dist::Inkt::Role::CopyStandardDocuments" => {
                                                                           file => "lib/Dist/Inkt/Role/CopyStandardDocuments.pm",
                                                                           version => 0.026,
                                                                         },
                            "Dist::Inkt::Role::CPANfile"              => { file => "lib/Dist/Inkt/Role/CPANfile.pm", version => 0.026 },
                            "Dist::Inkt::Role::MetaProvides"          => { file => "lib/Dist/Inkt/Role/MetaProvides.pm", version => 0.026 },
                            "Dist::Inkt::Role::MetaProvidesScripts"   => {
                                                                           file => "lib/Dist/Inkt/Role/MetaProvidesScripts.pm",
                                                                           version => 0.026,
                                                                         },
                            "Dist::Inkt::Role::SignDistribution"      => { file => "lib/Dist/Inkt/Role/SignDistribution.pm", version => 0.026 },
                            "Dist::Inkt::Role::StaticInstall"         => { file => "lib/Dist/Inkt/Role/StaticInstall.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteDOAPLite"         => { file => "lib/Dist/Inkt/Role/WriteDOAPLite.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteINSTALL"          => { file => "lib/Dist/Inkt/Role/WriteINSTALL.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteLICENSE"          => { file => "lib/Dist/Inkt/Role/WriteLICENSE.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteMakefilePL"       => { file => "lib/Dist/Inkt/Role/WriteMakefilePL.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteMetaJSON"         => { file => "lib/Dist/Inkt/Role/WriteMetaJSON.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteMetaYML"          => { file => "lib/Dist/Inkt/Role/WriteMetaYML.pm", version => 0.026 },
                            "Dist::Inkt::Role::WriteREADME"           => { file => "lib/Dist/Inkt/Role/WriteREADME.pm", version => 0.026 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt" },
                            homepage     => "https://metacpan.org/release/Dist-Inkt",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-dist-inkt.git",
                                              web  => "https://github.com/tobyink/p5-dist-inkt",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/Dist-Inkt/project",
                            x_wiki       => "https://github.com/tobyink/p5-dist-inkt/wiki",
                          },
  "version"            => 0.026,
  "x_help_wanted"      => ["tester", "documenter"],
  "x_provides_scripts" => {
                            "distinkt-dist"      => { file => "script/distinkt-dist" },
                            "distinkt-travisyml" => { file => "script/distinkt-travisyml" },
                          },
  "x_static_install"   => 1,
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t" },
	%dynamic_config,
);

$WriteMakefileArgs{LICENSE} = $meta->{license}[0] if $EUMM >= 6.3001;

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			next if $dep eq 'perl';
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ($EUMM >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ($EUMM >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my ($minperl) = reverse sort(
		grep defined && /^[0-9]+(\.[0-9]+)?$/,
		map $meta->{prereqs}{$_}{requires}{perl},
		qw( configure build runtime )
	);
	
	if (defined($minperl))
	{
		die "Installing $meta->{name} requires Perl >= $minperl"
			unless $] >= $minperl;
		
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl
			if $EUMM >= 6.48;
	}
}


my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);

