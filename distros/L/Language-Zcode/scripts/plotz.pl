#!perl -w

=head1 NAME

plotz - Poly-Lingual Opcode Translator for the Z-machine

=head1 SYNOPSIS

plotz.pl storyfile[.z?|dat] [output_suffix]

If you don't give a suffix to the storyfile, plotz will look for a file
with that root, and suffix .z? or .dat.

output_suffix can be pl, pir, or xml. It tells plotz which language to
translate to. Perl is the default.

=head1 DESCRIPTION

plotz translates a Z-code story file into another language. That file can
then be (compiled and) run to replicate the functionality of running a
standard Z-code interpreter like Zip or Frotz on the story file.

Since the disassembling of the Z-file will be the same no matter what your
output language is, in theory you can add a new output language with only half
the work. (OK, 90% of the work.) The first attempts to make use of this will
be a Perl and a PIR (Parrot Intermediate Language) translation.

aka Perpetrating Linguistics On The Z-machine.

=cut

use strict;
use Language::Zcode::Parser; # parse Z-file
use Language::Zcode::Translator; # language-specific output routines

################################
# Get args
my %e2l = (
    "pl" => "Perl",
    "imc" => "PIR",
    "pir" => "PIR",
    "xml" => "XML",
);
my $known = join "|", keys %e2l;

my $Usage = <<ENDUSAGE;
    plotz.pl storyfile[.z?|dat] [$known]

    The last arg is the extension for the output file, pl by default.
    The extension tells plotz which language to translate to.
ENDUSAGE
die "$Usage\n" if @ARGV == 0 || @ARGV > 2;

my ($infile, $extension) = @ARGV;
die "$Usage\n" if defined $extension && !exists $e2l{$extension};
$extension ||= "pl"; # .pl is default output

################################
# Read in the Z-file, store it in memory, parse the header
my $Parser = new Language::Zcode::Parser "Perl";
# If they didn't put ".z5" at the end, find it anyway
$infile = $Parser->find_zfile($infile) || exit;
$Parser->read_memory($infile);
$Parser->parse_header();

# Create a translator object that will write code in the correct 
# language (e.g. Plotz::Translator::Perl).
my $language = $e2l{$extension} 
    or die "Unknown extension $extension. I know ",join(" ",keys %e2l);
my $T = new Language::Zcode::Translator $language;

################################
# Start the output program
(my $outfile = $infile) =~ s/\.(z\d+|dat)$/.$extension/i;
open(POUT, ">$outfile");
print POUT $T->program_start();

# Get routines, each of which is made up of commands.
# Parse each Z-routine, then print its translation
print "Finding routines...";
my @subs = $Parser->find_subs($infile); # addr of each sub, commands not parsed
# TODO print only if -v? Or -b to be brief?
print scalar @subs, " routines to translate.\n";
my $i = 0;
print "Translating...";
for my $rtn (@subs) {
    $rtn->parse();
    print POUT $T->routine_start($rtn->address, $rtn->locals); # e.g."sub foo {"
    print POUT $T->translate_command($_) for $rtn->commands;
    print POUT $T->routine_end(); # e.g., "}"
    print "$i.." unless ++$i % 100;
}

# Add in any language-specific support routines (possibly from other files)
print POUT $T->library();

# Print the code that stores the zfile (e.g. as uunecoded text) and
# can unpack it back to bytes.
print POUT $T->write_memory();

print POUT $T->program_end();

close(POUT);
print "Done!\nOutput file is $outfile\n";
exit;

=head1 AUTHOR

Amir Karger (akarger@cpan.org)

=head1 LICENSE

Copyright (c) 2003-4 Amir Karger.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 NOTES

Plotz is a Yiddish word describing what your mother does when she finds out
you're wasting your life playing computer games instead of becoming a doctor.
And you couldn't call once in a while?

Plotz is the name of a machine company in Cleveland. 

Plotz was used on the rec.arts.int-fiction newsgroup in 1999 to describe that
indescribable something that interactive fiction games have that draws you in
and keeps you playing even if there isn't an actual plot.

=cut
