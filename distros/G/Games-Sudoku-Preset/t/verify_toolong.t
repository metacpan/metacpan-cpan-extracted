use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

can_ok('Games::Sudoku::Preset', qw/enter edit validate/);

use Games::Sudoku::Preset;

# pass game as string with embedded newlines

my $errfile = 'stderr.txt';
my $game = <<END;
# naked_single
# 4 NS  23 preset
#
^89 ^^^ 7^6
^^^ ^1^ ^^^
^^^ 5^^ ^2^+

2^6 ^^7 ^^^
^4^ ^3^ ^1^
^^^ 4^^ 9^5

^9^ ^^4 ^^^
^^^ ^7^ ^^^
7^3 ^^^ 86^
END
no warnings 'once';
open SAVEERR, ">&STDERR";
use warnings 'once';
# Name "main::SAVEERR" used only once: possible typo at ...
open (STDERR, '>', $errfile) or  die "cannot assign STDERR to $errfile: $!";
select STDERR; $| = 1;   # Pufferung deaktivieren (ging hier auch ohne)

my $puzzle = Games::Sudoku::Preset->validate($game);
my $ok = is($puzzle, '', 'verify too long puzzle');
if ($ok) {
	close STDERR;
    open STDERR, ">&SAVEERR";
	open (my $ERR, '<', $errfile)
        or  die "cannot open $errfile: $!";
    my @errtxt = <$ERR>;
	close $ERR
        or  die "cannot close $errfile: $!";
    unlink $errfile
       or  die "cannot delete $errfile: $!";
	diag("\nThe error message is:\n@errtxt");
} else {
    diag('unexpected return value $puzzle from Preset->validate');
}

# Note: Umlenkung von STDOUT und STDERR: Kamelbuch S. 775
