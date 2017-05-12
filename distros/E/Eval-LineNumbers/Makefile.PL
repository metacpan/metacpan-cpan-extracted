use ExtUtils::MakeMaker;

WriteMakefile(
	'VERSION_FROM' => 'lib/Eval/LineNumbers.pm',
	'NAME' => 'Eval::LineNumbers',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM' => {
		'Exporter' => '5.57', # in core since 5.8.3, and also on CPAN
	},
	($] >= 5.005
		?	
			(
				ABSTRACT	=> "Add line numbers to eval'ed heredoc blocks",
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Eval-LineNumbers',
					},
				},
			)
		: ()
	),
);

package MY;

sub postamble {
    <<"END_OF_POSTAMBLE";

pm_to_blib: README

README: lib/Eval/LineNumbers.pm
\tpod2text lib/Eval/LineNumbers.pm >README

END_OF_POSTAMBLE
}

