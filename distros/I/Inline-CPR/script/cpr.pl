use strict;

use Inline;
use Cwd;
use constant DIRECTORY => cwd('.') . '/.cpr';

my (@cpr, @argv, $script);

BEGIN {
    @argv = @ARGV;
    $script = pop @ARGV;
    open CPR, "< $script"
      or die "Can't open CPR script: $script for input\n$!\n";
    @cpr = <CPR>;
    close CPR;
    shift @cpr if $cpr[0] =~ /^\#\!/;

    if (not -d DIRECTORY) {
	mkdir(DIRECTORY, 0777) or die;
    }

    Inline->import(CPR => [@cpr], 
		   DIRECTORY => DIRECTORY);
    exit &main::cpr_main();
}
