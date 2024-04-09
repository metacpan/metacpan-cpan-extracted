use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/JSON-ToHTML>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-ToHTML>;

our %META = (
	name        => 'JSON-ToHTML',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>', # can be an array
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2024 },
	license     => 'perl_5',
	resources   => {
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
				Scalar::Util 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
