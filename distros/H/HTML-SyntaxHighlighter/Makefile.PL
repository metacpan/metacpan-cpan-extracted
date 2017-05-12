use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::SyntaxHighlighter',
    'VERSION_FROM' => 'SyntaxHighlighter.pm', # finds $VERSION
);
