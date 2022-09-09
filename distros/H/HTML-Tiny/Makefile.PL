use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/HTML-Tiny>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Tiny>;

our %META = (
	name           => 'HTML-Tiny',
	author         => [ 'Andy Armstrong <andy@hexten.net>', 'Aristotle Pagaltzis <pagaltzis@gmx.de>' ],
	x_copyright    => { holder => 'Andy Armstrong', year => 2008 },
	license        => 'perl_5',
	resources      => {
		license    => [ q<https://dev.perl.org/licenses/> ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.006
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
			)},
		},
	},
);

our $manifest_cmd = q[git ls-files ':!author/' ':!README.pod'];

require './inc/WriteMakefile.pl';
