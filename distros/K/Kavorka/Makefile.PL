use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "function signatures with the lure of the animal",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Kavorka",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { suggests => { "Data::Alias" => 0, "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       recommends => { "Type::Tiny::XS" => "0.010" },
                                       requires   => {
                                                       "Exporter::Tiny"   => 0.026,
                                                       "match::simple"    => 0,
                                                       "Module::Runtime"  => 0,
                                                       "Moo"              => 1.003001,
                                                       "namespace::sweep" => 0.006,
                                                       "PadWalker"        => 0,
                                                       "Parse::Keyword"   => 0.06,
                                                       "perl"             => 5.014,
                                                       "Return::Type"     => 0.004,
                                                       "Sub::Util"        => 0,
                                                       "Type::Parser"     => 0.032,
                                                       "Type::Registry"   => 0.032,
                                                       "Type::Utils"      => 0.032,
                                                       "Types::Standard"  => 0.032,
                                                     },
                                     },
                        test      => {
                                       recommends => {
                                                       "Class::Method::Modifiers" => 2.03,
                                                       "Class::Tiny" => 0,
                                                       "Moose" => "2.0000",
                                                       "Mouse" => "1.00",
                                                       "Role::Tiny" => "1.003000",
                                                     },
                                       requires   => { "Test::Fatal" => 0, "Test::More" => 0.96, "Test::Requires" => 0 },
                                     },
                      },
  "provides"       => {
                        "Kavorka"                                   => { file => "lib/Kavorka.pm", version => 0.038 },
                        "Kavorka::MethodModifier"                   => { file => "lib/Kavorka/MethodModifier.pm", version => 0.038 },
                        "Kavorka::Multi"                            => { file => "lib/Kavorka/Multi.pm", version => 0.038 },
                        "Kavorka::Parameter"                        => { file => "lib/Kavorka/Parameter.pm", version => 0.038 },
                        "Kavorka::ReturnType"                       => { file => "lib/Kavorka/ReturnType.pm", version => 0.038 },
                        "Kavorka::Signature"                        => { file => "lib/Kavorka/Signature.pm", version => 0.038 },
                        "Kavorka::Sub"                              => { file => "lib/Kavorka/Sub.pm", version => 0.038 },
                        "Kavorka::Sub::After"                       => { file => "lib/Kavorka/Sub/After.pm", version => 0.038 },
                        "Kavorka::Sub::Around"                      => { file => "lib/Kavorka/Sub/Around.pm", version => 0.038 },
                        "Kavorka::Sub::Augment"                     => { file => "lib/Kavorka/Sub/Augment.pm", version => 0.038 },
                        "Kavorka::Sub::Before"                      => { file => "lib/Kavorka/Sub/Before.pm", version => 0.038 },
                        "Kavorka::Sub::ClassMethod"                 => { file => "lib/Kavorka/Sub/ClassMethod.pm", version => 0.038 },
                        "Kavorka::Sub::Fun"                         => { file => "lib/Kavorka/Sub/Fun.pm", version => 0.038 },
                        "Kavorka::Sub::Method"                      => { file => "lib/Kavorka/Sub/Method.pm", version => 0.038 },
                        "Kavorka::Sub::ObjectMethod"                => { file => "lib/Kavorka/Sub/ObjectMethod.pm", version => 0.038 },
                        "Kavorka::Sub::Override"                    => { file => "lib/Kavorka/Sub/Override.pm", version => 0.038 },
                        "Kavorka::TraitFor::Parameter::alias"       => { file => "lib/Kavorka/TraitFor/Parameter/alias.pm", version => 0.038 },
                        "Kavorka::TraitFor::Parameter::assumed"     => {
                                                                         file => "lib/Kavorka/TraitFor/Parameter/assumed.pm",
                                                                         version => 0.038,
                                                                       },
                        "Kavorka::TraitFor::Parameter::locked"      => {
                                                                         file => "lib/Kavorka/TraitFor/Parameter/locked.pm",
                                                                         version => 0.038,
                                                                       },
                        "Kavorka::TraitFor::Parameter::optional"    => {
                                                                         file => "lib/Kavorka/TraitFor/Parameter/optional.pm",
                                                                         version => 0.038,
                                                                       },
                        "Kavorka::TraitFor::Parameter::ref_alias"   => {
                                                                         file => "lib/Kavorka/TraitFor/Parameter/ref_alias.pm",
                                                                         version => 0.038,
                                                                       },
                        "Kavorka::TraitFor::Parameter::ro"          => { file => "lib/Kavorka/TraitFor/Parameter/ro.pm", version => 0.038 },
                        "Kavorka::TraitFor::ReturnType::assumed"    => {
                                                                         file => "lib/Kavorka/TraitFor/ReturnType/assumed.pm",
                                                                         version => 0.038,
                                                                       },
                        "Kavorka::TraitFor::Sub::begin"             => { file => "lib/Kavorka/TraitFor/Sub/begin.pm", version => 0.038 },
                        "Kavorka::TraitFor::Sub::fresh"             => { file => "lib/Kavorka/TraitFor/Sub/fresh.pm", version => 0.038 },
                        "Kavorka::TraitFor::Sub::override"          => { file => "lib/Kavorka/TraitFor/Sub/override.pm", version => 0.038 },
                        "MooseX::KavorkaInfo"                       => { file => "lib/MooseX/KavorkaInfo.pm", version => 0.038 },
                        "MooseX::KavorkaInfo::DummyInfo"            => { file => "lib/MooseX/KavorkaInfo.pm" },
                        "MooseX::KavorkaInfo::Trait::Method"        => { file => "lib/MooseX/KavorkaInfo.pm", version => 0.038 },
                        "MooseX::KavorkaInfo::Trait::WrappedMethod" => { file => "lib/MooseX/KavorkaInfo.pm", version => 0.038 },
                        "Parse::KeywordX"                           => { file => "lib/Parse/KeywordX.pm", version => 0.038 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Kavorka" },
                        homepage     => "https://metacpan.org/release/Kavorka",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-kavorka.git",
                                          web  => "https://github.com/tobyink/p5-kavorka",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Kavorka/project",
                        x_IRC        => "irc://irc.perl.org/#moops",
                      },
  "version"        => 0.038,
  "x_contributors" => [
                        "Grzegorz Ro\x{17C}niecki (XAERXESS) <xaerxess\@cpan.org>",
                        "Aaron James Trevena (TEEJAY) <teejay\@cpan.org>",
                        "Piers Cawley (PDCAWLEY) <pdcawley\@cpan.org>",
                        "Thibaut Le Page (THILP) <thilp\@cpan.org>",
                        "Chris Tijerina (CAMSPI) <camspi\@cpan.org>",
                        "Daniel Dehennin",
                      ],
};

my %dynamic_config;
do {
#
# Perl 5.22 introduces experimental reference aliasing.
# Data::Alias is totally broken in 5.24.
#
$meta->{prereqs}{runtime}{requires}{'Data::Alias'} = '1.16'
	if $] < 5.022;

};

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

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}

my $mm = WriteMakefile(%WriteMakefileArgs);
FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
exit(0);

