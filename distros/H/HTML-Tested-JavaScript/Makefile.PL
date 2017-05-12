use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'HTML::Tested::JavaScript',
	VERSION_FROM => 'lib/HTML/Tested/JavaScript.pm', # finds \$VERSION
	AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
	ABSTRACT     => 'HTML::Tested JavaScript helpers',
	PREREQ_PM    => { 'Test::Simple' => 0.44,
	    		'HTML::Tested' => 0.56,
	    		'Mozilla::Mechanize::GUITester' => 0.18,
			'JSON::XS' => '',
			'File::Slurp' => '',
			'HTTP::Daemon' => '',
			'Text::Diff' => "",
			'HTTP::Request::Params' => '',
			'Mozilla::SourceViewer' => '0.05'
			, 'Gtk2::WebKit::Mechanize' => ''
	},
);

package MY;

sub install {
	my $res = shift->SUPER::install(@_);
	$res =~ s/(\$\(DEST[^\\]*MAN1DIR\))([^\$]+)/$1 $2javascript \$(SITEPREFIX)\/share\/libhtml-tested-javascript-perl \\\n/g;
	return $res;
}

