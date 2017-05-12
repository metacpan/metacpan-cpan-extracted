use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "implementation of the HTML5 DOM on top of XML::LibXML",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.016, CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "HTML-HTML5-DOM",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        runtime => {
                          requires => {
                            "Capture::Attribute"         => 0,
                            "DateTime"                   => 0,
                            "HTML::HTML5::Parser"        => 0,
                            "HTML::HTML5::Writer"        => 0,
                            "HTTP::Request"              => "6.00",
                            "IO::Detect"                 => 0,
                            "match::simple"              => 0,
                            "URI"                        => 0,
                            "URI::Escape"                => 0,
                            "XML::LibXML"                => "2.00",
                            "XML::LibXML::Augment"       => 0,
                            "XML::LibXML::QuerySelector" => 0,
                          },
                        },
                        test => { requires => { "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "HTML::HTML5::DOM"                             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLAnchorElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLAreaElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLAudioElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLBaseElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLBodyElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLBRElement"              => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLButtonElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLCanvasElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLCollection"             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLCommandElement"         => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLDataListElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLDetailsElement"         => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLDivElement"             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLDListElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLDocument"               => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLElement"                => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLEmbedElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLFieldSetElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLFormControlsCollection" => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLFormElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLHeadElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLHeadingElement"         => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLHRElement"              => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLHtmlElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLIFrameElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLImageElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLInputElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLKeygenElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLLabelElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLLegendElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLLIElement"              => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLLinkElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLMapElement"             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLMediaElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLMenuElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLMetaElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLMeterElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLModElement"             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLObjectElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLOListElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLOptGroupElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLOptionElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLOutputElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLParagraphElement"       => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLParamElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLPreElement"             => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLProgressElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLQuoteElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLScriptElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLSelectElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLSourceElement"          => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLSpanElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLStyleElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableCaptionElement"    => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableCellElement"       => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableColElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableDataCellElement"   => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableHeaderCellElement" => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableRowElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTableSectionElement"    => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTextAreaElement"        => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTimeElement"            => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTitleElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLTrackElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLUListElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLUnknownElement"         => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::HTMLVideoElement"           => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOM::RadioNodeList"              => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOMutil::AutoDoc"                => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOMutil::FancyISA"               => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                        "HTML::HTML5::DOMutil::Feature"                => { file => "lib/HTML/HTML5/DOM.pm", version => 0.002 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-DOM",
                                        },
                        homepage     => "https://metacpan.org/release/HTML-HTML5-DOM",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-html-html5-dom.git",
                                          web  => "https://github.com/tobyink/p5-html-html5-dom",
                                        },
                        X_identifier => "http://purl.org/NET/cpan-uri/dist/HTML-HTML5-DOM/project",
                      },
  "version"        => 0.002,
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

