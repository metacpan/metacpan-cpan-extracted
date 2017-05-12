use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "transform JSON using JsonT",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.023, CPAN::Meta::Converter version 2.140640",
  "keywords"       => ["ECMAScript", "JSON", "JavaScript", "JsonT", "Transform"],
  "license"        => ["lgpl_2_1"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "JSON-T",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        runtime   => {
                                       recommends => { "Cpanel::JSON::XS" => 0, "JE" => 0 },
                                       requires   => { "Module::Runtime" => 0, "perl" => "5.010000" },
                                       suggests   => { "JavaScript::SpiderMonkey" => 0, "JSON::PP" => 0 },
                                     },
                      },
  "provides"       => {
                        "JSON::T" => { file => "lib/JSON/T.pm", version => 0.104 },
                        "JSON::T::JE" => { file => "lib/JSON/T/JE.pm", version => 0.104 },
                        "JSON::T::SpiderMonkey" => { file => "lib/JSON/T/SpiderMonkey.pm", version => 0.104 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=JSON-T" },
                        homepage     => "https://metacpan.org/release/JSON-T",
                        license      => ["http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-json-t.git",
                                          web  => "https://github.com/tobyink/p5-json-t",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/JSON-T/project",
                      },
  "version"        => 0.104,
  "x_contributors" => ["Stefan Goessner"],
};

my %dynamic_config;
do {
if (eval { require JavaScript::SpiderMonkey })
{
	print "You have JavaScript::SpiderMonkey... awesome!\n";
}
else
{
	print "You are missing JavaScript::SpiderMonkey... but fear not!\n";
	print "We'll add a pure Perl Javascript implementation (JE) to your deps.\n";
	
	$meta->{prereqs}{runtime}{requires}{'JE'} = 0;
}

if (eval { require Cpanel::JSON::XS })
{
	print "You have Cpanel::JSON::XS... awesome!\n";
}
else
{
	print "You are missing Cpanel::JSON::XS... but fear not!\n";
	print "We'll add a pure Perl JSON implementation (JSON::PP) to your deps.\n";
	
	$meta->{prereqs}{runtime}{requires}{'JSON::PP'} = 0;
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

