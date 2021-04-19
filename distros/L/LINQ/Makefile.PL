use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "an interpretation of Microsoft's Language Integrated Query",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "LINQ",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { suggests => { "Dist::Inkt::Profile::TOBYINK" => 0 } },
                        runtime   => {
                                       requires => {
                                         "Class::Tiny"     => 0.005,
                                         "Exporter::Shiny" => 0,
                                         "List::Util"      => 1.35,
                                         "match::simple"   => 0,
                                         "Object::Adhoc"   => 0,
                                         "parent"          => 0.224,
                                         "perl"            => 5.008003,
                                         "Role::Tiny"      => 1.003003,
                                         "Scalar::Util"    => 0,
                                       },
                                     },
                        test      => {
                                       recommends => { "Type::Nano" => 0, "Types::Standard" => 0 },
                                       requires   => { "Test::Modern" => 0.008 },
                                       suggests   => { "MooseX::Types" => 0, "Specio" => 0 },
                                     },
                      },
  "provides"       => {
                        "LINQ"                                   => { file => "lib/LINQ.pm", version => 0.002 },
                        "LINQ::Array"                            => { file => "lib/LINQ/Array.pm", version => 0.002 },
                        "LINQ::Collection"                       => { file => "lib/LINQ/Collection.pm", version => 0.002 },
                        "LINQ::END"                              => { file => "lib/LINQ.pm", version => 0.002 },
                        "LINQ::Exception"                        => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::CallerError"           => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::Cast"                  => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::CollectionError"       => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::InternalError"         => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::MultipleFound"         => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::NotFound"              => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Exception::Unimplemented"         => { file => "lib/LINQ/Exception.pm", version => 0.002 },
                        "LINQ::Field"                            => { file => "lib/LINQ/Field.pm", version => 0.002 },
                        "LINQ::FieldSet"                         => { file => "lib/LINQ/FieldSet.pm", version => 0.002 },
                        "LINQ::FieldSet::Assertion"              => { file => "lib/LINQ/FieldSet/Assertion.pm", version => 0.002 },
                        "LINQ::FieldSet::Assertion::AND"         => { file => "lib/LINQ/FieldSet/Assertion.pm", version => 0.002 },
                        "LINQ::FieldSet::Assertion::Combination" => { file => "lib/LINQ/FieldSet/Assertion.pm", version => 0.002 },
                        "LINQ::FieldSet::Assertion::NOT"         => { file => "lib/LINQ/FieldSet/Assertion.pm", version => 0.002 },
                        "LINQ::FieldSet::Assertion::OR"          => { file => "lib/LINQ/FieldSet/Assertion.pm", version => 0.002 },
                        "LINQ::FieldSet::Selection"              => { file => "lib/LINQ/FieldSet/Selection.pm", version => 0.002 },
                        "LINQ::FieldSet::Single"                 => { file => "lib/LINQ/FieldSet/Single.pm", version => 0.002 },
                        "LINQ::Grouping"                         => { file => "lib/LINQ/Grouping.pm", version => 0.002 },
                        "LINQ::Iterator"                         => { file => "lib/LINQ/Iterator.pm", version => 0.002 },
                        "LINQ::LAST"                             => { file => "lib/LINQ.pm", version => 0.002 },
                        "LINQ::Util"                             => { file => "lib/LINQ/Util.pm", version => 0.002 },
                        "LINQ::Util::Internal"                   => { file => "lib/LINQ/Util/Internal.pm", version => 0.002 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://github.com/tobyink/p5-linq/issues" },
                        homepage     => "https://metacpan.org/release/LINQ",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-linq.git",
                                          web  => "https://github.com/tobyink/p5-linq",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/LINQ/project",
                      },
  "version"        => 0.002,
};

my %dynamic_config;
do {
$meta->{prereqs}{runtime}{requires}{'UNIVERSAL::DOES'} = 0 if $] < 5.010000;

};

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/docs/*.t" },
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

