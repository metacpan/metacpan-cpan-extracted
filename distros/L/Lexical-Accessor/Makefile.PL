use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "true private attributes for Moose/Moo/Mouse",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Lexical-Accessor",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       recommends => {
                                                       "Hash::FieldHash" => 0,
                                                       "Sub::HandlesVia" => 0.025,
                                                       "Sub::Util"       => "1.40",
                                                       "Type::Utils"     => 0.026,
                                                     },
                                       requires   => { "Eval::TypeTiny" => 0, "Exporter::Tiny" => 0, "perl" => 5.008003 },
                                       suggests   => { "Sub::Name" => 0 },
                                     },
                        test      => {
                                       recommends => {
                                                       "Class::Tiny" => 0.006,
                                                       "Moo" => "1.000000",
                                                       "Moose" => "2.0000",
                                                       "Mouse" => "1.00",
                                                     },
                                       requires   => {
                                                       "Test::Fatal"     => 0,
                                                       "Test::More"      => 0.96,
                                                       "Test::Requires"  => 0,
                                                       "Types::Standard" => 0.004,
                                                     },
                                     },
                      },
  "provides"       => {
                        "Lexical::Accessor" => { file => "lib/Lexical/Accessor.pm", version => 1.000003 },
                        "Sub::Accessor::Small" => { file => "lib/Sub/Accessor/Small.pm", version => 1.000003 },
                        "Sub::HandlesVia::Toolkit::SubAccessorSmall" => {
                          file => "lib/Sub/HandlesVia/Toolkit/SubAccessorSmall.pm",
                          version => 1.000003,
                        },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://github.com/tobyink/p5-lexical-accessor/issues" },
                        homepage     => "https://metacpan.org/release/Lexical-Accessor",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-lexical-accessor.git",
                                          web  => "https://github.com/tobyink/p5-lexical-accessor",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Lexical-Accessor/project",
                      },
  "version"        => 1.000003,
  "x_contributors" => ["Lukas Atkinson (AMON) <amon\@cpan.org>"],
};

my %dynamic_config;
do {
if ($] < 5.010000) {
	$meta->{prereqs}{runtime}{requires}{'Hash::Util::FieldHash::Compat'} = 0;
}

if (eval { require Sub::HandlesVia; 1 }) {
	$meta->{prereqs}{runtime}{requires}{'Sub::HandlesVia'} = '0.025';
}

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


my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);

