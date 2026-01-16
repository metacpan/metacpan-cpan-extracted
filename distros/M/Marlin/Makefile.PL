use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "\x{1F41F} pretty fast class builder with most Moo/Moose features \x{1F41F}",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Marlin",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       requires => {
                                         "B::Hooks::AtRuntime" => 0,
                                         "Class::Method::Modifiers" => 0,
                                         "Class::XSAccessor" => 1.19,
                                         "Class::XSConstructor" => "0.021000",
                                         "Clone" => 0,
                                         "Exporter::Tiny" => 1.006002,
                                         "List::Util" => 1.45,
                                         "LV" => 0,
                                         "perl" => 5.008008,
                                         "Role::Tiny" => 0,
                                         "Sub::Accessor::Small" => 1.000003,
                                         "Sub::HandlesVia" => "0.052000",
                                         "Type::Tiny" => "2.010000",
                                         "Type::Tiny::XS" => 0,
                                       },
                                     },
                        test      => {
                                       recommends => { Moo => 0, Moose => 0 },
                                       requires   => {
                                                       "Test2::Plugin::BailOnFail"     => 0,
                                                       "Test2::Require::AuthorTesting" => 0,
                                                       "Test2::Require::Module"        => 0,
                                                       "Test2::Tools::Spec"            => 0,
                                                       "Test2::V0"                     => 0,
                                                     },
                                     },
                      },
  "provides"       => {
                        "Marlin"                          => { file => "lib/Marlin.pm", version => "0.015000" },
                        "Marlin::Attribute"               => { file => "lib/Marlin/Attribute.pm", version => "0.015000" },
                        "Marlin::Meta::Class"             => { file => "lib/MooseX/Marlin.pm" },
                        "Marlin::Role"                    => { file => "lib/Marlin/Role.pm", version => "0.015000" },
                        "Marlin::Struct"                  => { file => "lib/Marlin/Struct.pm", version => "0.015000" },
                        "Marlin::TypeConstraint"          => { file => "lib/Marlin/TypeConstraint.pm", version => "0.015000" },
                        "Marlin::Util"                    => { file => "lib/Marlin/Util.pm", version => "0.015000" },
                        "Marlin::X"                       => { file => "lib/Marlin/X.pm", version => "0.015000" },
                        "Marlin::X::Clone"                => { file => "lib/Marlin/X/Clone.pm", version => "0.015000" },
                        "Marlin::X::UndefTolerant"        => { file => "lib/Marlin/X/UndefTolerant.pm", version => "0.015000" },
                        "Marlin::XAttribute::Alias"       => { file => "lib/Marlin/XAttribute/Alias.pm", version => "0.015000" },
                        "Marlin::XAttribute::LocalWriter" => {
                                                               file => "lib/Marlin/XAttribute/LocalWriter.pm",
                                                               version => "0.015000",
                                                             },
                        "Marlin::XAttribute::Lvalue"      => { file => "lib/Marlin/XAttribute/Lvalue.pm", version => "0.015000" },
                        "MooseX::Marlin"                  => { file => "lib/MooseX/Marlin.pm", version => "0.015000" },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://github.com/tobyink/p5-marlin/issues" },
                        homepage     => "https://metacpan.org/release/Marlin",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-marlin.git",
                                          web  => "https://github.com/tobyink/p5-marlin",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Marlin/project",
                      },
  "version"        => "0.015000",
};

my %dynamic_config;
do {
	if ( "$]" >= 5.011002 and "$]" < 5.037002 ) {
		$meta->{prereqs}{runtime}{'requires'}{'Lexical::Var'} = '0.010';
	}
	
	if ( "$]" < 5.010000 ) {
		$meta->{prereqs}{runtime}{'requires'}{'MRO::Compat'} = 0;
	}

};

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/integration/*.t" },
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

