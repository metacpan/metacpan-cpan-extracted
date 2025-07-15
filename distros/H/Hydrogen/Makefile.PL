use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "utilities for the simplest elements of Perl",
  "author"           => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "Hydrogen",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => {
                                         recommends => { "Dist::Inkt" => 0.001 },
                                         requires   => {
                                                         "Mite" => 0,
                                                         "Module::Runtime" => 0,
                                                         "Path::Tiny" => 0,
                                                         "Sub::HandlesVia" => 0.037,
                                                         "Types::Standard" => "2.000000",
                                                       },
                                       },
                          runtime   => {
                                         requires => {
                                           "autobox"         => 0,
                                           "Carp"            => 0,
                                           "Data::Dumper"    => 0,
                                           "Exporter::Shiny" => 1.004001,
                                           "Import::Into"    => 0,
                                           "List::Util"      => 1.54,
                                           "perl"            => 5.008001,
                                           "Scalar::Util"    => 0,
                                         },
                                       },
                          test      => { requires => { "Test2::V0" => 0 } },
                        },
  "provides"         => {
                          "Hydrogen"                  => { file => "lib/Hydrogen.pm", version => "0.021000" },
                          "Hydrogen::Array"           => { file => "lib/Hydrogen/Array.pm", version => "0.021000" },
                          "Hydrogen::ArrayRef"        => { file => "lib/Hydrogen/ArrayRef.pm", version => "0.021000" },
                          "Hydrogen::Autobox"         => { file => "lib/Hydrogen/Autobox.pm", version => "0.021000" },
                          "Hydrogen::Bool"            => { file => "lib/Hydrogen/Bool.pm", version => "0.021000" },
                          "Hydrogen::Code"            => { file => "lib/Hydrogen/Code.pm", version => "0.021000" },
                          "Hydrogen::CodeRef"         => { file => "lib/Hydrogen/CodeRef.pm", version => "0.021000" },
                          "Hydrogen::Counter"         => { file => "lib/Hydrogen/Counter.pm", version => "0.021000" },
                          "Hydrogen::Curry::ArrayRef" => { file => "lib/Hydrogen/Curry/ArrayRef.pm", version => "0.021000" },
                          "Hydrogen::Curry::Bool"     => { file => "lib/Hydrogen/Curry/Bool.pm", version => "0.021000" },
                          "Hydrogen::Curry::CodeRef"  => { file => "lib/Hydrogen/Curry/CodeRef.pm", version => "0.021000" },
                          "Hydrogen::Curry::Counter"  => { file => "lib/Hydrogen/Curry/Counter.pm", version => "0.021000" },
                          "Hydrogen::Curry::HashRef"  => { file => "lib/Hydrogen/Curry/HashRef.pm", version => "0.021000" },
                          "Hydrogen::Curry::Number"   => { file => "lib/Hydrogen/Curry/Number.pm", version => "0.021000" },
                          "Hydrogen::Curry::Scalar"   => { file => "lib/Hydrogen/Curry/Scalar.pm", version => "0.021000" },
                          "Hydrogen::Curry::String"   => { file => "lib/Hydrogen/Curry/String.pm", version => "0.021000" },
                          "Hydrogen::Hash"            => { file => "lib/Hydrogen/Hash.pm", version => "0.021000" },
                          "Hydrogen::HashRef"         => { file => "lib/Hydrogen/HashRef.pm", version => "0.021000" },
                          "Hydrogen::Number"          => { file => "lib/Hydrogen/Number.pm", version => "0.021000" },
                          "Hydrogen::Scalar"          => { file => "lib/Hydrogen/Scalar.pm", version => "0.021000" },
                          "Hydrogen::String"          => { file => "lib/Hydrogen/String.pm", version => "0.021000" },
                          "Hydrogen::Topic::ArrayRef" => { file => "lib/Hydrogen/Topic/ArrayRef.pm", version => "0.021000" },
                          "Hydrogen::Topic::Bool"     => { file => "lib/Hydrogen/Topic/Bool.pm", version => "0.021000" },
                          "Hydrogen::Topic::CodeRef"  => { file => "lib/Hydrogen/Topic/CodeRef.pm", version => "0.021000" },
                          "Hydrogen::Topic::Counter"  => { file => "lib/Hydrogen/Topic/Counter.pm", version => "0.021000" },
                          "Hydrogen::Topic::HashRef"  => { file => "lib/Hydrogen/Topic/HashRef.pm", version => "0.021000" },
                          "Hydrogen::Topic::Number"   => { file => "lib/Hydrogen/Topic/Number.pm", version => "0.021000" },
                          "Hydrogen::Topic::Scalar"   => { file => "lib/Hydrogen/Topic/Scalar.pm", version => "0.021000" },
                          "Hydrogen::Topic::String"   => { file => "lib/Hydrogen/Topic/String.pm", version => "0.021000" },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => { web => "https://github.com/tobyink/p5-hydrogen/issues" },
                          homepage     => "https://metacpan.org/release/Hydrogen",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/tobyink/p5-hydrogen.git",
                                            web  => "https://github.com/tobyink/p5-hydrogen",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/Hydrogen/project",
                        },
  "version"          => "0.021000",
  "x_static_install" => 1,
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/integration/*.t t/unit/Hydrogen/*.t t/unit/Hydrogen/Curry/*.t t/unit/Hydrogen/Topic/*.t" },
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

