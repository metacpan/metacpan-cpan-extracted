# Create the poll

use HTML::Ballot::Trusting;

$HTML::Ballot::Trusting::CHAT = 3;

my $p = new HTML::Ballot::Trusting {
	ARTICLE_ROOT => 'E:/www/leegoddard_com',
	URL_ROOT 	=> 'http://localhost/leegoddard_com',
	RPATH 	 => 'E:/www/leegoddard_com/vote/results.html',
	TPATH	 => 'E:/www/leegoddard_com/vote/template.html',
	QPATH	 =>	'E:/www/leegoddard_com/vote/vote.html',
	CPATH 	 => 'E:/www/leegoddard_com/CGI_BIN/vote.pl',
	ASKNAMES => 1,
	QUESTIONS => [
		'Why?',
		'Why not?',
		'Only for £300.'
	]
};

$p->create();

