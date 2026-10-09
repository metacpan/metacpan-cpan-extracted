package Game::Merrills::Test::Screen;

use strict;
use warnings;

use Exporter 'import';
use Game::Merrills;
use Game::Merrills::Terminal;

our $VERSION = '0.01';

our @EXPORT_OK = qw/terminal typed/;

# A terminal that reads a script and writes into a string, for the tests.
#
#   my ($terminal, $screen) = terminal("d2\nf4\n", human => 'both');
#   $terminal->start;
#   like $$screen, qr/.../;
#
# Off a terminal, plain ASCII and no colour unless the test says otherwise,
# so that what is matched is what was meant and nothing else.
sub terminal {
	my ($script, %option) = @_;
	my $screen = '';
	open my $in, '<', \$script or die "cannot read the script: $!";
	open my $out, '>', \$screen or die "cannot open the screen: $!";
	my $terminal = Game::Merrills::Terminal->new(
		in => $in,
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		human => 'both',
		%option,
	);
	return ($terminal, \$screen);
}

# typed($script, %option): run a whole session and hand back the terminal and
# everything it printed. A session that has not ended in a minute is one that
# never will, and dies saying so: a test that hangs tells nobody anything.
sub typed {
	my ($script, %option) = @_;
	my ($terminal, $screen) = terminal($script, %option);
	local $SIG{ALRM} = sub { die "the session did not end\n" };
	alarm 60;
	$terminal->start;
	alarm 0;
	return ($terminal, $$screen);
}

1;
