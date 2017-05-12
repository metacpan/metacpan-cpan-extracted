use ExtUtils::MakeMaker;

use strict;
use warnings;

my $PACKAGE = "Mail::Message::Attachment::Stripper";
my $LOCN    = "lib/Mail/Message/Attachment/Stripper.pm";

WriteMakefile(
	AUTHOR        => 'Kasei <cpan@kasei.com>',
	NAME          => $PACKAGE,
	ABSTRACT_FROM => $LOCN,
	VERSION_FROM  => $LOCN,
	PREREQ_PM     => {
		'Test::More' => 0.45,
		'Mail::Message' => 2.050,
	},
	dist => {
		COMPRESS     => 'gzip -9',
		SUFFIX       => '.gz',
		DIST_DEFAULT => 'all tardist',
	},

);
