use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "parse HTML reliably",
  "author"             => ["Toby Inkster <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"           => ["HTML", "HTML5", "Web"],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "HTML-HTML5-Parser",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                            runtime   => {
                                           requires => {
                                             "HTML::HTML5::Entities" => 0.002,
                                             "HTTP::Tiny"            => 0,
                                             "IO::HTML"              => 0,
                                             "perl"                  => 5.008001,
                                             "Scalar::Util"          => 0,
                                             "Try::Tiny"             => 0,
                                             "URI::file"             => 0,
                                             "XML::LibXML"           => 1.94,
                                             "XML::LibXML::Devel"    => 0,
                                           },
                                         },
                            test      => {
                                           recommends => { "LWP::UserAgent" => 0 },
                                           requires   => { "FindBin" => 0, "Test::More" => 0.61, "Test::Requires" => 0 },
                                         },
                          },
  "provides"           => {
                            "HTML::HTML5::Parser"                                    => { file => "lib/HTML/HTML5/Parser.pm", version => 0.992 },
                            "HTML::HTML5::Parser::Charset::DecodeHandle"             => {
                                                                                          file => "lib/HTML/HTML5/Parser/Charset/DecodeHandle.pm",
                                                                                          version => 0.992,
                                                                                        },
                            "HTML::HTML5::Parser::Charset::DecodeHandle::ByteBuffer" => { file => "lib/HTML/HTML5/Parser/Charset/DecodeHandle.pm" },
                            "HTML::HTML5::Parser::Charset::DecodeHandle::CharString" => { file => "lib/HTML/HTML5/Parser/Charset/DecodeHandle.pm" },
                            "HTML::HTML5::Parser::Charset::DecodeHandle::Encode"     => { file => "lib/HTML/HTML5/Parser/Charset/DecodeHandle.pm" },
                            "HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP"  => { file => "lib/HTML/HTML5/Parser/Charset/DecodeHandle.pm" },
                            "HTML::HTML5::Parser::Charset::Info"                     => { file => "lib/HTML/HTML5/Parser/Charset/Info.pm", version => 0.992 },
                            "HTML::HTML5::Parser::Charset::UnicodeChecker"           => {
                                                                                          file => "lib/HTML/HTML5/Parser/Charset/UnicodeChecker.pm",
                                                                                          version => 0.992,
                                                                                        },
                            "HTML::HTML5::Parser::Charset::UniversalCharDet"         => {
                                                                                          file => "lib/HTML/HTML5/Parser/Charset/UniversalCharDet.pm",
                                                                                          version => 0.992,
                                                                                        },
                            "HTML::HTML5::Parser::Charset::USASCII"                  => { file => "lib/HTML/HTML5/Parser/Charset/WebLatin1.pm" },
                            "HTML::HTML5::Parser::Charset::WebLatin1"                => {
                                                                                          file => "lib/HTML/HTML5/Parser/Charset/WebLatin1.pm",
                                                                                          version => 0.992,
                                                                                        },
                            "HTML::HTML5::Parser::Charset::WebLatin5"                => { file => "lib/HTML/HTML5/Parser/Charset/WebLatin1.pm" },
                            "HTML::HTML5::Parser::Charset::WebThai"                  => {
                                                                                          file => "lib/HTML/HTML5/Parser/Charset/WebThai.pm",
                                                                                          version => 0.992,
                                                                                        },
                            "HTML::HTML5::Parser::Charset::WebThai::WebTIS620"       => { file => "lib/HTML/HTML5/Parser/Charset/WebThai.pm" },
                            "HTML::HTML5::Parser::Error"                             => { file => "lib/HTML/HTML5/Parser/Error.pm", version => 0.992 },
                            "HTML::HTML5::Parser::TagSoupParser"                     => { file => "lib/HTML/HTML5/Parser/TagSoupParser.pm", version => 0.992 },
                            "HTML::HTML5::Parser::TagSoupParser::RestartParser"      => { file => "lib/HTML/HTML5/Parser/TagSoupParser.pm" },
                            "HTML::HTML5::Parser::Tokenizer"                         => { file => "lib/HTML/HTML5/Parser/Tokenizer.pm", version => 0.992 },
                            "HTML::HTML5::Parser::UA"                                => { file => "lib/HTML/HTML5/Parser/UA.pm", version => 0.992 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => { web => "https://github.com/tobyink/p5-html-html5-parser/issues" },
                            homepage     => "https://metacpan.org/release/HTML-HTML5-Parser",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => {
                                              type => "git",
                                              url  => "git://github.com/tobyink/p5-html-html5-parser.git",
                                              web  => "https://github.com/tobyink/p5-html-html5-parser",
                                            },
                            x_identifier => "http://purl.org/NET/cpan-uri/dist/HTML-HTML5-Parser/project",
                          },
  "version"            => 0.992,
  "x_contributors"     => [
                            "Wakaba",
                            "SHELLAC",
                            "AUDREYT <audreyt\@cpan.org>",
                            "TOBYINK",
                            "Dorian Taylor",
                            "Gregory Williams",
                            "Kjetil Kjernsmo",
                            "Alex Vandiver",
                          ],
  "x_provides_scripts" => {
                            html2xhtml => { file => "bin/html2xhtml" },
                            html5debug => { file => "bin/html5debug" },
                          },
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

