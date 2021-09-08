use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "find poetry in the least poetic places",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => [],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "Lingua-Poetry-Haiku-Finder",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                            runtime   => {
                                           requires => {
                                             "Lingua::EN::Numbers" => 0,
                                             "Lingua::EN::Syllable" => 0,
                                             "Lingua::Sentence" => 0,
                                             "List::Util" => 1.26,
                                             "Moo" => "2.000000",
                                             "namespace::autoclean" => 0,
                                             "perl" => 5.012,
                                             "Types::Standard" => "1.010000",
                                           },
                                         },
                            test      => { requires => { "Test::More" => 0.96 } },
                          },
  "provides"           => {
                            "Lingua::Poetry::Haiku::Finder"               => { file => "lib/Lingua/Poetry/Haiku/Finder.pm", version => 0.002 },
                            "Lingua::Poetry::Haiku::Finder::NonWord"      => {
                                                                               file => "lib/Lingua/Poetry/Haiku/Finder/NonWord.pm",
                                                                               version => 0.002,
                                                                             },
                            "Lingua::Poetry::Haiku::Finder::Sentence"     => {
                                                                               file => "lib/Lingua/Poetry/Haiku/Finder/Sentence.pm",
                                                                               version => 0.002,
                                                                             },
                            "Lingua::Poetry::Haiku::Finder::SentencePart" => {
                                                                               file => "lib/Lingua/Poetry/Haiku/Finder/SentencePart.pm",
                                                                               version => 0.002,
                                                                             },
                            "Lingua::Poetry::Haiku::Finder::Word"         => { file => "lib/Lingua/Poetry/Haiku/Finder/Word.pm", version => 0.002 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => {
                                              web => "https://github.com/tobyink/p5-lingua-poetry-haiku-finder/issues",
                                            },
                            homepage     => "https://metacpan.org/release/Lingua-Poetry-Haiku-Finder",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-lingua-poetry-haiku-finder.git",
                                              web  => "https://github.com/tobyink/p5-lingua-poetry-haiku-finder",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/Lingua-Poetry-Haiku-Finder/project",
                          },
  "version"            => 0.002,
  "x_provides_scripts" => { "haiku-find" => { file => "bin/haiku-find" } },
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

