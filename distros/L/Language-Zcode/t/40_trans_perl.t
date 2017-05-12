#!perl
# Test that we can translate a Z-code file into a Perl file.
# (Hey vim! use Perl syntax highlighting... vim: filetype=Perl 

use strict;
use warnings;
use Test;
use File::Basename;

BEGIN { plan tests => 2, todo => [] } #3,4] }

use constant ZROOT => "big_test";

my $Zname = ZROOT . ".z5";
# Use fileparse because dirname can have different behavior sometimes.
my $Zfile = (fileparse $0)[1] . $Zname;

use Language::Zcode::Parser; # parse Z-file
use Language::Zcode::Translator; # language-specific output routines

# Translate the Z-file. This code copied from plotz.pl, minus comments.
my $Parser = new Language::Zcode::Parser "Perl";
#my $Zfile = $Parser->find_zfile($Zfile) || exit;
$Parser->read_memory($Zfile);
$Parser->parse_header();
my @subs = $Parser->find_subs($Zfile);

my $T = new Language::Zcode::Translator "Perl";
ok(ref $T && $T->isa("Language::Zcode::Translator::Perl"));
#TODO test Translator ISA etc.
#We can also test memory for fun.
(my $outfile = $Zfile) =~ s/\.(z\d+)$/.pl/i;
open(POUT, ">$outfile");
print POUT $T->program_start();
for my $rtn (@subs) {
    $rtn->parse();
    print POUT $T->routine_start($rtn->address, $rtn->locals); 
    print POUT $T->translate_command($_) for $rtn->commands;
    print POUT $T->routine_end();
}
print POUT $T->library();
print POUT $T->write_memory();
print POUT $T->program_end();
close(POUT);
ok(1); # got to end
